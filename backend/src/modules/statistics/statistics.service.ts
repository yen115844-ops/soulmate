import { Injectable } from '@nestjs/common';
import { BookingStatus, KycStatus, UserStatus } from '@prisma/client';
import { PrismaService } from '../../database/prisma/prisma.service';
import { QueryStatsDto } from './dto';

type DateRange = { from: Date; to: Date };

function parseRange(from?: string, to?: string): DateRange | null {
  if (!from || !to) return null;
  const fromDate = new Date(from);
  const toDate = new Date(to);
  toDate.setHours(23, 59, 59, 999);
  return { from: fromDate, to: toDate };
}

function getDefaultRange(): DateRange {
  const to = new Date();
  const from = new Date(to);
  from.setMonth(from.getMonth() - 1);
  from.setHours(0, 0, 0, 0);
  to.setHours(23, 59, 59, 999);
  return { from, to };
}

function groupByDay(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function groupByWeek(date: Date): string {
  const d = new Date(date);
  const day = d.getDay();
  const diff = d.getDate() - day + (day === 0 ? -6 : 1);
  d.setDate(diff);
  return d.toISOString().slice(0, 10);
}

function groupByMonth(date: Date): string {
  return date.toISOString().slice(0, 7);
}

@Injectable()
export class StatisticsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Full dashboard report: overview + charts (revenue, bookings, growth) + breakdowns
   */
  async getFullReport(dto: QueryStatsDto) {
    const range = parseRange(dto.from, dto.to) || getDefaultRange();
    const groupBy = dto.groupBy || 'day';
    const fromStr = dto.from ?? range.from.toISOString().slice(0, 10);
    const toStr = dto.to ?? range.to.toISOString().slice(0, 10);

    const [
      overview,
      revenueChart,
      bookingsByStatus,
      bookingsByServiceType,
      userGrowth,
      partnerGrowth,
      kycBreakdown,
      topPartnersByRevenue,
    ] = await Promise.all([
      this.getOverview(fromStr, toStr),
      this.getRevenueChart(range.from, range.to, groupBy),
      this.getBookingsByStatus(range.from, range.to),
      this.getBookingsByServiceType(range.from, range.to),
      this.getUserGrowth(range.from, range.to, groupBy),
      this.getPartnerGrowth(range.from, range.to, groupBy),
      this.getKycBreakdown(),
      this.getTopPartnersByRevenue(10, range.from, range.to),
    ]);

    return {
      overview,
      revenueChart,
      bookingsByStatus,
      bookingsByServiceType,
      userGrowth,
      partnerGrowth,
      kycBreakdown,
      topPartnersByRevenue,
      dateRange: { from: range.from.toISOString(), to: range.to.toISOString() },
    };
  }

  /**
   * Overview counts (optional period filter)
   */
  async getOverview(from?: string, to?: string) {
    const range = parseRange(from, to);
    const userWhere = range ? { createdAt: { gte: range.from, lte: range.to } } : {};
    const userDateFilter = range ? { createdAt: { gte: range.from, lte: range.to } } : {};
    const bookingWhere = range
      ? { createdAt: { gte: range.from, lte: range.to } }
      : {};
    const bookingCompletedWhere = range
      ? { completedAt: { gte: range.from, lte: range.to } as any }
      : {};

    const [
      totalUsers,
      activeUsers,
      pendingUsers,
      suspendedUsers,
      bannedUsers,
      totalPartners,
      activePartners,
      availablePartners,
      totalBookings,
      completedBookings,
      cancelledBookings,
      totalRevenue,
      kycPending,
      kycVerified,
      kycRejected,
    ] = await Promise.all([
      this.prisma.user.count(range ? { where: userWhere } : { where: {} }),
      this.prisma.user.count({ where: { status: UserStatus.ACTIVE, ...userWhere } }),
      this.prisma.user.count({ where: { status: UserStatus.PENDING, ...userWhere } }),
      this.prisma.user.count({ where: { status: UserStatus.SUSPENDED, ...userWhere } }),
      this.prisma.user.count({ where: { status: UserStatus.BANNED, ...userWhere } }),
      this.prisma.partnerProfile.count(
        range ? { where: { user: userDateFilter } } : ({ where: {} } as Parameters<typeof this.prisma.partnerProfile.count>[0]),
      ),
      this.prisma.partnerProfile.count({
        where: {
          user: {
            status: UserStatus.ACTIVE,
            ...userDateFilter,
          },
        },
      }),
      this.prisma.partnerProfile.count({
        where: range
          ? { isAvailable: true, user: userDateFilter }
          : { isAvailable: true },
      }),
      this.prisma.booking.count(range ? { where: bookingWhere } : { where: {} }),
      this.prisma.booking.count({
        where: { status: BookingStatus.COMPLETED, ...bookingWhere },
      }),
      this.prisma.booking.count({
        where: { status: BookingStatus.CANCELLED, ...bookingWhere },
      }),
      this.prisma.booking.aggregate({
        where: {
          status: BookingStatus.COMPLETED,
          ...bookingCompletedWhere,
        },
        _sum: { serviceFee: true },
      }),
      this.prisma.kycVerification.count({ where: { status: KycStatus.PENDING } }),
      this.prisma.kycVerification.count({ where: { status: KycStatus.VERIFIED } }),
      this.prisma.kycVerification.count({ where: { status: KycStatus.REJECTED } }),
    ]);

    const avgRating = await this.prisma.partnerProfile.aggregate({
      _avg: { averageRating: true },
    });

    return {
      users: {
        total: totalUsers,
        active: activeUsers,
        pending: pendingUsers,
        suspended: suspendedUsers,
        banned: bannedUsers,
      },
      partners: {
        total: totalPartners,
        active: activePartners,
        available: availablePartners,
        averageRating: Number(avgRating._avg.averageRating ?? 0),
      },
      bookings: {
        total: totalBookings,
        completed: completedBookings,
        cancelled: cancelledBookings,
        totalRevenue: Number(totalRevenue._sum.serviceFee ?? 0),
      },
      kyc: {
        pending: kycPending,
        verified: kycVerified,
        rejected: kycRejected,
      },
    };
  }

  /**
   * Revenue over time (completed bookings, service fee sum)
   */
  async getRevenueChart(from: Date, to: Date, groupBy: 'day' | 'week' | 'month') {
    // Use Prisma $queryRaw with SQL GROUP BY for efficient aggregation
    let dateFormat: string;
    if (groupBy === 'month') {
      dateFormat = 'YYYY-MM';
    } else if (groupBy === 'week') {
      dateFormat = 'IYYY-IW'; // ISO week
    } else {
      dateFormat = 'YYYY-MM-DD';
    }

    const results = await this.prisma.$queryRawUnsafe<
      Array<{ date: string; revenue: number; count: bigint }>
    >(
      `SELECT TO_CHAR(completed_at, $1) as date, 
              COALESCE(SUM(service_fee), 0)::float as revenue, 
              COUNT(*)::bigint as count
       FROM bookings 
       WHERE status = 'COMPLETED' 
         AND completed_at >= $2 
         AND completed_at <= $3
       GROUP BY TO_CHAR(completed_at, $1)
       ORDER BY date ASC`,
      dateFormat,
      from,
      to,
    );

    return results.map((r) => ({
      date: r.date,
      revenue: Number(r.revenue),
      count: Number(r.count),
    }));
  }

  /**
   * Booking counts by status in period
   */
  async getBookingsByStatus(from: Date, to: Date) {
    const statuses = Object.values(BookingStatus);
    const counts = await Promise.all(
      statuses.map((status) =>
        this.prisma.booking.count({
          where: {
            status,
            createdAt: { gte: from, lte: to },
          },
        }),
      ),
    );
    return statuses.map((status, i) => ({ status, count: counts[i] }));
  }

  /**
   * Booking counts by service type in period
   */
  async getBookingsByServiceType(from: Date, to: Date) {
    const list = await this.prisma.booking.groupBy({
      by: ['serviceType'],
      where: { createdAt: { gte: from, lte: to } },
      _count: { id: true },
      _sum: { totalAmount: true },
    });
    return list.map((x) => ({
      serviceType: x.serviceType,
      count: x._count.id,
      totalAmount: Number(x._sum.totalAmount ?? 0),
    }));
  }

  /**
   * New users over time
   */
  async getUserGrowth(from: Date, to: Date, groupBy: 'day' | 'week' | 'month') {
    const groupFn = groupBy === 'month' ? groupByMonth : groupBy === 'week' ? groupByWeek : groupByDay;

    const users = await this.prisma.user.findMany({
      where: { createdAt: { gte: from, lte: to } },
      select: { createdAt: true },
    });

    const map = new Map<string, number>();
    for (const u of users) {
      const key = groupFn(new Date(u.createdAt));
      map.set(key, (map.get(key) ?? 0) + 1);
    }
    return Array.from(map.entries())
      .map(([date, count]) => ({ date, count }))
      .sort((a, b) => a.date.localeCompare(b.date));
  }

  /**
   * New partners over time
   */
  async getPartnerGrowth(from: Date, to: Date, groupBy: 'day' | 'week' | 'month') {
    const groupFn = groupBy === 'month' ? groupByMonth : groupBy === 'week' ? groupByWeek : groupByDay;

    const partners = await this.prisma.partnerProfile.findMany({
      where: { createdAt: { gte: from, lte: to } },
      select: { createdAt: true },
    });

    const map = new Map<string, number>();
    for (const p of partners) {
      const key = groupFn(new Date(p.createdAt));
      map.set(key, (map.get(key) ?? 0) + 1);
    }
    return Array.from(map.entries())
      .map(([date, count]) => ({ date, count }))
      .sort((a, b) => a.date.localeCompare(b.date));
  }

  /**
   * KYC counts by status (no date filter - current state)
   */
  async getKycBreakdown() {
    const [pending, verified, rejected, none] = await Promise.all([
      this.prisma.kycVerification.count({ where: { status: KycStatus.PENDING } }),
      this.prisma.kycVerification.count({ where: { status: KycStatus.VERIFIED } }),
      this.prisma.kycVerification.count({ where: { status: KycStatus.REJECTED } }),
      this.prisma.user.count({ where: { kycStatus: KycStatus.NONE } }),
    ]);
    return [
      { status: 'PENDING', count: pending, label: 'Chờ duyệt' },
      { status: 'VERIFIED', count: verified, label: 'Đã xác minh' },
      { status: 'REJECTED', count: rejected, label: 'Từ chối' },
      { status: 'NONE', count: none, label: 'Chưa nộp' },
    ];
  }

  /**
   * Top partners by revenue (completed bookings) in period
   */
  async getTopPartnersByRevenue(limit: number, from: Date, to: Date) {
    const completed = await this.prisma.booking.findMany({
      where: {
        status: BookingStatus.COMPLETED,
        completedAt: { gte: from, lte: to },
      },
      select: {
        partnerId: true,
        totalAmount: true,
        serviceFee: true,
        partner: {
          select: {
            profile: { select: { fullName: true, avatarUrl: true } },
            email: true,
          },
        },
      },
    });

    const byPartner = new Map<
      string,
      { revenue: number; fee: number; count: number; partner: (typeof completed)[0]['partner'] }
    >();
    for (const b of completed) {
      const cur = byPartner.get(b.partnerId) ?? {
        revenue: 0,
        fee: 0,
        count: 0,
        partner: b.partner,
      };
      cur.revenue += Number(b.totalAmount);
      cur.fee += Number(b.serviceFee);
      cur.count += 1;
      byPartner.set(b.partnerId, cur);
    }

    return Array.from(byPartner.entries())
      .map(([partnerId, v]) => ({
        partnerId,
        fullName: v.partner?.profile?.fullName ?? '—',
        avatarUrl: v.partner?.profile?.avatarUrl ?? null,
        totalRevenue: v.revenue,
        platformFee: v.fee,
        bookingCount: v.count,
      }))
      .sort((a, b) => b.totalRevenue - a.totalRevenue)
      .slice(0, limit);
  }
}
