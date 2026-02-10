import {
    Body,
    Controller,
    Get,
    HttpCode,
    HttpStatus,
    Param,
    Patch,
    Post,
    Put,
    Query,
    UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { BookingsService } from './bookings.service';
import { AdminBookingQueryDto, BookingQueryDto, CancelBookingDto, CompleteBookingDto, CreateBookingDto, UpdateBookingStatusDto } from './dto';

@ApiTags('Bookings')
@Controller('bookings')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class BookingsController {
  constructor(private readonly bookingsService: BookingsService) {}

  // ==================== ADMIN ENDPOINTS ====================

  @Get('admin/list')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: Get all bookings with filters' })
  @ApiResponse({ status: 200, description: 'Bookings retrieved' })
  async adminGetBookings(@Query() query: AdminBookingQueryDto) {
    return this.bookingsService.adminGetAllBookings(query);
  }

  @Get('admin/stats')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: Get booking statistics' })
  @ApiResponse({ status: 200, description: 'Statistics retrieved' })
  async adminGetStats() {
    return this.bookingsService.adminGetBookingStats();
  }

  @Patch('admin/:id/status')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Admin: Update booking status' })
  @ApiResponse({ status: 200, description: 'Booking status updated' })
  async adminUpdateStatus(
    @Param('id') id: string,
    @Body() dto: UpdateBookingStatusDto,
  ) {
    return this.bookingsService.adminUpdateBookingStatus(id, dto);
  }

  // ==================== USER ENDPOINTS ====================

  @Post()
  @ApiOperation({ summary: 'Create a new booking' })
  @ApiResponse({ status: 201, description: 'Booking created' })
  async createBooking(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateBookingDto,
  ) {
    return this.bookingsService.createBooking(userId, dto);
  }

  @Get('my-bookings')
  @ApiOperation({ summary: 'Get my bookings as a customer' })
  @ApiResponse({ status: 200, description: 'Bookings retrieved' })
  async getMyBookings(
    @CurrentUser('id') userId: string,
    @Query() query: BookingQueryDto,
  ) {
    return this.bookingsService.getUserBookings(userId, query);
  }

  @Get('partner-bookings')
  @ApiOperation({ summary: 'Get bookings received as a partner' })
  @ApiResponse({ status: 200, description: 'Partner bookings retrieved' })
  async getPartnerBookings(
    @CurrentUser('id') partnerId: string,
    @Query() query: BookingQueryDto,
  ) {
    return this.bookingsService.getPartnerBookings(partnerId, query);
  }

  @Get('stats/user')
  @ApiOperation({ summary: 'Get my booking statistics as user' })
  @ApiResponse({ status: 200, description: 'Statistics retrieved' })
  async getUserStats(@CurrentUser('id') userId: string) {
    return this.bookingsService.getUserBookingStats(userId);
  }

  @Get('stats/partner')
  @ApiOperation({ summary: 'Get my booking statistics as partner' })
  @ApiResponse({ status: 200, description: 'Statistics retrieved' })
  async getPartnerStats(@CurrentUser('id') partnerId: string) {
    return this.bookingsService.getPartnerBookingStats(partnerId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get booking details' })
  @ApiResponse({ status: 200, description: 'Booking retrieved' })
  @ApiResponse({ status: 404, description: 'Booking not found' })
  async getBooking(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.bookingsService.getBookingById(id, userId);
  }

  @Put(':id/confirm')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Partner confirms booking' })
  @ApiResponse({ status: 200, description: 'Booking confirmed' })
  async confirmBooking(
    @Param('id') id: string,
    @CurrentUser('id') partnerId: string,
    @Body('note') note?: string,
  ) {
    return this.bookingsService.confirmBooking(id, partnerId, note);
  }

  @Put(':id/cancel')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Cancel booking' })
  @ApiResponse({ status: 200, description: 'Booking cancelled' })
  async cancelBooking(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Body() dto: CancelBookingDto,
  ) {
    return this.bookingsService.cancelBooking(id, userId, dto);
  }

  @Put(':id/start')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Start booking (begin meeting)' })
  @ApiResponse({ status: 200, description: 'Booking started' })
  async startBooking(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.bookingsService.startBooking(id, userId);
  }

  @Put(':id/complete')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Complete booking' })
  @ApiResponse({ status: 200, description: 'Booking completed' })
  async completeBooking(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Body() dto: CompleteBookingDto,
  ) {
    return this.bookingsService.completeBooking(id, userId, dto.note);
  }
}
