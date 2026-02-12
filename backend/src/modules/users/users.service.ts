import { BadRequestException, ForbiddenException, Inject, Injectable, Logger, NotFoundException, forwardRef } from '@nestjs/common';
import { KycStatus, UserStatus } from '@prisma/client';
import { PaginationDto } from '../../common/dto/pagination.dto';
import { PrismaService } from '../../database/prisma/prisma.service';
import { ChatGateway } from '../chat/chat.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { AdminKycQueryDto, AdminUserQueryDto, ReviewKycDto, UpdateLocationDto, UpdateProfileDto, UpdateSettingsDto, UpdateUserStatusDto } from './dto';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    @Inject(forwardRef(() => ChatGateway))
    private readonly chatGateway: ChatGateway,
  ) {}

  /**
   * Get user by ID with profile
   * @param id User ID to find
   * @param currentUserId Optional current user ID to check block status
   */
  async findById(id: string, currentUserId?: string) {
    // Check if either user has blocked the other
    if (currentUserId && currentUserId !== id) {
      const blockExists = await this.prisma.userBlacklist.findFirst({
        where: {
          OR: [
            { blockerId: currentUserId, blockedId: id },
            { blockerId: id, blockedId: currentUserId },
          ],
        },
      });
      
      if (blockExists) {
        throw new ForbiddenException('Không thể xem hồ sơ người dùng này');
      }
    }

    const user = await this.prisma.user.findUnique({
      where: { id },
      include: {
        profile: true,
        partnerProfile: true,
        wallet: {
          select: {
            balance: true,
            pendingBalance: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Remove sensitive data
    const { passwordHash, ...result } = user;
    return result;
  }

  /**
   * Get user profile
   */
  async getProfile(userId: string) {
    const profile = await this.prisma.profile.findUnique({
      where: { userId },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            phone: true,
            role: true,
            status: true,
            kycStatus: true,
            createdAt: true,
          },
        },
      },
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    return profile;
  }

  /**
   * Update user profile
   */
  async updateProfile(userId: string, dto: UpdateProfileDto) {
    // Check if profile exists
    const existingProfile = await this.prisma.profile.findUnique({
      where: { userId },
    });

    if (!existingProfile) {
      throw new NotFoundException('Profile not found');
    }

    const updateData: any = { ...dto };

    // Handle date conversion
    if (dto.dateOfBirth) {
      updateData.dateOfBirth = new Date(dto.dateOfBirth);
    }

    const profile = await this.prisma.profile.update({
      where: { userId },
      data: updateData,
      include: {
        user: {
          select: {
            id: true,
            email: true,
            role: true,
            status: true,
          },
        },
      },
    });

    this.logger.log(`Profile updated for user: ${userId}`);
    return profile;
  }

  /**
   * Update user avatar
   */
  async updateAvatar(userId: string, file: Express.Multer.File) {
    // Check if profile exists
    const existingProfile = await this.prisma.profile.findUnique({
      where: { userId },
    });

    if (!existingProfile) {
      throw new NotFoundException('Profile not found');
    }

    // Generate avatar URL (use the public file serving endpoint)
    const avatarUrl = `/api/upload/files/${file.filename}`;

    // Update profile with new avatar URL
    const profile = await this.prisma.profile.update({
      where: { userId },
      data: { avatarUrl },
    });

    this.logger.log(`Avatar updated for user: ${userId}`);
    return {
      avatarUrl,
      filename: file.filename,
      originalName: file.originalname,
      size: file.size,
      mimetype: file.mimetype,
    };
  }

  /**
   * Update user location
   */
  async updateLocation(userId: string, dto: UpdateLocationDto) {
    const profile = await this.prisma.profile.update({
      where: { userId },
      data: {
        currentLat: dto.currentLat,
        currentLng: dto.currentLng,
        city: dto.city,
        district: dto.district,
      },
    });

    return profile;
  }

  /**
   * Get users list (admin only)
   */
  async findAll(paginationDto: PaginationDto, filters?: any) {
    const { page = 1, limit = 10 } = paginationDto;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (filters?.role) {
      where.role = filters.role;
    }

    if (filters?.status) {
      where.status = filters.status;
    }

    if (filters?.search) {
      where.OR = [
        { email: { contains: filters.search, mode: 'insensitive' } },
        { phone: { contains: filters.search } },
        { profile: { fullName: { contains: filters.search, mode: 'insensitive' } } },
      ];
    }

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          profile: {
            select: {
              fullName: true,
              avatarUrl: true,
              city: true,
            },
          },
        },
        omit: {
          passwordHash: true,
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    const totalPages = Math.ceil(total / limit);

    return {
      data: users,
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
   * Delete user (soft delete)
   */
  async delete(userId: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { status: 'BANNED' },
    });

    return { message: 'User deleted successfully' };
  }

  /**
   * Get user favorites
   */
  async getFavorites(userId: string, paginationDto: PaginationDto) {
    const { page = 1, limit = 10 } = paginationDto;
    const skip = (page - 1) * limit;

    const [favorites, total] = await Promise.all([
      this.prisma.favorite.findMany({
        where: { userId },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          partner: {
            include: {
              profile: true,
              partnerProfile: true,
            },
          },
        },
      }),
      this.prisma.favorite.count({ where: { userId } }),
    ]);

    const totalPages = Math.ceil(total / limit);

    return {
      data: favorites.map((f) => ({
        id: f.id,
        partner: {
          id: f.partner.id,
          email: f.partner.email,
          profile: f.partner.profile,
          partnerProfile: f.partner.partnerProfile,
        },
        createdAt: f.createdAt,
      })),
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
   * Add to favorites
   */
  async addFavorite(userId: string, partnerId: string) {
    // Check if partner exists
    const partner = await this.prisma.user.findFirst({
      where: { id: partnerId, role: 'PARTNER' },
    });

    if (!partner) {
      throw new NotFoundException('Partner not found');
    }

    // Check if already favorited
    const existing = await this.prisma.favorite.findUnique({
      where: {
        userId_partnerId: { userId, partnerId },
      },
    });

    if (existing) {
      return { message: 'Already in favorites' };
    }

    await this.prisma.favorite.create({
      data: { userId, partnerId },
    });

    return { message: 'Added to favorites' };
  }

  /**
   * Remove from favorites
   */
  async removeFavorite(userId: string, partnerId: string) {
    await this.prisma.favorite.deleteMany({
      where: { userId, partnerId },
    });

    return { message: 'Removed from favorites' };
  }

  /**
   * Get profile statistics
   */
  async getProfileStats(userId: string) {
    const [bookingsCount, reviewsCount, wallet, reviewsData, partnerProfile] = await Promise.all([
      // Total bookings as user
      this.prisma.booking.count({
        where: { userId },
      }),
      // Total reviews written
      this.prisma.review.count({
        where: { reviewerId: userId },
      }),
      // Wallet balance
      this.prisma.wallet.findUnique({
        where: { userId },
        select: { balance: true },
      }),
      // Average rating received (reviews about this user)
      this.prisma.review.aggregate({
        where: { revieweeId: userId },
        _avg: { overallRating: true },
      }),
      // Partner profile info
      this.prisma.partnerProfile.findUnique({
        where: { userId },
        select: {
          id: true,
          isVerified: true,
          isAvailable: true,
          verificationBadge: true,
          totalBookings: true,
          completedBookings: true,
          averageRating: true,
          totalReviews: true,
        },
      }),
    ]);

    return {
      totalBookings: bookingsCount,
      totalReviews: reviewsCount,
      averageRating: reviewsData._avg?.overallRating ?? 0,
      walletBalance: wallet?.balance ?? 0,
      // Partner info
      isPartner: !!partnerProfile,
      partnerStatus: partnerProfile ? {
        isVerified: partnerProfile.isVerified,
        isAvailable: partnerProfile.isAvailable,
        verificationBadge: partnerProfile.verificationBadge,
        totalBookings: partnerProfile.totalBookings,
        completedBookings: partnerProfile.completedBookings,
        averageRating: partnerProfile.averageRating,
        totalReviews: partnerProfile.totalReviews,
      } : null,
    };
  }

  // ==================== ADMIN METHODS ====================

  /**
   * Admin: Get user statistics
   */
  async adminGetUserStats() {
    const [total, active, pending, suspended, banned, partners, admins] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.user.count({ where: { status: UserStatus.ACTIVE } }),
      this.prisma.user.count({ where: { status: UserStatus.PENDING } }),
      this.prisma.user.count({ where: { status: UserStatus.SUSPENDED } }),
      this.prisma.user.count({ where: { status: UserStatus.BANNED } }),
      this.prisma.user.count({ where: { role: 'PARTNER' } }),
      this.prisma.user.count({ where: { role: 'ADMIN' } }),
    ]);

    return {
      total,
      active,
      pending,
      suspended,
      banned,
      partners,
      admins,
    };
  }

  /**
   * Admin: Get all users with filters
   */
  async adminGetAllUsers(query: AdminUserQueryDto) {
    const {
      page = 1,
      limit = 10,
      search,
      role,
      status,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = query;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (role) {
      where.role = role;
    }

    if (status) {
      where.status = status;
    }

    if (search) {
      where.OR = [
        { email: { contains: search, mode: 'insensitive' } },
        { phone: { contains: search } },
        { profile: { fullName: { contains: search, mode: 'insensitive' } } },
      ];
    }

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { [sortBy]: sortOrder },
        include: {
          profile: true,
          partnerProfile: {
            select: {
              isVerified: true,
              isAvailable: true,
              totalBookings: true,
              averageRating: true,
            },
          },
        },
        omit: {
          passwordHash: true,
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    const totalPages = Math.ceil(total / limit);

    return {
      data: users,
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
   * Admin: Update user status
   */
  async adminUpdateUserStatus(userId: string, dto: UpdateUserStatusDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: {
        status: dto.status,
      },
      include: {
        profile: true,
        partnerProfile: true,
      },
      omit: {
        passwordHash: true,
      },
    });

    this.logger.log(`Admin updated user ${userId} status to ${dto.status}`);

    return updatedUser;
  }

  // ==================== KYC Admin Methods ====================

  /**
   * Admin: Get KYC stats
   */
  async adminGetKycStats() {
    const [total, pending, verified, rejected, none] = await Promise.all([
      this.prisma.kycVerification.count(),
      this.prisma.kycVerification.count({ where: { status: KycStatus.PENDING } }),
      this.prisma.kycVerification.count({ where: { status: KycStatus.VERIFIED } }),
      this.prisma.kycVerification.count({ where: { status: KycStatus.REJECTED } }),
      this.prisma.user.count({ where: { kycStatus: KycStatus.NONE } }),
    ]);

    return {
      total,
      pending,
      verified,
      rejected,
      none,
    };
  }

  /**
   * Admin: Get all KYC verifications with pagination
   */
  async adminGetAllKyc(dto: AdminKycQueryDto) {
    const {
      page = 1,
      limit = 10,
      search,
      status,
      sortBy = 'submittedAt',
      sortOrder = 'desc',
    } = dto;

    const skip = (page - 1) * limit;

    const where: any = {};

    if (status) {
      where.status = status;
    }

    if (search) {
      where.OR = [
        { user: { email: { contains: search, mode: 'insensitive' } } },
        { user: { profile: { fullName: { contains: search, mode: 'insensitive' } } } },
        { idCardName: { contains: search, mode: 'insensitive' } },
        { idCardNumber: { contains: search } },
      ];
    }

    const [kycList, total] = await Promise.all([
      this.prisma.kycVerification.findMany({
        where,
        skip,
        take: limit,
        orderBy: { [sortBy]: sortOrder },
        include: {
          user: {
            include: {
              profile: {
                select: {
                  fullName: true,
                  avatarUrl: true,
                  gender: true,
                  dateOfBirth: true,
                },
              },
            },
            omit: {
              passwordHash: true,
            },
          },
        },
      }),
      this.prisma.kycVerification.count({ where }),
    ]);

    const totalPages = Math.ceil(total / limit);

    return {
      data: kycList,
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
   * Admin: Get KYC by ID
   */
  async adminGetKycById(kycId: string) {
    const kyc = await this.prisma.kycVerification.findUnique({
      where: { id: kycId },
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
    });

    if (!kyc) {
      throw new NotFoundException('KYC verification not found');
    }

    return kyc;
  }

  /**
   * Admin: Review KYC (approve/reject)
   */
  async adminReviewKyc(kycId: string, adminId: string, dto: ReviewKycDto) {
    const kyc = await this.prisma.kycVerification.findUnique({
      where: { id: kycId },
      include: { user: true },
    });

    if (!kyc) {
      throw new NotFoundException('KYC verification not found');
    }

    if (kyc.status !== KycStatus.PENDING) {
      throw new BadRequestException('KYC verification has already been reviewed');
    }

    if (dto.status === KycStatus.REJECTED && !dto.rejectionReason) {
      throw new BadRequestException('Rejection reason is required');
    }

    const result = await this.prisma.$transaction(async (tx) => {
      // Update KYC verification
      const updatedKyc = await tx.kycVerification.update({
        where: { id: kycId },
        data: {
          status: dto.status,
          rejectionReason: dto.status === KycStatus.REJECTED ? dto.rejectionReason : null,
          reviewNote: dto.reviewNote,
          verifiedAt: dto.status === KycStatus.VERIFIED ? new Date() : null,
          verifiedBy: dto.status === KycStatus.VERIFIED ? adminId : null,
        },
        include: {
          user: {
            include: { profile: true },
            omit: { passwordHash: true },
          },
        },
      });

      // Update user kycStatus
      await tx.user.update({
        where: { id: kyc.userId },
        data: {
          kycStatus: dto.status,
        },
      });

      return updatedKyc;
    });

    this.logger.log(`Admin ${adminId} reviewed KYC ${kycId}: ${dto.status}`);

    return {
      message: `KYC verification ${dto.status === KycStatus.VERIFIED ? 'approved' : 'rejected'}`,
      data: result,
    };
  }

  // ==================== USER SETTINGS ====================

  /**
   * Get user settings
   */
  async getSettings(userId: string) {
    let settings = await this.prisma.userSettings.findUnique({
      where: { userId },
    });

    // Create default settings if not exists
    if (!settings) {
      settings = await this.prisma.userSettings.create({
        data: { userId },
      });
    }

    return settings;
  }

  /**
   * Update user settings
   */
  async updateSettings(userId: string, dto: UpdateSettingsDto) {
    // Check if settings exist, create if not
    const existing = await this.prisma.userSettings.findUnique({
      where: { userId },
    });

    if (!existing) {
      // Create with provided values
      return this.prisma.userSettings.create({
        data: {
          userId,
          ...dto,
        },
      });
    }

    // Update existing settings
    const settings = await this.prisma.userSettings.update({
      where: { userId },
      data: dto,
    });

    this.logger.log(`Settings updated for user: ${userId}`);
    return settings;
  }

  // ==================== EMERGENCY CONTACTS ====================

  /**
   * Get all emergency contacts for user
   */
  async getEmergencyContacts(userId: string) {
    const contacts = await this.prisma.emergencyContact.findMany({
      where: { userId },
      orderBy: [{ isPrimary: 'desc' }, { createdAt: 'asc' }],
    });

    return {
      data: contacts,
      total: contacts.length,
    };
  }

  /**
   * Create emergency contact
   */
  async createEmergencyContact(userId: string, dto: any) {
    // If this is set as primary, unset other primary contacts
    if (dto.isPrimary) {
      await this.prisma.emergencyContact.updateMany({
        where: { userId, isPrimary: true },
        data: { isPrimary: false },
      });
    }

    const contact = await this.prisma.emergencyContact.create({
      data: {
        userId,
        ...dto,
      },
    });

    this.logger.log(`Emergency contact created for user: ${userId}`);
    return {
      message: 'Thêm liên hệ khẩn cấp thành công',
      data: contact,
    };
  }

  /**
   * Update emergency contact
   */
  async updateEmergencyContact(userId: string, contactId: string, dto: any) {
    const existing = await this.prisma.emergencyContact.findFirst({
      where: { id: contactId, userId },
    });

    if (!existing) {
      throw new NotFoundException('Emergency contact not found');
    }

    // If this is set as primary, unset other primary contacts
    if (dto.isPrimary) {
      await this.prisma.emergencyContact.updateMany({
        where: { userId, isPrimary: true, id: { not: contactId } },
        data: { isPrimary: false },
      });
    }

    const contact = await this.prisma.emergencyContact.update({
      where: { id: contactId },
      data: dto,
    });

    this.logger.log(`Emergency contact updated: ${contactId}`);
    return {
      message: 'Cập nhật liên hệ khẩn cấp thành công',
      data: contact,
    };
  }

  /**
   * Delete emergency contact
   */
  async deleteEmergencyContact(userId: string, contactId: string) {
    const existing = await this.prisma.emergencyContact.findFirst({
      where: { id: contactId, userId },
    });

    if (!existing) {
      throw new NotFoundException('Emergency contact not found');
    }

    await this.prisma.emergencyContact.delete({
      where: { id: contactId },
    });

    this.logger.log(`Emergency contact deleted: ${contactId}`);
    return {
      message: 'Xóa liên hệ khẩn cấp thành công',
    };
  }

  // ==================== USER KYC ====================

  /**
   * Get user KYC status
   */
  async getKycStatus(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { kycStatus: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const kyc = await this.prisma.kycVerification.findUnique({
      where: { userId },
      select: {
        status: true,
        idCardFrontUrl: true,
        idCardBackUrl: true,
        selfieUrl: true,
        rejectionReason: true,
        submittedAt: true,
        verifiedAt: true,
      },
    });

    return {
      status: user.kycStatus,
      ...kyc,
    };
  }

  /**
   * Submit KYC verification
   */
  async submitKyc(userId: string, dto: any) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { kycStatus: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.kycStatus === KycStatus.VERIFIED) {
      throw new BadRequestException('KYC already verified');
    }

    if (user.kycStatus === KycStatus.PENDING) {
      throw new BadRequestException('KYC submission is pending review');
    }

    // Create or update KYC verification
    const kyc = await this.prisma.kycVerification.upsert({
      where: { userId },
      create: {
        userId,
        idCardFrontUrl: dto.idCardFrontUrl,
        idCardBackUrl: dto.idCardBackUrl,
        selfieUrl: dto.selfieUrl,
        idCardNumber: dto.idCardNumber,
        idCardName: dto.idCardName,
        status: KycStatus.PENDING,
        submittedAt: new Date(),
      },
      update: {
        idCardFrontUrl: dto.idCardFrontUrl,
        idCardBackUrl: dto.idCardBackUrl,
        selfieUrl: dto.selfieUrl,
        idCardNumber: dto.idCardNumber,
        idCardName: dto.idCardName,
        status: KycStatus.PENDING,
        submittedAt: new Date(),
        rejectionReason: null,
      },
    });

    // Update user KYC status
    await this.prisma.user.update({
      where: { id: userId },
      data: { kycStatus: KycStatus.PENDING },
    });

    const userWithEmail = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { email: true },
    });
    await this.notificationsService
      .notifyAdminsIfEnabled('kyc_pending_alert', 'KYC chờ duyệt', `Người dùng ${userWithEmail?.email ?? userId} vừa gửi yêu cầu xác minh KYC.`, { userId })
      .catch((err) => this.logger.warn(`Failed to notify admins: ${err?.message}`));

    this.logger.log(`KYC submitted for user: ${userId}`);
    return {
      message: 'Đã gửi yêu cầu xác minh thành công. Vui lòng chờ phê duyệt.',
      data: {
        status: KycStatus.PENDING,
        submittedAt: kyc.submittedAt,
      },
    };
  }

  // ==================== BLOCK USER ====================

  /**
   * Block a user
   */
  async blockUser(userId: string, blockedUserId: string) {
    if (userId === blockedUserId) {
      throw new BadRequestException('Cannot block yourself');
    }

    // Check if user exists
    const blockedUser = await this.prisma.user.findUnique({
      where: { id: blockedUserId },
    });

    if (!blockedUser) {
      throw new NotFoundException('User not found');
    }

    // Check if already blocked
    const existingBlock = await this.prisma.userBlacklist.findUnique({
      where: {
        blockerId_blockedId: {
          blockerId: userId,
          blockedId: blockedUserId,
        },
      },
    });

    if (existingBlock) {
      return { message: 'User already blocked' };
    }

    // Create block record
    await this.prisma.userBlacklist.create({
      data: {
        blockerId: userId,
        blockedId: blockedUserId,
      },
    });

    // Emit socket event to notify both users
    this.chatGateway.emitUserBlocked(userId, blockedUserId);

    this.logger.log(`User ${userId} blocked user ${blockedUserId}`);
    return { message: 'User blocked successfully' };
  }

  /**
   * Unblock a user
   */
  async unblockUser(userId: string, blockedUserId: string) {
    const block = await this.prisma.userBlacklist.findUnique({
      where: {
        blockerId_blockedId: {
          blockerId: userId,
          blockedId: blockedUserId,
        },
      },
    });

    if (!block) {
      throw new NotFoundException('User is not blocked');
    }

    await this.prisma.userBlacklist.delete({
      where: {
        blockerId_blockedId: {
          blockerId: userId,
          blockedId: blockedUserId,
        },
      },
    });

    // Emit socket event to notify both users
    this.chatGateway.emitUserUnblocked(userId, blockedUserId);

    this.logger.log(`User ${userId} unblocked user ${blockedUserId}`);
    return { message: 'User unblocked successfully' };
  }

  /**
   * Get list of blocked users
   */
  async getBlockedUsers(userId: string) {
    const blockedUsers = await this.prisma.userBlacklist.findMany({
      where: { blockerId: userId },
      include: {
        blocked: {
          select: {
            id: true,
            profile: {
              select: {
                displayName: true,
                fullName: true,
                avatarUrl: true,
              },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return {
      data: blockedUsers.map((b) => ({
        id: b.blockedId,
        name: b.blocked.profile?.displayName || b.blocked.profile?.fullName || 'User',
        avatarUrl: b.blocked.profile?.avatarUrl,
        blockedAt: b.createdAt,
      })),
    };
  }

  /**
   * Check if a user is blocked
   */
  async isUserBlocked(userId: string, targetUserId: string): Promise<boolean> {
    const block = await this.prisma.userBlacklist.findFirst({
      where: {
        OR: [
          { blockerId: userId, blockedId: targetUserId },
          { blockerId: targetUserId, blockedId: userId },
        ],
      },
    });

    return !!block;
  }
}
