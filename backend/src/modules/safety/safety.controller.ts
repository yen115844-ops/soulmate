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
    UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import {
    CreateEmergencyContactDto,
    LogLocationDto,
    ResolveSosDto,
    TriggerSosDto,
    UpdateEmergencyContactDto,
} from './dto';
import { SafetyService } from './safety.service';

@ApiTags('Safety')
@Controller('safety')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class SafetyController {
  constructor(private readonly safetyService: SafetyService) {}

  // ==================== SOS ====================

  @Post('sos')
  @ApiOperation({ summary: 'Trigger SOS emergency event' })
  @ApiResponse({ status: 201, description: 'SOS triggered' })
  async triggerSos(
    @CurrentUser('id') userId: string,
    @Body() dto: TriggerSosDto,
  ) {
    return this.safetyService.triggerSos(userId, dto);
  }

  @Put('sos/:id/cancel')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Cancel own SOS event' })
  @ApiResponse({ status: 200, description: 'SOS cancelled' })
  async cancelSos(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.safetyService.cancelSos(id, userId);
  }

  @Get('sos/my-events')
  @ApiOperation({ summary: 'Get my SOS event history' })
  @ApiResponse({ status: 200, description: 'SOS events retrieved' })
  async getMySosEvents(@CurrentUser('id') userId: string) {
    return this.safetyService.getUserSosEvents(userId);
  }

  // Admin endpoints
  @Get('sos/active')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: Get active SOS events' })
  async getActiveSosEvents() {
    return this.safetyService.getActiveSosEvents();
  }

  @Put('sos/:id/resolve')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Admin: Resolve SOS event' })
  async resolveSos(
    @Param('id') id: string,
    @CurrentUser('id') responderId: string,
    @Body() dto: ResolveSosDto,
  ) {
    return this.safetyService.resolveSos(id, responderId, dto);
  }

  // ==================== EMERGENCY CONTACTS ====================

  @Get('emergency-contacts')
  @ApiOperation({ summary: 'Get my emergency contacts' })
  @ApiResponse({ status: 200, description: 'Contacts retrieved' })
  async getEmergencyContacts(@CurrentUser('id') userId: string) {
    return this.safetyService.getEmergencyContacts(userId);
  }

  @Post('emergency-contacts')
  @ApiOperation({ summary: 'Add emergency contact (max 5)' })
  @ApiResponse({ status: 201, description: 'Contact created' })
  async createEmergencyContact(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateEmergencyContactDto,
  ) {
    return this.safetyService.createEmergencyContact(userId, dto);
  }

  @Patch('emergency-contacts/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update emergency contact' })
  async updateEmergencyContact(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateEmergencyContactDto,
  ) {
    return this.safetyService.updateEmergencyContact(id, userId, dto);
  }

  @Delete('emergency-contacts/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete emergency contact' })
  async deleteEmergencyContact(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.safetyService.deleteEmergencyContact(id, userId);
  }

  // ==================== LOCATION LOGGING ====================

  @Post('location')
  @ApiOperation({ summary: 'Log location during active booking' })
  @ApiResponse({ status: 201, description: 'Location logged' })
  async logLocation(
    @CurrentUser('id') userId: string,
    @Body() dto: LogLocationDto,
  ) {
    return this.safetyService.logLocation(userId, dto);
  }

  @Get('location/:bookingId')
  @ApiOperation({ summary: 'Get location history for a booking' })
  @ApiResponse({ status: 200, description: 'Location history retrieved' })
  async getBookingLocationLogs(
    @Param('bookingId') bookingId: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.safetyService.getBookingLocationLogs(bookingId, userId);
  }
}
