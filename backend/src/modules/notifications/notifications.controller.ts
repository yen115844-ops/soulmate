import {
    Body,
    Controller,
    Delete,
    Get,
    Param,
    Post,
    Query,
    Request,
    UseGuards,
} from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AdminQueryNotificationsDto, AdminSendNotificationDto } from './dto/admin-notification.dto';
import { MarkReadDto } from './dto/mark-read.dto';
import { QueryNotificationsDto } from './dto/query-notifications.dto';
import { RegisterDeviceDto, UnregisterDeviceDto } from './dto/register-device.dto';
import { NotificationsService } from './notifications.service';
import { DeviceTokenService } from './services/device-token.service';

@ApiTags('Notifications')
@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(
    private readonly notificationsService: NotificationsService,
    private readonly deviceTokenService: DeviceTokenService,
  ) {}

  // ==================== ADMIN ENDPOINTS ====================

  @Get('admin/stats')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: Get notification statistics' })
  async adminGetStats() {
    return this.notificationsService.adminGetStats();
  }

  @Get('admin/list')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: Get all notifications with filters' })
  async adminGetNotifications(@Query() query: AdminQueryNotificationsDto) {
    return this.notificationsService.adminGetNotifications(query);
  }

  @Post('admin/send')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: Send notification to specific users' })
  async adminSendNotification(@Body() dto: AdminSendNotificationDto) {
    return this.notificationsService.adminSendNotification(dto);
  }

  @Post('admin/broadcast')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: Send notification to all users' })
  async adminBroadcastNotification(@Body() dto: AdminSendNotificationDto) {
    return this.notificationsService.adminBroadcastNotification(dto);
  }

  @Delete('admin/:id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: Delete a notification' })
  async adminDeleteNotification(@Param('id') id: string) {
    return this.notificationsService.adminDeleteNotification(id);
  }

  // ==================== USER ENDPOINTS ====================

  @Get()
  @ApiOperation({ summary: 'Get notifications list with pagination' })
  async getNotifications(
    @Request() req,
    @Query() query: QueryNotificationsDto,
  ) {
    return this.notificationsService.getNotifications(req.user.id, query);
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Get unread notifications count' })
  async getUnreadCount(@Request() req) {
    return this.notificationsService.getUnreadCount(req.user.id);
  }

  @Post('mark-read/:id')
  @ApiOperation({ summary: 'Mark a notification as read' })
  async markAsRead(@Request() req, @Param('id') id: string) {
    return this.notificationsService.markAsRead(req.user.id, id);
  }

  @Post('mark-all-read')
  @ApiOperation({ summary: 'Mark all notifications as read' })
  async markAllAsRead(@Request() req, @Body() dto: MarkReadDto) {
    return this.notificationsService.markAllAsRead(req.user.id, dto.ids);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a notification' })
  async deleteNotification(@Request() req, @Param('id') id: string) {
    return this.notificationsService.deleteNotification(req.user.id, id);
  }

  @Delete('read/all')
  @ApiOperation({ summary: 'Delete all read notifications' })
  async deleteAllRead(@Request() req) {
    return this.notificationsService.deleteAllRead(req.user.id);
  }

  // ==================== Device Token APIs ====================

  @Post('device-token')
  @ApiOperation({ summary: 'Register FCM device token' })
  async registerDeviceToken(@Request() req, @Body() dto: RegisterDeviceDto) {
    return this.deviceTokenService.registerToken(req.user.id, dto);
  }

  @Delete('device-token')
  @ApiOperation({ summary: 'Unregister FCM device token' })
  async unregisterDeviceToken(
    @Request() req,
    @Body() dto: UnregisterDeviceDto,
  ) {
    return this.deviceTokenService.unregisterToken(req.user.id, dto.token);
  }

  @Delete('device-tokens/all')
  @ApiOperation({ summary: 'Unregister all device tokens (logout all devices)' })
  async unregisterAllDeviceTokens(@Request() req) {
    return this.deviceTokenService.unregisterAllTokens(req.user.id);
  }

  @Get('devices')
  @ApiOperation({ summary: 'Get user registered devices' })
  async getUserDevices(@Request() req) {
    return this.deviceTokenService.getUserTokens(req.user.id);
  }
}

