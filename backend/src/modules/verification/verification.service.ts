import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma/prisma.service';
import { KycStatus, NotificationType } from '../../generated/prisma/client';
import { NotificationsService } from '../notifications';
import { ReviewVerificationDto, SubmitSelfieDto } from './dto';

// Thresholds for auto-verification
// NOTE: For now, we disable auto-verification and require manual CMS review.
// Set AUTO_APPROVE_THRESHOLD to a very high value (1.1) to always require manual review.
// In production, integrate with actual liveness API and lower this threshold.
const AUTO_APPROVE_THRESHOLD = 1.1; // Disabled: requires manual CMS review
const MANUAL_REVIEW_THRESHOLD = 0.0; // Always send to pending

@Injectable()
export class VerificationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  /**
   * Submit selfie for soft verification
   */
  async submitSelfie(
    userId: string,
    selfieFile: Express.Multer.File,
    dto: SubmitSelfieDto,
  ) {
    // Generate selfie URL
    const selfieUrl = `/uploads/verification/${selfieFile.filename}`;

    // Simulate liveness check (in production, call actual liveness API)
    // e.g., AWS Rekognition, FPT.AI, VNPT eKYC
    const livenessResult = await this.performLivenessCheck(selfieUrl);

    // Determine status based on liveness score
    let status: KycStatus;
    let isAutoVerified = false;

    if (livenessResult.score >= AUTO_APPROVE_THRESHOLD) {
      status = KycStatus.VERIFIED;
      isAutoVerified = true;
    } else if (livenessResult.score >= MANUAL_REVIEW_THRESHOLD) {
      status = KycStatus.PENDING;
    } else {
      status = KycStatus.REJECTED;
    }

    // Upsert verification record
    const verification = await this.prisma.kycVerification.upsert({
      where: { userId },
      create: {
        userId,
        selfieUrl,
        livenessScore: livenessResult.score,
        livenessCheckId: livenessResult.checkId,
        status,
        isAutoVerified,
        submittedAt: new Date(),
        verifiedAt: isAutoVerified ? new Date() : null,
        deviceInfo: dto.deviceInfo,
      },
      update: {
        selfieUrl,
        livenessScore: livenessResult.score,
        livenessCheckId: livenessResult.checkId,
        status,
        isAutoVerified,
        submittedAt: new Date(),
        verifiedAt: isAutoVerified ? new Date() : null,
        rejectionReason: null,
        deviceInfo: dto.deviceInfo,
      },
    });

    // Update user's KYC status
    await this.prisma.user.update({
      where: { id: userId },
      data: { kycStatus: status },
    });

    // Send notification based on result
    if (status === KycStatus.VERIFIED) {
      await this.notificationsService.createNotification({
        userId,
        type: NotificationType.SYSTEM,
        title: 'Xác thực thành công! ✅',
        body: 'Tài khoản của bạn đã được xác thực. Bạn đã nhận được huy hiệu tick xanh.',
        actionType: 'profile',
      });
    } else if (status === KycStatus.PENDING) {
      await this.notificationsService.createNotification({
        userId,
        type: NotificationType.SYSTEM,
        title: 'Đang xem xét xác thực',
        body: 'Yêu cầu xác thực của bạn đang được xem xét. Chúng tôi sẽ thông báo kết quả trong 24 giờ.',
        actionType: 'profile',
      });
    } else {
      await this.notificationsService.createNotification({
        userId,
        type: NotificationType.SYSTEM,
        title: 'Xác thực không thành công',
        body: 'Ảnh selfie không đạt yêu cầu. Vui lòng thử lại với ánh sáng tốt hơn và khuôn mặt rõ ràng.',
        actionType: 'verification',
      });
    }

    return {
      id: verification.id,
      status: verification.status,
      livenessScore: Number(verification.livenessScore),
      isAutoVerified: verification.isAutoVerified,
      verifiedAt: verification.verifiedAt,
      submittedAt: verification.submittedAt,
    };
  }

  /**
   * Get verification status for a user
   */
  async getStatus(userId: string) {
    const verification = await this.prisma.kycVerification.findUnique({
      where: { userId },
    });

    if (!verification) {
      return {
        status: KycStatus.NONE,
        isVerified: false,
      };
    }

    return {
      id: verification.id,
      status: verification.status,
      livenessScore: verification.livenessScore
        ? Number(verification.livenessScore)
        : null,
      isAutoVerified: verification.isAutoVerified,
      verifiedAt: verification.verifiedAt,
      submittedAt: verification.submittedAt,
      rejectionReason: verification.rejectionReason,
      isVerified: verification.status === KycStatus.VERIFIED,
    };
  }

  /**
   * Perform liveness check (placeholder for now)
   *
   * CURRENT STATUS: Returns a random score for development.
   * All submissions go to PENDING for manual CMS review.
   *
   * TODO: Future Enhancement - Integrate with actual liveness API:
   * - AWS Rekognition Face Liveness (recommended)
   * - FPT.AI eKYC (Vietnam)
   * - VNPT eKYC (Vietnam)
   * - Jumio, Onfido (international)
   *
   * When implementing:
   * 1. Call the liveness API with selfie URL
   * 2. Get actual liveness score and face quality metrics
   * 3. Lower AUTO_APPROVE_THRESHOLD to 0.85 to enable auto-verify
   */
  private async performLivenessCheck(selfieUrl: string): Promise<{
    score: number;
    checkId: string;
  }> {
    // Placeholder: Generate random score for development
    // This will always result in PENDING status due to high AUTO_APPROVE_THRESHOLD
    const score = 0.75 + Math.random() * 0.15; // Random between 0.75 and 0.90

    return {
      score: Math.round(score * 10000) / 10000,
      checkId: `liveness_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    };
  }

  // ==================== Admin Functions ====================

  /**
   * Get verification stats for admin dashboard
   */
  async adminGetStats() {
    const [total, pending, verified, rejected, none] = await Promise.all([
      this.prisma.kycVerification.count(),
      this.prisma.kycVerification.count({
        where: { status: KycStatus.PENDING },
      }),
      this.prisma.kycVerification.count({
        where: { status: KycStatus.VERIFIED },
      }),
      this.prisma.kycVerification.count({
        where: { status: KycStatus.REJECTED },
      }),
      this.prisma.user.count({ where: { kycStatus: KycStatus.NONE } }),
    ]);

    return { total, pending, verified, rejected, none };
  }

  /**
   * Get paginated verification list for admin
   */
  async adminGetList(params: {
    page?: number;
    limit?: number;
    status?: KycStatus;
    search?: string;
    sortBy?: string;
    sortOrder?: 'asc' | 'desc';
  }) {
    const {
      page = 1,
      limit = 10,
      status,
      search,
      sortBy = 'submittedAt',
      sortOrder = 'desc',
    } = params;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (status) {
      where.status = status;
    }

    if (search) {
      where.user = {
        OR: [
          { email: { contains: search, mode: 'insensitive' } },
          { profile: { fullName: { contains: search, mode: 'insensitive' } } },
        ],
      };
    }

    const [data, total] = await Promise.all([
      this.prisma.kycVerification.findMany({
        where,
        skip,
        take: limit,
        orderBy: { [sortBy]: sortOrder },
        include: {
          user: {
            select: {
              id: true,
              email: true,
              profile: {
                select: {
                  fullName: true,
                  avatarUrl: true,
                },
              },
            },
          },
        },
      }),
      this.prisma.kycVerification.count({ where }),
    ]);

    return {
      data,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * Get verification detail by ID
   */
  async adminGetById(id: string) {
    const verification = await this.prisma.kycVerification.findUnique({
      where: { id },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            phone: true,
            profile: {
              select: {
                fullName: true,
                avatarUrl: true,
                dateOfBirth: true,
                gender: true,
              },
            },
          },
        },
      },
    });

    if (!verification) {
      throw new NotFoundException('Verification not found');
    }

    return verification;
  }

  /**
   * Review verification (approve/reject)
   */
  async adminReview(id: string, adminId: string, dto: ReviewVerificationDto) {
    const verification = await this.prisma.kycVerification.findUnique({
      where: { id },
      include: { user: true },
    });

    if (!verification) {
      throw new NotFoundException('Verification not found');
    }

    if (verification.status === KycStatus.VERIFIED) {
      throw new BadRequestException('This verification is already approved');
    }

    // Update verification
    const updated = await this.prisma.kycVerification.update({
      where: { id },
      data: {
        status: dto.status,
        verifiedAt: dto.status === KycStatus.VERIFIED ? new Date() : null,
        verifiedBy: dto.status === KycStatus.VERIFIED ? adminId : null,
        rejectionReason:
          dto.status === KycStatus.REJECTED ? dto.rejectionReason : null,
        reviewNote: dto.reviewNote,
        isAutoVerified: false,
      },
    });

    // Update user's KYC status
    await this.prisma.user.update({
      where: { id: verification.userId },
      data: { kycStatus: dto.status },
    });

    // Send notification to user
    if (dto.status === KycStatus.VERIFIED) {
      await this.notificationsService.createNotification({
        userId: verification.userId,
        type: NotificationType.SYSTEM,
        title: 'Xác thực thành công! ✅',
        body: 'Tài khoản của bạn đã được xác thực. Bạn đã nhận được huy hiệu tick xanh.',
        actionType: 'profile',
      });
    } else if (dto.status === KycStatus.REJECTED) {
      await this.notificationsService.createNotification({
        userId: verification.userId,
        type: NotificationType.SYSTEM,
        title: 'Xác thực bị từ chối',
        body:
          dto.rejectionReason ||
          'Yêu cầu xác thực của bạn không được chấp nhận. Vui lòng thử lại.',
        actionType: 'verification',
      });
    }

    return updated;
  }
}
