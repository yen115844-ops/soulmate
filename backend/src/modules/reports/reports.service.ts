import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { NotificationType } from '@prisma/client';
import { PrismaService } from '../../database/prisma/prisma.service';
import { NotificationsService } from '../notifications';
import { CreateReportDto, ReportQueryDto, ResolveReportDto } from './dto';

@Injectable()
export class ReportsService {
  private readonly logger = new Logger(ReportsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  /**
   * Create a report
   */
  async createReport(reporterId: string, dto: CreateReportDto) {
    if (reporterId === dto.reportedId) {
      throw new BadRequestException('Bạn không thể báo cáo chính mình');
    }

    // Check for duplicate recent report
    const existingReport = await this.prisma.report.findFirst({
      where: {
        reporterId,
        reportedId: dto.reportedId,
        type: dto.type,
        referenceId: dto.referenceId,
        status: 'pending',
      },
    });

    if (existingReport) {
      throw new BadRequestException('Bạn đã báo cáo nội dung này rồi');
    }

    const report = await this.prisma.report.create({
      data: {
        reporterId,
        reportedId: dto.reportedId,
        type: dto.type,
        referenceId: dto.referenceId,
        reason: dto.reason,
        description: dto.description,
        evidence: dto.evidence || [],
        status: 'pending',
      },
    });

    // Notify admins
    await this.notificationsService
      .notifyAdminsIfEnabled(
        'report_alert',
        'Báo cáo mới',
        `Báo cáo mới về ${dto.type}: ${dto.reason}`,
        { reportId: report.id, type: dto.type },
      )
      .catch((err) => this.logger.warn(`Failed to notify admins of report: ${err?.message}`));

    this.logger.log(`Report created by ${reporterId} against ${dto.reportedId}`);

    return {
      success: true,
      message: 'Báo cáo đã được gửi. Đội ngũ hỗ trợ sẽ xem xét sớm nhất.',
      reportId: report.id,
    };
  }

  /**
   * Get user's submitted reports
   */
  async getMyReports(userId: string) {
    return this.prisma.report.findMany({
      where: { reporterId: userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  /**
   * Block a user
   */
  async blockUser(blockerId: string, blockedId: string) {
    if (blockerId === blockedId) {
      throw new BadRequestException('Bạn không thể chặn chính mình');
    }

    const existing = await this.prisma.userBlacklist.findFirst({
      where: { blockerId, blockedId },
    });

    if (existing) {
      return { message: 'Đã chặn người dùng này' };
    }

    await this.prisma.userBlacklist.create({
      data: { blockerId, blockedId },
    });

    this.logger.log(`User ${blockerId} blocked ${blockedId}`);
    return { success: true, message: 'Đã chặn người dùng' };
  }

  /**
   * Unblock a user
   */
  async unblockUser(blockerId: string, blockedId: string) {
    await this.prisma.userBlacklist.deleteMany({
      where: { blockerId, blockedId },
    });
    return { success: true, message: 'Đã bỏ chặn người dùng' };
  }

  /**
   * Get blocked users list
   */
  async getBlockedUsers(userId: string) {
    const blocked = await this.prisma.userBlacklist.findMany({
      where: { blockerId: userId },
      include: {
        blocked: {
          include: { profile: true },
          omit: { passwordHash: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return blocked.map((b) => ({
      id: b.blockedId,
      displayName: b.blocked.profile?.displayName,
      avatarUrl: b.blocked.profile?.avatarUrl,
      blockedAt: b.createdAt,
    }));
  }

  // ==================== ADMIN ====================

  /**
   * Admin: Get all reports
   */
  async adminGetReports(query: ReportQueryDto) {
    const { status, page = 1, limit = 20 } = query;
    const skip = (page - 1) * limit;

    const where: any = {};
    if (status) where.status = status;

    const [reports, total] = await Promise.all([
      this.prisma.report.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.report.count({ where }),
    ]);

    return {
      data: reports,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  /**
   * Admin: Resolve a report
   */
  async adminResolveReport(reportId: string, adminId: string, dto: ResolveReportDto) {
    const report = await this.prisma.report.findUnique({ where: { id: reportId } });
    if (!report) throw new NotFoundException('Report not found');

    if (report.status !== 'pending' && report.status !== 'reviewing') {
      throw new BadRequestException('Report already handled');
    }

    const updated = await this.prisma.report.update({
      where: { id: reportId },
      data: {
        status: dto.status,
        handledBy: adminId,
        handledAt: new Date(),
        resolution: dto.resolution,
      },
    });

    // Notify reporter
    await this.notificationsService
      .sendNotification({
        userId: report.reporterId,
        type: NotificationType.SYSTEM,
        title: 'Báo cáo đã được xử lý',
        body:
          dto.status === 'resolved'
            ? 'Báo cáo của bạn đã được xem xét và xử lý.'
            : 'Báo cáo của bạn đã được xem xét nhưng không vi phạm.',
        data: { reportId },
      })
      .catch((err) => this.logger.warn(`Failed to notify report resolution: ${err?.message}`));

    this.logger.log(`Report ${reportId} resolved by admin ${adminId}: ${dto.status}`);
    return updated;
  }
}
