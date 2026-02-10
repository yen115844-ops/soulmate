import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../../database/prisma/prisma.service';
import { RegisterDeviceDto } from '../dto/register-device.dto';

@Injectable()
export class DeviceTokenService {
  private readonly logger = new Logger(DeviceTokenService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Register or update a device token for a user
   */
  async registerToken(userId: string, dto: RegisterDeviceDto) {
    try {
      // Check if token already exists
      const existingToken = await this.prisma.deviceToken.findUnique({
        where: { token: dto.token },
      });

      if (existingToken) {
        // Token exists - update it (might be transferred to new user)
        if (existingToken.userId !== userId) {
          // Token was registered to different user - transfer ownership
          this.logger.log(
            `Transferring device token from user ${existingToken.userId} to ${userId}`,
          );
        }

        const updated = await this.prisma.deviceToken.update({
          where: { token: dto.token },
          data: {
            userId,
            platform: dto.platform,
            deviceInfo: dto.deviceInfo,
            isActive: true,
            lastUsedAt: new Date(),
          },
        });

        return {
          success: true,
          message: 'Device token updated',
          tokenId: updated.id,
        };
      }

      // Create new token
      const created = await this.prisma.deviceToken.create({
        data: {
          userId,
          token: dto.token,
          platform: dto.platform,
          deviceInfo: dto.deviceInfo,
          isActive: true,
        },
      });

      this.logger.log(`Registered new device token for user ${userId}`);

      return {
        success: true,
        message: 'Device token registered',
        tokenId: created.id,
      };
    } catch (error: any) {
      this.logger.error(`Failed to register device token: ${error.message}`);
      throw error;
    }
  }

  /**
   * Unregister a device token (e.g., on logout)
   */
  async unregisterToken(userId: string, token: string) {
    try {
      const result = await this.prisma.deviceToken.deleteMany({
        where: {
          userId,
          token,
        },
      });

      if (result.count === 0) {
        return {
          success: false,
          message: 'Device token not found',
        };
      }

      this.logger.log(`Unregistered device token for user ${userId}`);

      return {
        success: true,
        message: 'Device token unregistered',
      };
    } catch (error: any) {
      this.logger.error(`Failed to unregister device token: ${error.message}`);
      throw error;
    }
  }

  /**
   * Unregister all device tokens for a user (e.g., on logout from all devices)
   */
  async unregisterAllTokens(userId: string) {
    try {
      const result = await this.prisma.deviceToken.deleteMany({
        where: { userId },
      });

      this.logger.log(
        `Unregistered ${result.count} device tokens for user ${userId}`,
      );

      return {
        success: true,
        message: `Unregistered ${result.count} device(s)`,
        count: result.count,
      };
    } catch (error: any) {
      this.logger.error(`Failed to unregister all tokens: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get all active device tokens for a user
   */
  async getUserTokens(userId: string) {
    const tokens = await this.prisma.deviceToken.findMany({
      where: {
        userId,
        isActive: true,
      },
      select: {
        id: true,
        platform: true,
        deviceInfo: true,
        lastUsedAt: true,
        createdAt: true,
      },
    });

    return {
      devices: tokens,
      count: tokens.length,
    };
  }

  /**
   * Update last used timestamp for a token
   */
  async updateLastUsed(token: string) {
    try {
      await this.prisma.deviceToken.update({
        where: { token },
        data: { lastUsedAt: new Date() },
      });
    } catch (error) {
      // Silently fail - not critical
    }
  }

  /**
   * Cleanup inactive/old tokens
   */
  async cleanupOldTokens(daysOld: number = 90) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysOld);

    const result = await this.prisma.deviceToken.deleteMany({
      where: {
        OR: [
          { isActive: false },
          { lastUsedAt: { lt: cutoffDate } },
        ],
      },
    });

    this.logger.log(`Cleaned up ${result.count} old/inactive device tokens`);

    return {
      deletedCount: result.count,
    };
  }
}
