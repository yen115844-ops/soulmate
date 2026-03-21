import {
    BadRequestException,
    ForbiddenException,
    Inject,
    Injectable,
    Logger,
    NotFoundException,
    forwardRef,
} from '@nestjs/common';
import { PaginationDto } from '../../common/dto/pagination.dto';
import { PrismaService } from '../../database/prisma/prisma.service';
import { UserStatus } from '../../generated/prisma/client';
import { ChatGateway } from '../chat/chat.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { UploadService } from '../upload/upload.service';
import {
    AdminUserQueryDto,
    UpdateLocationDto,
    UpdateProfileDto,
    UpdateSettingsDto,
    UpdateUserStatusDto,
} from './dto';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    private readonly uploadService: UploadService,
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

    // Auto-populate denormalized city/district names from provinceId/districtId
    if (dto.provinceId) {
      const province = await this.prisma.province.findUnique({
        where: { id: dto.provinceId },
      });
      if (province) {
        updateData.city = province.name;
        updateData.provinceId = province.id;
      }
    } else if (dto.provinceId === null) {
      updateData.provinceId = null;
      updateData.city = null;
    }

    if (dto.districtId) {
      const district = await this.prisma.district.findUnique({
        where: { id: dto.districtId },
      });
      if (district) {
        updateData.district = district.name;
        updateData.districtId = district.id;
      }
    } else if (dto.districtId === null) {
      updateData.districtId = null;
      updateData.district = null;
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

    this.uploadService.validateMagicBytes(file);
    await this.uploadService.optimizeImage(file, {
      maxWidth: 1024,
      maxHeight: 1024,
      quality: 82,
    });

    // Generate avatar URL (use the public file serving endpoint)
    const avatarUrl = this.uploadService.getFileUrl(file.filename);
    const oldAvatarUrl = existingProfile.avatarUrl;

    // Update profile with new avatar URL
    const profile = await this.prisma.profile.update({
      where: { userId },
      data: { avatarUrl },
    });

    this.logger.log(`Avatar updated for user: ${userId}`);

    if (oldAvatarUrl && oldAvatarUrl !== avatarUrl) {
      this.uploadService.deleteFileByUrl(oldAvatarUrl);
    }

    return {
      avatarUrl,
      filename: file.filename,
      originalName: file.originalname,
      size: file.size,
      mimetype: file.mimetype,
    };
  }

  async uploadProfilePhoto(userId: string, file: Express.Multer.File) {
    const existingProfile = await this.prisma.profile.findUnique({
      where: { userId },
    });

    if (!existingProfile) {
      throw new NotFoundException('Profile not found');
    }

    this.uploadService.validateMagicBytes(file);
    await this.uploadService.optimizeImage(file, {
      maxWidth: 1440,
      maxHeight: 1440,
      quality: 82,
    });

    const photoUrl = this.uploadService.getFileUrl(file.filename);
    const currentPhotos = Array.isArray(existingProfile.photos)
      ? (existingProfile.photos as string[])
      : [];

    if (!currentPhotos.includes(photoUrl)) {
      currentPhotos.push(photoUrl);
    }

    await this.prisma.profile.update({
      where: { userId },
      data: { photos: currentPhotos },
    });

    return {
      photoUrl,
      filename: file.filename,
      originalName: file.originalname,
      size: file.size,
      mimetype: file.mimetype,
      totalPhotos: currentPhotos.length,
    };
  }

  async deleteProfilePhoto(userId: string, photoUrl: string) {
    const existingProfile = await this.prisma.profile.findUnique({
      where: { userId },
    });

    if (!existingProfile) {
      throw new NotFoundException('Profile not found');
    }

    const currentPhotos = Array.isArray(existingProfile.photos)
      ? (existingProfile.photos as string[])
      : [];
    const nextPhotos = currentPhotos.filter((url) => url !== photoUrl);

    if (nextPhotos.length === currentPhotos.length) {
      throw new BadRequestException('Photo not found in profile');
    }

    await this.prisma.profile.update({
      where: { userId },
      data: { photos: nextPhotos },
    });

    this.uploadService.deleteFileByUrl(photoUrl);

    return {
      deleted: true,
      photoUrl,
      totalPhotos: nextPhotos.length,
    };
  }

  /**
   * Update user location
   */
  async updateLocation(userId: string, dto: UpdateLocationDto) {
    const updateData: any = {
      currentLat: dto.currentLat,
      currentLng: dto.currentLng,
    };

    // Auto-populate denormalized city/district names from provinceId/districtId
    if (dto.provinceId) {
      const province = await this.prisma.province.findUnique({
        where: { id: dto.provinceId },
      });
      if (province) {
        updateData.city = province.name;
        updateData.provinceId = province.id;
      }
    } else if (dto.city !== undefined) {
      updateData.city = dto.city;
    }

    if (dto.districtId) {
      const district = await this.prisma.district.findUnique({
        where: { id: dto.districtId },
      });
      if (district) {
        updateData.district = district.name;
        updateData.districtId = district.id;
      }
    } else if (dto.district !== undefined) {
      updateData.district = dto.district;
    }

    const profile = await this.prisma.profile.update({
      where: { userId },
      data: updateData,
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
        {
          profile: {
            fullName: { contains: filters.search, mode: 'insensitive' },
          },
        },
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
        partnerId: f.partnerId,
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
    const [bookingsCount, reviewsCount, reviewsData, partnerProfile] =
      await Promise.all([
        // Total bookings as user
        this.prisma.booking.count({
          where: { userId },
        }),
        // Total reviews written
        this.prisma.review.count({
          where: { reviewerId: userId },
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
      // Partner info
      isPartner: !!partnerProfile,
      partnerStatus: partnerProfile
        ? {
            isVerified: partnerProfile.isVerified,
            isAvailable: partnerProfile.isAvailable,
            verificationBadge: partnerProfile.verificationBadge,
            totalBookings: partnerProfile.totalBookings,
            completedBookings: partnerProfile.completedBookings,
            averageRating: partnerProfile.averageRating,
            totalReviews: partnerProfile.totalReviews,
          }
        : null,
    };
  }

  // ==================== ADMIN METHODS ====================

  /**
   * Admin: Get user statistics
   */
  async adminGetUserStats() {
    const [total, active, pending, suspended, banned, partners, admins] =
      await Promise.all([
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
        name:
          b.blocked.profile?.displayName ||
          b.blocked.profile?.fullName ||
          'User',
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
