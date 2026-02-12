import {
    BadRequestException,
    ForbiddenException,
    Injectable,
    Logger,
    NotFoundException,
} from '@nestjs/common';
import { BookingStatus, NotificationType } from '@prisma/client';
import { Decimal } from '@prisma/client/runtime/library';
import { PrismaService } from '../../database/prisma/prisma.service';
import { NotificationsService } from '../notifications';
import { SettingsService } from '../settings/settings.service';
import { WalletService } from '../wallet/wallet.service';
import { AdminBookingQueryDto, BookingQueryDto, CancelBookingDto, CreateBookingDto, UpdateBookingStatusDto } from './dto';

/** Combine date with time-only (DB Time → full DateTime for API) */
function combineDateAndTime(date: Date, time: Date): Date {
  const result = new Date(date);
  result.setUTCHours(
    time.getUTCHours(),
    time.getUTCMinutes(),
    time.getUTCSeconds(),
    0,
  );
  return result;
}

/** Map booking so startTime/endTime have correct date (not 1970-01-01) */
function withCombinedDateTime<
  T extends { date: Date; startTime: Date; endTime: Date },
>(booking: T): T {
  return {
    ...booking,
    startTime: combineDateAndTime(booking.date, booking.startTime),
    endTime: combineDateAndTime(booking.date, booking.endTime),
  };
}

@Injectable()
export class BookingsService {
  private readonly logger = new Logger(BookingsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    private readonly settingsService: SettingsService,
    private readonly walletService: WalletService,
  ) {}

  /**
   * Generate unique booking code
   */
  private generateBookingCode(): string {
    const timestamp = Date.now().toString(36).toUpperCase();
    const random = Math.random().toString(36).substring(2, 6).toUpperCase();
    return `BK-${timestamp}${random}`;
  }

