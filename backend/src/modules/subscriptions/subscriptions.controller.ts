import {
    Body,
    Controller,
    Get,
    Post,
    Query,
    UseGuards,
} from '@nestjs/common';
import {
    ApiBearerAuth,
    ApiOperation,
    ApiQuery,
    ApiResponse,
    ApiTags,
} from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { UserRole } from '../../generated/prisma/client';
import { RestorePurchasesDto, VerifyPurchaseDto } from './dto';
import { SubscriptionsService } from './subscriptions.service';

@ApiTags('Subscriptions')
@Controller('subscriptions')
export class SubscriptionsController {
  constructor(private readonly subscriptionsService: SubscriptionsService) {}

  // ==================== Public Routes ====================

  @Get('plans')
  @ApiOperation({ summary: 'Get all available subscription plans' })
  @ApiResponse({ status: 200, description: 'Plans returned' })
  async getPlans() {
    return this.subscriptionsService.getPlans();
  }

  // ==================== User Routes ====================

  @Get('status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current subscription status' })
  @ApiResponse({ status: 200, description: 'Subscription status returned' })
  async getStatus(@CurrentUser('id') userId: string) {
    return this.subscriptionsService.getStatus(userId);
  }

  @Post('verify-purchase')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Verify IAP purchase and activate subscription' })
  @ApiResponse({ status: 201, description: 'Purchase verified and subscription activated' })
  @ApiResponse({ status: 400, description: 'Invalid receipt' })
  async verifyPurchase(
    @CurrentUser('id') userId: string,
    @Body() dto: VerifyPurchaseDto,
  ) {
    return this.subscriptionsService.verifyPurchase(userId, dto);
  }

  @Post('restore')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Restore previous purchases' })
  @ApiResponse({ status: 200, description: 'Purchases restored' })
  async restorePurchases(
    @CurrentUser('id') userId: string,
    @Body() dto: RestorePurchasesDto,
  ) {
    return this.subscriptionsService.restorePurchases(userId, dto);
  }

  @Get('can-send-message')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Check if user can send message (free limit check)' })
  @ApiResponse({ status: 200, description: 'Limit status returned' })
  async canSendMessage(@CurrentUser('id') userId: string) {
    return this.subscriptionsService.canSendMessage(userId);
  }

  @Get('admirers')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get list of users who favorited you (Premium only)' })
  @ApiResponse({ status: 200, description: 'Admirers list returned' })
  @ApiResponse({ status: 403, description: 'Premium required' })
  async getAdmirers(@CurrentUser('id') userId: string) {
    return this.subscriptionsService.getAdmirers(userId);
  }

  // ==================== Admin Routes ====================

  @Get('admin/stats')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get subscription stats for admin' })
  @ApiResponse({ status: 200, description: 'Stats returned' })
  async adminGetStats() {
    return this.subscriptionsService.adminGetStats();
  }

  @Get('admin/list')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all subscriptions with pagination' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'status', required: false, enum: ['ACTIVE', 'EXPIRED', 'CANCELLED'] })
  @ApiQuery({ name: 'search', required: false, type: String })
  @ApiResponse({ status: 200, description: 'Subscriptions list returned' })
  async adminGetList(
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('status') status?: 'ACTIVE' | 'EXPIRED' | 'CANCELLED',
    @Query('search') search?: string,
  ) {
    return this.subscriptionsService.adminGetList({
      page: page ? Number(page) : undefined,
      limit: limit ? Number(limit) : undefined,
      status: status as any,
      search,
    });
  }
}
