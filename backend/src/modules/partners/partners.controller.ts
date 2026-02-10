import {
    Body,
    Controller,
    Delete,
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
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../../common/guards/optional-jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import {
    AdminPartnerQueryDto,
    CreateAvailabilitySlotDto,
    CreatePartnerProfileDto,
    SearchPartnersDto,
    UpdateAvailabilitySlotDto,
    UpdatePartnerProfileDto,
    UpdatePartnerStatusDto,
} from './dto';
import { PartnersService } from './partners.service';

@ApiTags('Partners')
@Controller('partners')
export class PartnersController {
  constructor(private readonly partnersService: PartnersService) {}

  // ==================== Admin Routes ====================

  @Get('admin/stats')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get partner stats for admin dashboard' })
  @ApiResponse({ status: 200, description: 'Partner stats retrieved' })
  async getPartnerStats() {
    return this.partnersService.adminGetPartnerStats();
  }

  @Get('admin/list')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all partners with pagination and filters' })
  @ApiResponse({ status: 200, description: 'Partners list retrieved' })
  async getAllPartners(@Query() dto: AdminPartnerQueryDto) {
    return this.partnersService.adminGetAllPartners(dto);
  }

  @Patch('admin/:id/status')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update partner status' })
  @ApiResponse({ status: 200, description: 'Partner status updated' })
  @ApiResponse({ status: 404, description: 'Partner not found' })
  async updatePartnerStatus(
    @Param('id') id: string,
    @Body() dto: UpdatePartnerStatusDto,
  ) {
    return this.partnersService.adminUpdatePartnerStatus(id, dto);
  }

  // ==================== Public Routes ====================

  @Get('search')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiOperation({ summary: 'Search partners with filters' })
  @ApiResponse({ status: 200, description: 'Partners list retrieved' })
  async searchPartners(
    @Query() dto: SearchPartnersDto,
    @CurrentUser('id') currentUserId?: string,
  ) {
    return this.partnersService.searchPartners(dto, currentUserId);
  }

  @Get(':id')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiOperation({ summary: 'Get partner public profile by ID' })
  @ApiResponse({ status: 200, description: 'Partner profile retrieved' })
  @ApiResponse({ status: 404, description: 'Partner not found' })
  @ApiResponse({ status: 403, description: 'User is blocked' })
  async getPartnerById(
    @Param('id') id: string,
    @CurrentUser('id') currentUserId?: string,
  ) {
    return this.partnersService.getPartnerById(id, currentUserId);
  }

  // ==================== Protected Routes ====================

  @Post('register')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Register as a partner' })
  @ApiResponse({ status: 201, description: 'Partner profile created' })
  @ApiResponse({ status: 409, description: 'Already a partner' })
  async registerAsPartner(
    @CurrentUser('id') userId: string,
    @Body() dto: CreatePartnerProfileDto,
  ) {
    return this.partnersService.registerAsPartner(userId, dto);
  }

  @Get('me/profile')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get my partner profile' })
  @ApiResponse({ status: 200, description: 'Partner profile retrieved' })
  async getMyPartnerProfile(@CurrentUser('id') userId: string) {
    return this.partnersService.getPartnerProfile(userId);
  }

  @Put('me/profile')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update my partner profile' })
  @ApiResponse({ status: 200, description: 'Partner profile updated' })
  async updateMyPartnerProfile(
    @CurrentUser('id') userId: string,
    @Body() dto: UpdatePartnerProfileDto,
  ) {
    return this.partnersService.updatePartnerProfile(userId, dto);
  }

  @Put('me/presence')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update presence (lastActiveAt) for online status' })
  @ApiResponse({ status: 200, description: 'Presence updated' })
  async updatePresence(@CurrentUser('id') userId: string) {
    return this.partnersService.updatePresence(userId);
  }

  // ==================== Availability Slots ====================

  @Get('me/slots')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get my availability slots' })
  @ApiQuery({ name: 'startDate', required: false, example: '2026-01-15' })
  @ApiQuery({ name: 'endDate', required: false, example: '2026-01-31' })
  @ApiResponse({ status: 200, description: 'Slots retrieved' })
  async getMySlots(
    @CurrentUser('id') userId: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.partnersService.getAvailabilitySlots(userId, startDate, endDate);
  }

  @Post('me/slots')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create availability slot' })
  @ApiResponse({ status: 201, description: 'Slot created' })
  @ApiResponse({ status: 409, description: 'Slot overlaps' })
  async createSlot(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateAvailabilitySlotDto,
  ) {
    return this.partnersService.createAvailabilitySlot(userId, dto);
  }

  @Put('me/slots/:slotId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update availability slot' })
  @ApiResponse({ status: 200, description: 'Slot updated' })
  async updateSlot(
    @CurrentUser('id') userId: string,
    @Param('slotId') slotId: string,
    @Body() dto: UpdateAvailabilitySlotDto,
  ) {
    return this.partnersService.updateAvailabilitySlot(userId, slotId, dto);
  }

  @Delete('me/slots/:slotId')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete availability slot' })
  @ApiResponse({ status: 200, description: 'Slot deleted' })
  async deleteSlot(
    @CurrentUser('id') userId: string,
    @Param('slotId') slotId: string,
  ) {
    return this.partnersService.deleteAvailabilitySlot(userId, slotId);
  }
}