  /**
   * Create a new booking
   */
  async createBooking(userId: string, dto: CreateBookingDto) {
    // Check if either user has blocked the other
    const blockExists = await this.prisma.userBlacklist.findFirst({
      where: {
        OR: [
          { blockerId: userId, blockedId: dto.partnerId },
          { blockerId: dto.partnerId, blockedId: userId },
        ],
      },
    });
    
    if (blockExists) {
      throw new ForbiddenException('Không thể đặt lịch với người dùng này');
    }

    // Get partner profile
    const partnerProfile = await this.prisma.partnerProfile.findUnique({
      where: { userId: dto.partnerId },
      include: { user: true },
    });

    if (!partnerProfile) {
      throw new NotFoundException('Partner not found');
    }

    if (!partnerProfile.isAvailable) {
      throw new BadRequestException('Partner is not available');
    }

    if (dto.partnerId === userId) {
      throw new BadRequestException('Cannot book yourself');
    }

    const requireKycForPartner = await this.settingsService.getBool('require_kyc_for_partner', true);
    if (requireKycForPartner && partnerProfile.user.kycStatus !== 'VERIFIED') {
      throw new BadRequestException('Đối tác chưa xác minh KYC, chưa thể nhận đặt chỗ');
    }

    const minBookingHours = await this.settingsService.getNumber('min_booking_hours', 1);
    const maxBookingHours = await this.settingsService.getNumber('max_booking_hours', 8);
    const advanceBookingDays = await this.settingsService.getNumber('advance_booking_days', 30);
    const serviceFeePercent = await this.settingsService.getNumber('service_fee_percent', 15);
    const autoConfirmBooking = await this.settingsService.getBool('auto_confirm_booking', false);

    const date = new Date(dto.date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const maxAdvanceDate = new Date(today);
    maxAdvanceDate.setDate(maxAdvanceDate.getDate() + advanceBookingDays);
    if (date < today) {
      throw new BadRequestException('Ngày đặt chỗ không được ở quá khứ');
    }
    if (date > maxAdvanceDate) {
      throw new BadRequestException(`Chỉ có thể đặt trước tối đa ${advanceBookingDays} ngày`);
    }

    const startTime = new Date(`1970-01-01T${dto.startTime}:00`);
    const endTime = new Date(`1970-01-01T${dto.endTime}:00`);
    const durationMs = endTime.getTime() - startTime.getTime();
    const durationHours = durationMs / (1000 * 60 * 60);

    const minHours = Math.max(minBookingHours, partnerProfile.minimumHours);
    if (durationHours < minHours) {
      throw new BadRequestException(`Thời lượng đặt tối thiểu là ${minHours} giờ`);
    }
    if (durationHours > maxBookingHours) {
      throw new BadRequestException(`Thời lượng đặt tối đa là ${maxBookingHours} giờ`);
    }

    const hourlyRate = partnerProfile.hourlyRate;
    const subtotal = new Decimal(hourlyRate.toString()).mul(durationHours);
    const serviceFee = subtotal.mul(serviceFeePercent).div(100);
    const totalAmount = subtotal.add(serviceFee);

    const initialStatus = autoConfirmBooking ? BookingStatus.CONFIRMED : BookingStatus.PENDING;

    const booking = await this.prisma.booking.create({
      data: {
        bookingCode: this.generateBookingCode(),
        userId,
        partnerId: dto.partnerId,
        serviceType: dto.serviceType,
        date,
        startTime,
        endTime,
        durationHours,
        meetingLocation: dto.meetingLocation,
        meetingLat: dto.meetingLat,
        meetingLng: dto.meetingLng,
        hourlyRate,
        totalHours: durationHours,
        subtotal,
        serviceFee,
        totalAmount,
        userNote: dto.userNote,
        status: initialStatus,
      },
      include: {
        user: {
          include: { profile: true },
          omit: { passwordHash: true },
        },
        partner: {
          include: { profile: true, partnerProfile: true },
          omit: { passwordHash: true },
        },
      },
    });

    this.logger.log(`Booking created: ${booking.bookingCode}`);

    await this.notificationsService
      .notifyAdminsIfEnabled('new_booking_alert', 'Đặt chỗ mới', `Mã đặt chỗ ${booking.bookingCode} vừa được tạo.`, { bookingId: booking.id, bookingCode: booking.bookingCode })
      .catch((err) => this.logger.warn(`Failed to notify admins: ${err?.message}`));

    // Send notification to partner (fire-and-forget - avoid blocking response on Redis/FCM)
    const userName = booking.user.profile?.displayName || booking.user.email;
    void this.notificationsService
      .sendNotification({
        userId: dto.partnerId,
        type: NotificationType.BOOKING,
        title: 'Yêu cầu đặt lịch mới',
        body: `${userName} muốn đặt lịch với bạn`,
        actionType: 'booking',
        actionId: booking.id,
        data: {
          bookingCode: booking.bookingCode,
          date: booking.date.toISOString(),
          startTime: dto.startTime,
          endTime: dto.endTime,
        },
      })
      .catch((err) => this.logger.warn(`Failed to send booking notification: ${err?.message}`));

    return withCombinedDateTime(booking);
  }

  /**
   * Get bookings for user (as customer)
   */
  async getUserBookings(userId: string, query: BookingQueryDto) {
    const { page = 1, limit = 10, status, startDate, endDate } = query;
    const skip = (page - 1) * limit;

    const where: any = { userId };

    if (status && status.length > 0) {
      where.status = status.length === 1 ? status[0] : { in: status };
    }

    if (startDate) {
      where.date = { gte: new Date(startDate) };
    }

    if (endDate) {
      where.date = { ...where.date, lte: new Date(endDate) };
    }

    const [bookings, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          partner: {
            include: { profile: true, partnerProfile: true },
            omit: { passwordHash: true },
          },
        },
      }),
      this.prisma.booking.count({ where }),
    ]);

    const totalPages = Math.ceil(total / limit);

    return {
      data: bookings.map(withCombinedDateTime),
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
   * Get bookings for partner (received bookings)
   */
  async getPartnerBookings(partnerId: string, query: BookingQueryDto) {
    const { page = 1, limit = 10, status, startDate, endDate } = query;
    const skip = (page - 1) * limit;

    const where: any = { partnerId };

    if (status && status.length > 0) {
      where.status = status.length === 1 ? status[0] : { in: status };
    }

    if (startDate) {
      where.date = { gte: new Date(startDate) };
    }

    if (endDate) {
      where.date = { ...where.date, lte: new Date(endDate) };
    }

    const [bookings, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          user: {
            include: { profile: true },
            omit: { passwordHash: true },
          },
        },
      }),
      this.prisma.booking.count({ where }),
    ]);

    const totalPages = Math.ceil(total / limit);

    return {
      data: bookings.map(withCombinedDateTime),
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
   * Get booking by ID
   */
  async getBookingById(bookingId: string, userId: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        user: {
          include: { profile: true },
          omit: { passwordHash: true },
        },
        partner: {
          include: { profile: true, partnerProfile: true },
          omit: { passwordHash: true },
        },
        reviews: true,
      },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    // Check access permission
    if (booking.userId !== userId && booking.partnerId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    return withCombinedDateTime(booking);
  }

  /**
   * Partner confirms booking
   */
  async confirmBooking(bookingId: string, partnerId: string, note?: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.partnerId !== partnerId) {
      throw new ForbiddenException('Access denied');
    }

    if (booking.status !== BookingStatus.PENDING) {
      throw new BadRequestException('Booking cannot be confirmed');
    }

    const updatedBooking = await this.prisma.booking.update({
      where: { id: bookingId },
      data: {
        status: BookingStatus.CONFIRMED,
        partnerNote: note,
        confirmedAt: new Date(),
      },
    });

    this.logger.log(`Booking confirmed: ${booking.bookingCode}`);

    // Send notification to user
    const partner = await this.prisma.user.findUnique({
      where: { id: partnerId },
      include: { profile: true },
    });
    const partnerName = partner?.profile?.displayName || 'Partner';
    
    await this.notificationsService.sendNotification({
      userId: booking.userId,
      type: NotificationType.BOOKING,
      title: 'Lịch hẹn đã được xác nhận',
      body: `${partnerName} đã xác nhận lịch hẹn của bạn`,
      actionType: 'booking',
      actionId: bookingId,
      data: {
        bookingCode: booking.bookingCode,
      },
    });

    return withCombinedDateTime(updatedBooking);
  }

  /**
   * Pay for a confirmed booking — deducts from wallet and creates escrow
   */
  async payBooking(bookingId: string, userId: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.userId !== userId) {
      throw new ForbiddenException('Only the customer can pay for the booking');
    }

    if (booking.status !== BookingStatus.CONFIRMED) {
      throw new BadRequestException('Booking must be confirmed before payment');
    }

    const totalAmount = Number(booking.totalAmount);
    const serviceFee = Number(booking.serviceFee);
    const subtotal = Number(booking.subtotal);

    // Deduct from wallet and create escrow holding
    await this.walletService.deductPaymentAndCreateEscrow(
      userId,
      booking.partnerId,
      subtotal,
      serviceFee,
      bookingId,
    );

    const updatedBooking = await this.prisma.booking.update({
      where: { id: bookingId },
      data: {
        status: BookingStatus.PAID,
        paidAt: new Date(),
      },
      include: {
        user: {
          include: { profile: true },
          omit: { passwordHash: true },
        },
        partner: {
          include: { profile: true, partnerProfile: true },
          omit: { passwordHash: true },
        },
      },
    });

    this.logger.log(`Booking paid: ${booking.bookingCode}, amount: ${totalAmount}`);

    // Send notification to partner
    const userName = updatedBooking.user.profile?.displayName || 'Khách hàng';
    void this.notificationsService
      .sendNotification({
        userId: booking.partnerId,
        type: NotificationType.BOOKING,
        title: 'Booking đã được thanh toán',
        body: `${userName} đã thanh toán cho lịch hẹn ${booking.bookingCode}`,
        actionType: 'booking',
        actionId: bookingId,
        data: { bookingCode: booking.bookingCode },
      })
      .catch((err) => this.logger.warn(`Failed to send pay notification: ${err?.message}`));

    return withCombinedDateTime(updatedBooking);
  }

  /**
   * Cancel booking
   */
  async cancelBooking(bookingId: string, userId: string, dto: CancelBookingDto) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    // Check permission
    if (booking.userId !== userId && booking.partnerId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    // Check if can be cancelled
    const cancellableStatuses: BookingStatus[] = [
      BookingStatus.PENDING,
      BookingStatus.CONFIRMED,
      BookingStatus.PAID,
    ];

    if (!cancellableStatuses.includes(booking.status as BookingStatus)) {
      throw new BadRequestException('Booking cannot be cancelled');
    }

    const cancellationHours = await this.settingsService.getNumber('cancellation_hours', 24);
    const bookingStart = combineDateAndTime(booking.date, booking.startTime);
    const hoursUntilStart = (bookingStart.getTime() - Date.now()) / (1000 * 60 * 60);
    if (hoursUntilStart < cancellationHours) {
      throw new BadRequestException(
        `Chỉ có thể hủy miễn phí trước ${cancellationHours} giờ so với giờ bắt đầu. Còn ${Math.max(0, Math.ceil(hoursUntilStart))} giờ.`,
      );
    }

    const updatedBooking = await this.prisma.$transaction(async (tx) => {
      // Update booking status
      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: {
          status: BookingStatus.CANCELLED,
          cancellationReason: dto.reason,
          cancelledBy: userId,
          cancelledAt: new Date(),
        },
      });

      return updated;
    });

    // Refund escrow if already paid (outside prisma tx — walletService has its own)
    if (booking.status === BookingStatus.PAID) {
      try {
        await this.walletService.refundEscrow(bookingId);
        this.logger.log(`Escrow refunded for cancelled booking ${booking.bookingCode}`);
      } catch (err) {
        this.logger.error(`Failed to refund escrow for ${booking.bookingCode}: ${err?.message}`);
      }
    }

    this.logger.log(`Booking cancelled: ${booking.bookingCode} by ${userId}`);

    // Send notification to the other party (fire-and-forget - avoid blocking response)
    const recipientId = userId === booking.userId ? booking.partnerId : booking.userId;
    this.prisma.user
      .findUnique({
        where: { id: userId },
        include: { profile: true },
      })
      .then((canceller) => {
        const cancellerName = canceller?.profile?.displayName || 'Người dùng';
        return this.notificationsService.sendNotification({
          userId: recipientId,
          type: NotificationType.BOOKING,
          title: 'Lịch hẹn đã bị hủy',
          body: `${cancellerName} đã hủy lịch hẹn. Lý do: ${dto.reason || 'Không có lý do'}`,
          actionType: 'booking',
          actionId: bookingId,
          data: {
            bookingCode: booking.bookingCode,
            reason: dto.reason,
          },
        });
      })
      .catch((err) => this.logger.warn(`Failed to send cancel notification: ${err?.message}`));

    return withCombinedDateTime(updatedBooking);
  }

  /**
   * Start booking (when meeting begins)
   */
  async startBooking(bookingId: string, userId: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.userId !== userId && booking.partnerId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    if (booking.status !== BookingStatus.PAID) {
      throw new BadRequestException('Booking must be paid first');
    }

    const updatedBooking = await this.prisma.booking.update({
      where: { id: bookingId },
      data: {
        status: BookingStatus.IN_PROGRESS,
        startedAt: new Date(),
      },
    });

    this.logger.log(`Booking started: ${booking.bookingCode}`);

    return withCombinedDateTime(updatedBooking);
  }

  /**
   * Complete booking
   */
  async completeBooking(bookingId: string, userId: string, note?: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    // Only user can complete the booking
    if (booking.userId !== userId) {
      throw new ForbiddenException('Only the customer can complete the booking');
    }

    if (booking.status !== BookingStatus.IN_PROGRESS) {
      throw new BadRequestException('Booking is not in progress');
    }

    const updatedBooking = await this.prisma.$transaction(async (tx) => {
      // Complete booking
      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: {
          status: BookingStatus.COMPLETED,
          completedAt: new Date(),
          userNote: note ? `${booking.userNote || ''}\n${note}` : booking.userNote,
        },
      });

      // Update partner stats
      await tx.partnerProfile.update({
        where: { userId: booking.partnerId },
        data: {
          completedBookings: { increment: 1 },
        },
      }).catch(() => { /* partner profile may not have completedBookings field */ });

      return updated;
    });

    // Release escrow to partner (outside prisma tx — walletService has its own)
    try {
      await this.walletService.releaseEscrow(bookingId);
      this.logger.log(`Escrow released for completed booking ${booking.bookingCode}`);
    } catch (err) {
      this.logger.error(`Failed to release escrow for ${booking.bookingCode}: ${err?.message}`);
    }

    this.logger.log(`Booking completed: ${booking.bookingCode}`);

    // Send notification to partner
    void this.notificationsService
      .sendNotification({
        userId: booking.partnerId,
        type: NotificationType.BOOKING,
        title: 'Booking đã hoàn thành',
        body: `Booking ${booking.bookingCode} đã được hoàn thành. Tiền đã được chuyển vào ví của bạn.`,
        actionType: 'booking',
        actionId: bookingId,
        data: { bookingCode: booking.bookingCode },
      })
      .catch((err) => this.logger.warn(`Failed to send complete notification: ${err?.message}`));

    return withCombinedDateTime(updatedBooking);
  }

  /**
   * Get booking statistics for user
   */
  async getUserBookingStats(userId: string) {
    const [total, completed, cancelled, pending] = await Promise.all([
      this.prisma.booking.count({ where: { userId } }),
      this.prisma.booking.count({ where: { userId, status: BookingStatus.COMPLETED } }),
      this.prisma.booking.count({ where: { userId, status: BookingStatus.CANCELLED } }),
      this.prisma.booking.count({
        where: {
          userId,
          status: { in: [BookingStatus.PENDING, BookingStatus.CONFIRMED, BookingStatus.PAID] },
        },
      }),
    ]);

    const totalSpent = await this.prisma.booking.aggregate({
      where: { userId, status: BookingStatus.COMPLETED },
      _sum: { totalAmount: true },
    });

    const totalSpentNum = totalSpent._sum.totalAmount
      ? Number(totalSpent._sum.totalAmount)
      : 0;

    return {
      totalBookings: total,
      completedBookings: completed,
      cancelledBookings: cancelled,
      upcomingBookings: pending,
      totalSpent: totalSpentNum,
    };
  }

  /**
   * Get booking statistics for partner
   */
  async getPartnerBookingStats(partnerId: string) {
    const [total, completed, cancelled, pending] = await Promise.all([
      this.prisma.booking.count({ where: { partnerId } }),
      this.prisma.booking.count({ where: { partnerId, status: BookingStatus.COMPLETED } }),
      this.prisma.booking.count({ where: { partnerId, status: BookingStatus.CANCELLED } }),
      this.prisma.booking.count({
        where: {
          partnerId,
          status: { in: [BookingStatus.PENDING, BookingStatus.CONFIRMED, BookingStatus.PAID] },
        },
      }),
    ]);

    const totalEarned = await this.prisma.booking.aggregate({
      where: { partnerId, status: BookingStatus.COMPLETED },
      _sum: { subtotal: true },
    });

    return {
      total,
      completed,
      cancelled,
      pending,
      totalEarned: totalEarned._sum.subtotal || 0,
    };
  }

  // ==================== ADMIN METHODS ====================

  /**
   * Admin: Get all bookings with filters
   */
  async adminGetAllBookings(query: AdminBookingQueryDto) {
    const {
      page = 1,
      limit = 10,
      status,
      startDate,
      endDate,
      search,
      userId,
      partnerId,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = query;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (status && status.length > 0) {
      where.status = status.length === 1 ? status[0] : { in: status };
    }

    if (userId) {
      where.userId = userId;
    }

    if (partnerId) {
      where.partnerId = partnerId;
    }

    if (startDate) {
      where.date = { gte: new Date(startDate) };
    }

    if (endDate) {
      where.date = { ...where.date, lte: new Date(endDate) };
    }

    if (search) {
      where.OR = [
        { bookingCode: { contains: search, mode: 'insensitive' } },
        { user: { profile: { fullName: { contains: search, mode: 'insensitive' } } } },
        { partner: { profile: { fullName: { contains: search, mode: 'insensitive' } } } },
      ];
    }

    const [bookings, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        skip,
        take: limit,
        orderBy: { [sortBy]: sortOrder },
        include: {
          user: {
            include: { profile: true },
            omit: { passwordHash: true },
          },
          partner: {
            include: { profile: true, partnerProfile: true },
            omit: { passwordHash: true },
          },
        },
      }),
      this.prisma.booking.count({ where }),
    ]);

    const totalPages = Math.ceil(total / limit);

    return {
      data: bookings.map(withCombinedDateTime),
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
   * Admin: Get booking statistics
   */
  async adminGetBookingStats() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const firstDayOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    const lastDayOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0);

    const [
      total,
      pending,
      confirmed,
      paid,
      inProgress,
      completed,
      cancelled,
      disputed,
      todayCount,
      monthlyRevenue,
    ] = await Promise.all([
      this.prisma.booking.count(),
      this.prisma.booking.count({ where: { status: BookingStatus.PENDING } }),
      this.prisma.booking.count({ where: { status: BookingStatus.CONFIRMED } }),
      this.prisma.booking.count({ where: { status: BookingStatus.PAID } }),
      this.prisma.booking.count({ where: { status: BookingStatus.IN_PROGRESS } }),
      this.prisma.booking.count({ where: { status: BookingStatus.COMPLETED } }),
      this.prisma.booking.count({ where: { status: BookingStatus.CANCELLED } }),
      this.prisma.booking.count({ where: { status: BookingStatus.DISPUTED } }),
      this.prisma.booking.count({
        where: {
          createdAt: { gte: today, lt: tomorrow },
        },
      }),
      this.prisma.booking.aggregate({
        where: {
          status: BookingStatus.COMPLETED,
          completedAt: { gte: firstDayOfMonth, lte: lastDayOfMonth },
        },
        _sum: { serviceFee: true },
      }),
    ]);

    return {
      total,
      pending,
      confirmed,
      paid,
      inProgress,
      completed,
      cancelled,
      disputed,
      todayCount,
      monthlyRevenue: monthlyRevenue._sum.serviceFee || 0,
    };
  }

  /**
   * Admin: Update booking status
   */
  async adminUpdateBookingStatus(bookingId: string, dto: UpdateBookingStatusDto) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    const updateData: any = {
      status: dto.status,
    };

    // Add timestamps based on status
    switch (dto.status) {
      case BookingStatus.CONFIRMED:
        updateData.confirmedAt = new Date();
        break;
      case BookingStatus.IN_PROGRESS:
        updateData.startedAt = new Date();
        break;
      case BookingStatus.COMPLETED:
        updateData.completedAt = new Date();
        break;
      case BookingStatus.CANCELLED:
        updateData.cancelledAt = new Date();
        updateData.cancellationReason = dto.reason || 'Admin cancelled';
        break;
    }

    const updatedBooking = await this.prisma.booking.update({
      where: { id: bookingId },
      data: updateData,
      include: {
        user: {
          include: { profile: true },
          omit: { passwordHash: true },
        },
        partner: {
          include: { profile: true, partnerProfile: true },
          omit: { passwordHash: true },
        },
      },
    });

    this.logger.log(`Admin updated booking ${booking.bookingCode} status to ${dto.status}`);

    return withCombinedDateTime(updatedBooking);
  }
}
