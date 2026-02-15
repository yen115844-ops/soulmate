import { BadRequestException, ConflictException, ForbiddenException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { SlotStatus, UserRole, UserStatus } from '@prisma/client';
import { PrismaService } from '../../database/prisma/prisma.service';
import {
    AdminPartnerQueryDto,
    CreateAvailabilitySlotDto,
    CreatePartnerProfileDto,
    SearchPartnersDto,
    UpdateAvailabilitySlotDto,
    UpdatePartnerProfileDto,
    UpdatePartnerStatusDto,
} from './dto';

@Injectable()
export class PartnersService {
  private readonly logger = new Logger(PartnersService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Update lastActiveAt (presence) for current user's partner profile.
   * Used when app opens / comes to foreground so "online" shows on Home/Favorites.
   */
  async updatePresence(userId: string): Promise<{ updated: boolean }> {
    const result = await this.prisma.partnerProfile.updateMany({
      where: { userId },
      data: { lastActiveAt: new Date() },
    });
    return { updated: result.count > 0 };
  }

  /**
   * Register as a partner
   */
  async registerAsPartner(userId: string, dto: CreatePartnerProfileDto) {
    // Check if user exists
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { partnerProfile: true, profile: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.partnerProfile) {
      throw new ConflictException('User already has a partner profile');
    }

    // Create partner profile and update user role in transaction
    const result = await this.prisma.$transaction(async (tx) => {
      // Update user role to PARTNER
      await tx.user.update({
        where: { id: userId },
        data: { role: UserRole.PARTNER },
      });

      // Update user profile bio if provided
      if (dto.bio && user.profile) {
        await tx.profile.update({
          where: { id: user.profile.id },
          data: { bio: dto.bio },
        });
      }

      // Create or update wallet with bank info
      if (dto.bankName || dto.bankAccountNo || dto.bankAccountName) {
        await tx.wallet.upsert({
          where: { userId },
          create: {
            userId,
            bankName: dto.bankName,
            bankAccountNo: dto.bankAccountNo,
            bankAccountName: dto.bankAccountName,
          },
          update: {
            bankName: dto.bankName,
            bankAccountNo: dto.bankAccountNo,
            bankAccountName: dto.bankAccountName,
          },
        });
      }

      // Create partner profile
      const partnerProfile = await tx.partnerProfile.create({
        data: {
          userId,
          hourlyRate: dto.hourlyRate,
          minimumHours: dto.minimumHours || 3,
          currency: dto.currency || 'VND',
          serviceTypes: dto.serviceTypes,
          introduction: dto.introduction,
          experienceYears: dto.experienceYears,
        },
      });

      // Add photos to user's photos if provided
      if (dto.photoUrls && dto.photoUrls.length > 0) {
        const existingPhotos = user.profile?.photos as string[] || [];
        const newPhotos = [...existingPhotos];
        
        for (const url of dto.photoUrls) {
          if (!newPhotos.includes(url)) {
            newPhotos.push(url);
          }
        }

        if (user.profile) {
          await tx.profile.update({
            where: { id: user.profile.id },
            data: { photos: newPhotos },
          });
        } else {
          // Create profile if it doesn't exist
          await tx.profile.create({
            data: {
              userId,
              fullName: user.email?.split('@')[0] || 'Partner',
              photos: newPhotos,
            },
          });
          this.logger.log(`Created new profile for user ${userId} during partner registration`);
        }
      }

      return partnerProfile;
    });

    this.logger.log(`User ${userId} registered as partner`);
    return result;
  }

  /**
   * Get partner profile by user ID
   */
  async getPartnerProfile(userId: string) {
    const profile = await this.prisma.partnerProfile.findUnique({
      where: { userId },
      include: {
        user: {
          include: {
            profile: true,
          },
          omit: {
            passwordHash: true,
          },
        },
        availabilitySlots: {
          where: {
            date: { gte: new Date() },
            status: SlotStatus.AVAILABLE,
          },
          take: 10,
          orderBy: { date: 'asc' },
        },
      },
    });

    if (!profile) {
      throw new NotFoundException('Partner profile not found');
    }

    return profile;
  }

  /**
   * Update partner profile
   */
  async updatePartnerProfile(userId: string, dto: UpdatePartnerProfileDto) {
    const existing = await this.prisma.partnerProfile.findUnique({
      where: { userId },
      include: {
        user: {
          include: { profile: true },
        },
      },
    });

    if (!existing) {
      throw new NotFoundException('Partner profile not found');
    }

    // Extract bank info, photo updates from dto (these go to different tables)
    const { bankName, bankAccountNo, bankAccountName, photoUrls, removePhotoUrls, ...partnerData } = dto;

    return this.prisma.$transaction(async (tx) => {
      // Update partner profile
      const profile = await tx.partnerProfile.update({
        where: { userId },
        data: {
          ...partnerData,
          lastActiveAt: new Date(),
        },
      });

      // Update bank info in wallet if provided
      if (bankName !== undefined || bankAccountNo !== undefined || bankAccountName !== undefined) {
        await tx.wallet.upsert({
          where: { userId },
          create: {
            userId,
            bankName,
            bankAccountNo,
            bankAccountName,
          },
          update: {
            bankName,
            bankAccountNo,
            bankAccountName,
          },
        });
      }

      // Update photos in user's profile
      if (photoUrls || removePhotoUrls) {
        const userProfile = existing.user?.profile;
        let currentPhotos = (userProfile?.photos as string[]) || [];

        // Remove photos if specified
        if (removePhotoUrls && removePhotoUrls.length > 0) {
          currentPhotos = currentPhotos.filter((url) => !removePhotoUrls.includes(url));
        }

        // Add new photos if specified
        if (photoUrls && photoUrls.length > 0) {
          for (const url of photoUrls) {
            if (!currentPhotos.includes(url)) {
              currentPhotos.push(url);
            }
          }
        }

        if (userProfile) {
          await tx.profile.update({
            where: { id: userProfile.id },
            data: { photos: currentPhotos },
          });
        } else {
          // Create profile if it doesn't exist
          await tx.profile.create({
            data: {
              userId,
              fullName: existing.user?.email?.split('@')[0] || 'Partner',
              photos: currentPhotos,
            },
          });
          this.logger.log(`Created new profile for user ${userId} with photos`);
        }
      }

      this.logger.log(`Partner profile updated for user: ${userId}`);
      return profile;
    });
  }

  /**
   * Search partners with filters
   * @param dto Search parameters
   * @param currentUserId Optional - exclude this user from results (don't show self in search)
   */
  async searchPartners(dto: SearchPartnersDto, currentUserId?: string) {
    const { page = 1, limit = 10 } = dto;
    const skip = (page - 1) * limit;

    // Get blocked user IDs if current user is logged in
    let blockedUserIds: string[] = [];
    if (currentUserId) {
      const [blockedByMe, blockedMe] = await Promise.all([
        this.prisma.userBlacklist.findMany({
          where: { blockerId: currentUserId },
          select: { blockedId: true },
        }),
        this.prisma.userBlacklist.findMany({
          where: { blockedId: currentUserId },
          select: { blockerId: true },
        }),
      ]);
      blockedUserIds = [
        ...blockedByMe.map(b => b.blockedId),
        ...blockedMe.map(b => b.blockerId),
      ];
    }

    // Build where conditions
    const where: any = {
      user: {
        is: {
          role: UserRole.PARTNER,
          status: 'ACTIVE',
        },
      },
      isAvailable: true,
    };

    // Exclude current user and blocked users from results
    if (currentUserId) {
      const excludeUserIds = [currentUserId, ...blockedUserIds];
      where.userId = { notIn: excludeUserIds };
    }

    // Service type filter
    if (dto.serviceType) {
      where.serviceTypes = {
        array_contains: [dto.serviceType],
      };
    }

    // Price range filter
    if (dto.minRate !== undefined || dto.maxRate !== undefined) {
      where.hourlyRate = {};
      if (dto.minRate !== undefined) {
        where.hourlyRate.gte = dto.minRate;
      }
      if (dto.maxRate !== undefined) {
        where.hourlyRate.lte = dto.maxRate;
      }
    }

    // Verified only filter
    if (dto.verifiedOnly) {
      where.isVerified = true;
    }

    // Gender filter
    if (dto.gender) {
      where.user.is.profile = {
        is: {
          gender: dto.gender,
        },
      };
    }

    // City filter (by province ID)
    const filterProvinceId = dto.provinceId || dto.cityId;
    if (filterProvinceId) {
      if (!where.user.is.profile) {
        where.user.is.profile = { is: {} };
      }
      where.user.is.profile.is.provinceId = filterProvinceId;
    }

    // District filter (by district ID)
    if (dto.districtId) {
      if (!where.user.is.profile) {
        where.user.is.profile = { is: {} };
      }
      where.user.is.profile.is.districtId = dto.districtId;
    }

    // Age filter (based on dateOfBirth)
    if (dto.minAge !== undefined || dto.maxAge !== undefined) {
      if (!where.user.is.profile) {
        where.user.is.profile = { is: {} };
      }
      const now = new Date();
      const dobFilter: any = { not: null };
      if (dto.maxAge !== undefined) {
        // maxAge => born after this date (younger)
        const minBirthDate = new Date(now.getFullYear() - dto.maxAge - 1, now.getMonth(), now.getDate());
        dobFilter.gte = minBirthDate;
      }
      if (dto.minAge !== undefined) {
        // minAge => born before this date (older)
        const maxBirthDate = new Date(now.getFullYear() - dto.minAge, now.getMonth(), now.getDate());
        dobFilter.lte = maxBirthDate;
      }
      where.user.is.profile.is.dateOfBirth = dobFilter;
    }

    // Available now filter (active within last 15 minutes)
    if (dto.availableNow) {
      const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000);
      where.lastActiveAt = { gte: fifteenMinutesAgo };
    }

    // Text search filter (search by name or introduction)
    if (dto.q) {
      where.OR = [
        { introduction: { contains: dto.q, mode: 'insensitive' } },
        { user: { is: { profile: { is: { fullName: { contains: dto.q, mode: 'insensitive' } } } } } },
      ];
    }

    // Build order by
    let orderBy: any = { averageRating: 'desc' };
    if (dto.sortBy === 'price_low') {
      orderBy = { hourlyRate: 'asc' };
    } else if (dto.sortBy === 'price_high') {
      orderBy = { hourlyRate: 'desc' };
    } else if (dto.sortBy === 'newest') {
      orderBy = { createdAt: 'desc' };
    }

    const [partners, total] = await Promise.all([
      this.prisma.partnerProfile.findMany({
        where,
        skip,
        take: limit,
        orderBy,
        include: {
          user: {
            include: {
              profile: true,
            },
            omit: {
              passwordHash: true,
            },
          },
        },
      }),
      this.prisma.partnerProfile.count({ where }),
    ]);

    const totalPages = Math.ceil(total / limit);

    return {
      data: partners,
      meta: {
        total,
        page,
        limit,
        totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      },
    };
  }

  /**
   * Get partner by ID (public profile)
   * @param partnerId Partner user ID
   * @param currentUserId Optional current user ID to check block status
   */
  async getPartnerById(partnerId: string, currentUserId?: string) {
    // Check if either user has blocked the other
    if (currentUserId && currentUserId !== partnerId) {
      const blockExists = await this.prisma.userBlacklist.findFirst({
        where: {
          OR: [
            { blockerId: currentUserId, blockedId: partnerId },
            { blockerId: partnerId, blockedId: currentUserId },
          ],
        },
      });
      
      if (blockExists) {
        throw new ForbiddenException('Không thể xem hồ sơ người dùng này');
      }
    }

    const partner = await this.prisma.partnerProfile.findFirst({
      where: {
        userId: partnerId,
        user: { role: UserRole.PARTNER, status: 'ACTIVE' },
      },
      include: {
        user: {
          include: {
            profile: true,
            reviewsReceived: {
              take: 5,
              orderBy: { createdAt: 'desc' },
              include: {
                reviewer: {
                  include: {
                    profile: {
                      select: {
                        fullName: true,
                        avatarUrl: true,
                      },
                    },
                  },
                },
              },
            },
          },
          omit: {
            passwordHash: true,
          },
        },
        availabilitySlots: {
          where: {
            date: { gte: new Date() },
            status: SlotStatus.AVAILABLE,
          },
          take: 20,
          orderBy: [{ date: 'asc' }, { startTime: 'asc' }],
        },
      },
    });

    if (!partner) {
      throw new NotFoundException('Partner not found');
    }

    return this.transformPartnerDetailResponse(partner);
  }

  /**
   * Transform partner detail for API response:
   * - Convert Decimal to number (hourlyRate, averageRating, responseRate)
   * - Expand serviceTypes, interests, talents with master data (name, icon)
   * - Normalize photos to string[]
   * - Format availabilitySlots
   */
  private async transformPartnerDetailResponse(partner: any) {
    const serviceTypeCodes = Array.isArray(partner.serviceTypes)
      ? (partner.serviceTypes as string[])
      : [];
    const interestCodes = Array.isArray(partner.user?.profile?.interests)
      ? (partner.user.profile.interests as string[])
      : [];
    const talentCodes = Array.isArray(partner.user?.profile?.talents)
      ? (partner.user.profile.talents as string[])
      : [];

    const [serviceTypesData, interestsData, talentsData] = await Promise.all([
      serviceTypeCodes.length > 0
        ? this.prisma.serviceType.findMany({
            where: { code: { in: serviceTypeCodes }, isActive: true },
          })
        : ([] as { code: string; name: string; nameVi: string; icon: string | null }[]),
      interestCodes.length > 0
        ? this.prisma.interest.findMany({
            where: { code: { in: interestCodes }, isActive: true },
          })
        : ([] as { code: string; name: string; icon: string | null }[]),
      talentCodes.length > 0
        ? this.prisma.talent.findMany({
            where: { code: { in: talentCodes }, isActive: true },
          })
        : ([] as { code: string; name: string; icon: string | null }[]),
    ]);

    const serviceTypesMap = new Map<string, { code: string; name: string; nameVi: string; icon: string | null }>();
    for (const s of serviceTypesData) {
      serviceTypesMap.set(s.code, s);
    }
    const interestsMap = new Map<string, { code: string; name: string; icon: string | null }>();
    for (const i of interestsData) {
      interestsMap.set(i.code, i);
    }
    const talentsMap = new Map<string, { code: string; name: string; icon: string | null }>();
    for (const t of talentsData) {
      talentsMap.set(t.code, t);
    }

    const serviceTypesDetail = serviceTypeCodes
      .map((code) => serviceTypesMap.get(code))
      .filter((s): s is NonNullable<typeof s> => !!s)
      .map((s) => ({
        code: s.code,
        name: s.name,
        nameVi: s.nameVi,
        icon: s.icon,
      }));

    const interestsDetail = interestCodes
      .map((code) => interestsMap.get(code))
      .filter((i): i is NonNullable<typeof i> => !!i)
      .map((i) => ({
        code: i.code,
        name: i.name,
        nameVi: i.name,
        icon: i.icon,
      }));

    const talentsDetail = talentCodes
      .map((code) => talentsMap.get(code))
      .filter((t): t is NonNullable<typeof t> => !!t)
      .map((t) => ({
        code: t.code,
        name: t.name,
        nameVi: t.name,
        icon: t.icon,
      }));

    const profile = partner.user?.profile;
    const photosRaw = profile?.photos;
    let photos: string[] = [];
    if (Array.isArray(photosRaw)) {
      photos = photosRaw.map((p: any) =>
        typeof p === 'string' ? p : (p?.url ?? String(p)),
      );
    }

    const formatSlot = (slot: any) => ({
      id: slot.id,
      date: slot.date,
      startTime: slot.startTime,
      endTime: slot.endTime,
      status: slot.status,
    });

    return {
      ...partner,
      hourlyRate: Number(partner.hourlyRate),
      averageRating: Number(partner.averageRating),
      responseRate: Number(partner.responseRate),
      serviceTypesDetail,
      user: partner.user
        ? {
            ...partner.user,
            profile: profile
              ? {
                  ...profile,
                  interestsDetail,
                  talentsDetail,
                  photos,
                }
              : profile,
          }
        : partner.user,
      availabilitySlots: (partner.availabilitySlots || []).map(formatSlot),
    };
  }

  // ==================== Availability Slots ====================

  /**
   * Create availability slot
   */
  async createAvailabilitySlot(userId: string, dto: CreateAvailabilitySlotDto) {
    const partnerProfile = await this.prisma.partnerProfile.findUnique({
      where: { userId },
    });

    if (!partnerProfile) {
      throw new NotFoundException('Partner profile not found');
    }

    // Parse date and times
    const date = new Date(dto.date);
    const startTime = new Date(`1970-01-01T${dto.startTime}:00`);
    const endTime = new Date(`1970-01-01T${dto.endTime}:00`);

    if (startTime >= endTime) {
      throw new BadRequestException('Start time must be before end time');
    }

    // Check for overlapping slots
    const existingSlot = await this.prisma.availabilitySlot.findFirst({
      where: {
        partnerId: partnerProfile.id,
        date,
        OR: [
          {
            startTime: { lte: startTime },
            endTime: { gt: startTime },
          },
          {
            startTime: { lt: endTime },
            endTime: { gte: endTime },
          },
        ],
      },
    });

    if (existingSlot) {
      throw new ConflictException('Time slot overlaps with existing slot');
    }

    const slot = await this.prisma.availabilitySlot.create({
      data: {
        partnerId: partnerProfile.id,
        date,
        startTime,
        endTime,
        note: dto.note,
        status: SlotStatus.AVAILABLE,
      },
    });

    return slot;
  }

  /**
   * Get availability slots for a partner
   */
  async getAvailabilitySlots(userId: string, startDate?: string, endDate?: string) {
    const partnerProfile = await this.prisma.partnerProfile.findUnique({
      where: { userId },
    });

    if (!partnerProfile) {
      throw new NotFoundException('Partner profile not found');
    }

    const where: any = {
      partnerId: partnerProfile.id,
    };

    if (startDate) {
      where.date = { gte: new Date(startDate) };
    }

    if (endDate) {
      where.date = { ...where.date, lte: new Date(endDate) };
    }

    const slots = await this.prisma.availabilitySlot.findMany({
      where,
      orderBy: [{ date: 'asc' }, { startTime: 'asc' }],
    });

    return slots;
  }

  /**
   * Update availability slot
   */
  async updateAvailabilitySlot(userId: string, slotId: string, dto: UpdateAvailabilitySlotDto) {
    const partnerProfile = await this.prisma.partnerProfile.findUnique({
      where: { userId },
    });

    if (!partnerProfile) {
      throw new NotFoundException('Partner profile not found');
    }

    const slot = await this.prisma.availabilitySlot.findFirst({
      where: { id: slotId, partnerId: partnerProfile.id },
    });

    if (!slot) {
      throw new NotFoundException('Availability slot not found');
    }

    if (slot.status === SlotStatus.BOOKED) {
      throw new BadRequestException('Cannot update booked slot');
    }

    return this.prisma.availabilitySlot.update({
      where: { id: slotId },
      data: dto,
    });
  }

  /**
   * Delete availability slot
   */
  async deleteAvailabilitySlot(userId: string, slotId: string) {
    const partnerProfile = await this.prisma.partnerProfile.findUnique({
      where: { userId },
    });

    if (!partnerProfile) {
      throw new NotFoundException('Partner profile not found');
    }

    const slot = await this.prisma.availabilitySlot.findFirst({
      where: { id: slotId, partnerId: partnerProfile.id },
    });

    if (!slot) {
      throw new NotFoundException('Availability slot not found');
    }

    if (slot.status === SlotStatus.BOOKED) {
      throw new BadRequestException('Cannot delete booked slot');
    }

    await this.prisma.availabilitySlot.delete({
      where: { id: slotId },
    });

    return { message: 'Slot deleted successfully' };
  }

  /**
   * Update partner stats (called after booking completion, review, etc.)
   */
  async updatePartnerStats(partnerId: string) {
    const stats = await this.prisma.booking.aggregate({
      where: { partnerId },
      _count: { id: true },
    });

    const completedCount = await this.prisma.booking.count({
      where: { partnerId, status: 'COMPLETED' },
    });

    const cancelledCount = await this.prisma.booking.count({
      where: { partnerId, status: 'CANCELLED', cancelledBy: partnerId },
    });

    const reviewStats = await this.prisma.review.aggregate({
      where: { revieweeId: partnerId },
      _avg: { overallRating: true },
      _count: true,
    });

    await this.prisma.partnerProfile.update({
      where: { userId: partnerId },
      data: {
        totalBookings: stats._count.id,
        completedBookings: completedCount,
        cancelledBookings: cancelledCount,
        averageRating: reviewStats._avg.overallRating || 0,
        totalReviews: reviewStats._count,
      },
    });
  }

  // ==================== Admin Methods ====================

  /**
   * Get partner stats for admin dashboard
   */
  async adminGetPartnerStats() {
    const [total, active, pending, suspended, banned, available] = await Promise.all([
      this.prisma.partnerProfile.count(),
      this.prisma.partnerProfile.count({ where: { user: { status: UserStatus.ACTIVE } } }),
      this.prisma.partnerProfile.count({ where: { user: { status: UserStatus.PENDING } } }),
      this.prisma.partnerProfile.count({ where: { user: { status: UserStatus.SUSPENDED } } }),
      this.prisma.partnerProfile.count({ where: { user: { status: UserStatus.BANNED } } }),
      this.prisma.partnerProfile.count({ where: { isAvailable: true } }),
    ]);

    const avgRating = await this.prisma.partnerProfile.aggregate({
      _avg: { averageRating: true },
    });

    const totalBookings = await this.prisma.booking.count();
    const completedBookings = await this.prisma.booking.count({
      where: { status: 'COMPLETED' },
    });

    return {
      total,
      active,
      pending,
      suspended,
      banned,
      available,
      averageRating: avgRating._avg.averageRating || 0,
      totalBookings,
      completedBookings,
    };
  }

  /**
   * Get all partners for admin with pagination and filters
   */
  async adminGetAllPartners(dto: AdminPartnerQueryDto) {
    const {
      page = 1,
      limit = 10,
      search,
      status,
      serviceType,
      isAvailable,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = dto;

    const where: any = {};

    if (status) {
      where.user = { status };
    }

    if (isAvailable !== undefined) {
      where.isAvailable = isAvailable;
    }

    if (serviceType) {
      where.serviceTypes = { has: serviceType };
    }

    if (search) {
      where.OR = [
        { user: { email: { contains: search, mode: 'insensitive' } } },
        { user: { phone: { contains: search } } },
        { user: { profile: { fullName: { contains: search, mode: 'insensitive' } } } },
      ];
    }

    const [partners, total] = await Promise.all([
      this.prisma.partnerProfile.findMany({
        where,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { [sortBy]: sortOrder },
        include: {
          user: {
            include: {
              profile: true,
            },
          },
        },
      }),
      this.prisma.partnerProfile.count({ where }),
    ]);

    const totalPages = Math.ceil(total / limit);

    return {
      data: partners,
      meta: {
        total,
        page,
        limit,
        totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      },
    };
  }

  /**
   * Update partner status (admin only)
   */
  async adminUpdatePartnerStatus(partnerId: string, dto: UpdatePartnerStatusDto) {
    const partner = await this.prisma.partnerProfile.findUnique({
      where: { id: partnerId },
      include: { user: true },
    });

    if (!partner) {
      throw new NotFoundException('Partner not found');
    }

    const result = await this.prisma.$transaction(async (tx) => {
      // Update user status
      await tx.user.update({
        where: { id: partner.userId },
        data: { status: dto.status },
      });

      // Update partner profile based on status
      // When activated, set isVerified = true
      // When suspended/banned, set isAvailable = false
      const isActive = dto.status === UserStatus.ACTIVE;
      const updatedPartner = await tx.partnerProfile.update({
        where: { id: partnerId },
        data: {
          isVerified: isActive ? true : partner.isVerified,
          isAvailable: isActive ? partner.isAvailable : false,
        },
        include: {
          user: {
            include: { profile: true },
          },
        },
      });

      return updatedPartner;
    });

    return {
      message: `Partner status updated to ${dto.status}`,
      data: result,
    };
  }
}
