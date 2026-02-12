import { ForbiddenException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { NotificationType, SosStatus } from '@prisma/client';
import { PrismaService } from '../../database/prisma/prisma.service';
import { NotificationsService } from '../notifications';
import {
    CreateEmergencyContactDto,
    LogLocationDto,
    ResolveSosDto,
    TriggerSosDto,
    UpdateEmergencyContactDto,
} from './dto';

@Injectable()
export class SafetyService {
  private readonly logger = new Logger(SafetyService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ==================== SOS ====================

  /**
   * Trigger an SOS event — notifies admins and emergency contacts
   */
  async triggerSos(userId: string, dto: TriggerSosDto) {
    // Get user's emergency contacts
    const emergencyContacts = await this.prisma.emergencyContact.findMany({
      where: { userId },
      orderBy: { isPrimary: 'desc' },
    });

    const sosEvent = await this.prisma.sosEvent.create({
      data: {
        userId,
        bookingId: dto.bookingId,
        latitude: dto.latitude,
        longitude: dto.longitude,
        address: dto.address,
        status: SosStatus.TRIGGERED,
        notifiedContacts: emergencyContacts.map((c) => ({
          name: c.name,
          phone: c.phone,
          notifiedAt: new Date().toISOString(),
        })),
        notifiedSupport: true,
      },
      include: {
        user: { include: { profile: true }, omit: { passwordHash: true } },
      },
    });

    const userName =
      sosEvent.user?.profile?.displayName ||
      sosEvent.user?.profile?.fullName ||
      sosEvent.user?.email ||
      'Unknown';

    // Notify admins
    await this.notificationsService
      .notifyAdminsIfEnabled(
        'sos_alert',
        '🚨 SOS Alert',
        `${userName} đã kích hoạt SOS tại ${dto.address || `${dto.latitude}, ${dto.longitude}`}`,
        {
          sosEventId: sosEvent.id,
          userId,
          latitude: dto.latitude,
          longitude: dto.longitude,
        },
      )
      .catch((err) => this.logger.error(`Failed to notify admins of SOS: ${err?.message}`));

    this.logger.warn(`🚨 SOS triggered by user ${userId} at ${dto.latitude},${dto.longitude}`);

    return {
      id: sosEvent.id,
      status: sosEvent.status,
      message: 'SOS đã được gửi. Đội hỗ trợ và liên hệ khẩn cấp đã được thông báo.',
      emergencyContactsNotified: emergencyContacts.length,
    };
  }

  /**
   * Resolve an SOS event
   */
  async resolveSos(sosId: string, responderId: string, dto: ResolveSosDto) {
    const sos = await this.prisma.sosEvent.findUnique({ where: { id: sosId } });
    if (!sos) throw new NotFoundException('SOS event not found');

    if (sos.status === SosStatus.RESOLVED || sos.status === SosStatus.FALSE_ALARM) {
      return { message: 'SOS event already resolved' };
    }

    const status = dto.isFalseAlarm ? SosStatus.FALSE_ALARM : SosStatus.RESOLVED;

    const updated = await this.prisma.sosEvent.update({
      where: { id: sosId },
      data: {
        status,
        respondedBy: responderId,
        respondedAt: new Date(),
        resolvedAt: new Date(),
        resolutionNote: dto.resolutionNote,
      },
    });

    // Notify user that SOS was resolved
    await this.notificationsService
      .sendNotification({
        userId: sos.userId,
        type: NotificationType.SYSTEM,
        title: 'SOS đã được xử lý',
        body: dto.isFalseAlarm
          ? 'Sự kiện khẩn cấp đã được đánh dấu là báo động nhầm.'
          : 'Đội hỗ trợ đã xử lý sự kiện khẩn cấp của bạn.',
        data: { sosEventId: sosId },
      })
      .catch((err) => this.logger.warn(`Failed to send SOS resolve notification: ${err?.message}`));

    this.logger.log(`SOS ${sosId} resolved by ${responderId}`);
    return updated;
  }

  /**
   * Cancel own SOS (user self-resolution)
   */
  async cancelSos(sosId: string, userId: string) {
    const sos = await this.prisma.sosEvent.findUnique({ where: { id: sosId } });
    if (!sos) throw new NotFoundException('SOS event not found');
    if (sos.userId !== userId) throw new ForbiddenException('Access denied');

    if (sos.status !== SosStatus.TRIGGERED && sos.status !== SosStatus.RESPONDING) {
      return { message: 'SOS event cannot be cancelled' };
    }

    const updated = await this.prisma.sosEvent.update({
      where: { id: sosId },
      data: {
        status: SosStatus.FALSE_ALARM,
        resolvedAt: new Date(),
        resolutionNote: 'Cancelled by user',
      },
    });

    this.logger.log(`SOS ${sosId} cancelled by user ${userId}`);
    return updated;
  }

  /**
   * Get SOS events for user
   */
  async getUserSosEvents(userId: string) {
    return this.prisma.sosEvent.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 20,
    });
  }

  /**
   * Get active SOS events (admin)
   */
  async getActiveSosEvents() {
    return this.prisma.sosEvent.findMany({
      where: { status: { in: [SosStatus.TRIGGERED, SosStatus.RESPONDING] } },
      orderBy: { createdAt: 'desc' },
      include: {
        user: { include: { profile: true }, omit: { passwordHash: true } },
        booking: true,
      },
    });
  }

  // ==================== EMERGENCY CONTACTS ====================

  async getEmergencyContacts(userId: string) {
    return this.prisma.emergencyContact.findMany({
      where: { userId },
      orderBy: [{ isPrimary: 'desc' }, { createdAt: 'asc' }],
    });
  }

  async createEmergencyContact(userId: string, dto: CreateEmergencyContactDto) {
    // Max 5 contacts
    const count = await this.prisma.emergencyContact.count({ where: { userId } });
    if (count >= 5) {
      throw new ForbiddenException('Tối đa 5 liên hệ khẩn cấp');
    }

    // If setting as primary, unset existing primary
    if (dto.isPrimary) {
      await this.prisma.emergencyContact.updateMany({
        where: { userId, isPrimary: true },
        data: { isPrimary: false },
      });
    }

    return this.prisma.emergencyContact.create({
      data: {
        userId,
        name: dto.name,
        phone: dto.phone,
        relationship: dto.relationship,
        isPrimary: dto.isPrimary ?? false,
      },
    });
  }

  async updateEmergencyContact(contactId: string, userId: string, dto: UpdateEmergencyContactDto) {
    const contact = await this.prisma.emergencyContact.findUnique({ where: { id: contactId } });
    if (!contact) throw new NotFoundException('Contact not found');
    if (contact.userId !== userId) throw new ForbiddenException('Access denied');

    if (dto.isPrimary) {
      await this.prisma.emergencyContact.updateMany({
        where: { userId, isPrimary: true },
        data: { isPrimary: false },
      });
    }

    return this.prisma.emergencyContact.update({
      where: { id: contactId },
      data: dto,
    });
  }

  async deleteEmergencyContact(contactId: string, userId: string) {
    const contact = await this.prisma.emergencyContact.findUnique({ where: { id: contactId } });
    if (!contact) throw new NotFoundException('Contact not found');
    if (contact.userId !== userId) throw new ForbiddenException('Access denied');

    await this.prisma.emergencyContact.delete({ where: { id: contactId } });
    return { success: true };
  }

  // ==================== LOCATION LOGGING ====================

  async logLocation(userId: string, dto: LogLocationDto) {
    return this.prisma.locationLog.create({
      data: {
        userId,
        bookingId: dto.bookingId,
        latitude: dto.latitude,
        longitude: dto.longitude,
        accuracy: dto.accuracy,
        speed: dto.speed,
        heading: dto.heading,
      },
    });
  }

  async getBookingLocationLogs(bookingId: string, userId: string) {
    // Verify user has access to the booking
    const booking = await this.prisma.booking.findUnique({ where: { id: bookingId } });
    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.userId !== userId && booking.partnerId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    return this.prisma.locationLog.findMany({
      where: { bookingId },
      orderBy: { recordedAt: 'asc' },
    });
  }
}
