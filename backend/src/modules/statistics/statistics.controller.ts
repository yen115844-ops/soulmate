import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { QueryStatsDto } from './dto';
import { StatisticsService } from './statistics.service';

@ApiTags('Admin Statistics')
@Controller('admin/statistics')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
@ApiBearerAuth('JWT-auth')
export class StatisticsController {
  constructor(private readonly statisticsService: StatisticsService) {}

  @Get('report')
  @ApiOperation({ summary: 'Full statistics report (overview + charts + breakdowns)' })
  @ApiResponse({ status: 200, description: 'Report with date range' })
  async getFullReport(@Query() dto: QueryStatsDto) {
    return this.statisticsService.getFullReport(dto);
  }

  @Get('overview')
  @ApiOperation({ summary: 'Overview counts (users, partners, bookings, KYC)' })
  @ApiResponse({ status: 200, description: 'Overview stats' })
  async getOverview(@Query('from') from?: string, @Query('to') to?: string) {
    return this.statisticsService.getOverview(from, to);
  }

  @Get('revenue-chart')
  @ApiOperation({ summary: 'Revenue over time (completed bookings, service fee)' })
  @ApiResponse({ status: 200, description: 'Array of { date, revenue, count }' })
  async getRevenueChart(@Query() dto: QueryStatsDto) {
    const range = dto.from && dto.to
      ? { from: new Date(dto.from), to: new Date(dto.to) }
      : (() => {
          const to = new Date();
          const from = new Date(to);
          from.setMonth(from.getMonth() - 1);
          return { from, to };
        })();
    return this.statisticsService.getRevenueChart(
      range.from,
      range.to,
      dto.groupBy || 'day',
    );
  }

  @Get('bookings-by-status')
  @ApiOperation({ summary: 'Booking counts by status in period' })
  @ApiResponse({ status: 200, description: 'Array of { status, count }' })
  async getBookingsByStatus(@Query() dto: QueryStatsDto) {
    const range = dto.from && dto.to
      ? { from: new Date(dto.from), to: new Date(dto.to) }
      : (() => {
          const to = new Date();
          const from = new Date(to);
          from.setMonth(from.getMonth() - 1);
          return { from, to };
        })();
    return this.statisticsService.getBookingsByStatus(
      range.from,
      range.to,
    );
  }

  @Get('bookings-by-service-type')
  @ApiOperation({ summary: 'Booking counts by service type in period' })
  @ApiResponse({ status: 200, description: 'Array of { serviceType, count, totalAmount }' })
  async getBookingsByServiceType(@Query() dto: QueryStatsDto) {
    const range = dto.from && dto.to
      ? { from: new Date(dto.from), to: new Date(dto.to) }
      : (() => {
          const to = new Date();
          const from = new Date(to);
          from.setMonth(from.getMonth() - 1);
          return { from, to };
        })();
    return this.statisticsService.getBookingsByServiceType(
      range.from,
      range.to,
    );
  }

  @Get('user-growth')
  @ApiOperation({ summary: 'New users over time' })
  @ApiResponse({ status: 200, description: 'Array of { date, count }' })
  async getUserGrowth(@Query() dto: QueryStatsDto) {
    const range = dto.from && dto.to
      ? { from: new Date(dto.from), to: new Date(dto.to) }
      : (() => {
          const to = new Date();
          const from = new Date(to);
          from.setMonth(from.getMonth() - 1);
          return { from, to };
        })();
    return this.statisticsService.getUserGrowth(
      range.from,
      range.to,
      dto.groupBy || 'day',
    );
  }

  @Get('partner-growth')
  @ApiOperation({ summary: 'New partners over time' })
  @ApiResponse({ status: 200, description: 'Array of { date, count }' })
  async getPartnerGrowth(@Query() dto: QueryStatsDto) {
    const range = dto.from && dto.to
      ? { from: new Date(dto.from), to: new Date(dto.to) }
      : (() => {
          const to = new Date();
          const from = new Date(to);
          from.setMonth(from.getMonth() - 1);
          return { from, to };
        })();
    return this.statisticsService.getPartnerGrowth(
      range.from,
      range.to,
      dto.groupBy || 'day',
    );
  }

  @Get('kyc-breakdown')
  @ApiOperation({ summary: 'KYC counts by status' })
  @ApiResponse({ status: 200, description: 'Array of { status, count, label }' })
  async getKycBreakdown() {
    return this.statisticsService.getKycBreakdown();
  }

  @Get('top-partners-revenue')
  @ApiOperation({ summary: 'Top partners by revenue in period' })
  @ApiResponse({ status: 200, description: 'Array of partner revenue summary' })
  async getTopPartnersByRevenue(@Query() dto: QueryStatsDto) {
    const range = dto.from && dto.to
      ? { from: new Date(dto.from), to: new Date(dto.to) }
      : (() => {
          const to = new Date();
          const from = new Date(to);
          from.setMonth(from.getMonth() - 1);
          return { from, to };
        })();
    return this.statisticsService.getTopPartnersByRevenue(
      10,
      range.from,
      range.to,
    );
  }
}
