import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { UserRole } from '../../generated/prisma/client';
import { CREDIT_TO_VND_RATE } from './credits.constants';
import { CreditsService } from './credits.service';
import {
  CreateCreditPackageDto,
  UpdateBankInfoDto,
  UpdateCreditPackageDto,
  VerifyCreditPurchaseDto,
  WithdrawCreditsDto,
} from './dto';

@Controller('credits')
export class CreditsController {
  constructor(private readonly creditsService: CreditsService) {}

  /**
   * Get available credit packages
   */
  @Get('packages')
  async getPackages() {
    const packages = await this.creditsService.getPackages();
    return {
      packages,
      exchangeRate: CREDIT_TO_VND_RATE,
    };
  }

  /**
   * Get user's wallet/balance
   */
  @Get('wallet')
  @UseGuards(JwtAuthGuard)
  async getWallet(@CurrentUser('id') userId: string) {
    return this.creditsService.getWallet(userId);
  }

  /**
   * Get transaction history
   */
  @Get('transactions')
  @UseGuards(JwtAuthGuard)
  async getTransactions(
    @CurrentUser('id') userId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.creditsService.getTransactions(
      userId,
      parseInt(page || '1'),
      parseInt(limit || '20'),
    );
  }

  /**
   * Verify credit purchase via IAP
   */
  @Post('purchase')
  @UseGuards(JwtAuthGuard)
  async verifyCreditPurchase(
    @CurrentUser('id') userId: string,
    @Body() dto: VerifyCreditPurchaseDto,
  ) {
    return this.creditsService.verifyCreditPurchase(userId, dto);
  }

  /**
   * Request withdrawal (convert credits to VND)
   */
  @Post('withdraw')
  @UseGuards(JwtAuthGuard)
  async requestWithdrawal(
    @CurrentUser('id') userId: string,
    @Body() dto: WithdrawCreditsDto,
  ) {
    return this.creditsService.requestWithdrawal(userId, dto);
  }

  /**
   * Update bank account info
   */
  @Put('bank-info')
  @UseGuards(JwtAuthGuard)
  async updateBankInfo(
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateBankInfoDto,
  ) {
    return this.creditsService.updateBankInfo(userId, dto);
  }

  // ==================== ADMIN ENDPOINTS ====================

  /**
   * Create a new credit package (Admin only)
   */
  @Post('packages')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async createPackage(@Body() dto: CreateCreditPackageDto) {
    return this.creditsService.createPackage(dto);
  }

  /**
   * Update a credit package (Admin only)
   */
  @Put('packages/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async updatePackage(
    @Param('id') id: string,
    @Body() dto: UpdateCreditPackageDto,
  ) {
    return this.creditsService.updatePackage(id, dto);
  }

  /**
   * Delete a credit package (Admin only)
   */
  @Delete('packages/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async deletePackage(@Param('id') id: string) {
    return this.creditsService.deletePackage(id);
  }
}
