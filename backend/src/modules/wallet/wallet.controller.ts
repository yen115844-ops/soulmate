import {
    Body,
    Controller,
    Get,
    HttpCode,
    HttpStatus,
    Post,
    Query,
    UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { WithdrawDto } from './dto/withdraw.dto';
import { WalletService } from './wallet.service';

@ApiTags('Wallet')
@Controller('wallet')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class WalletController {
  constructor(private readonly walletService: WalletService) {}

  @Get()
  @ApiOperation({ summary: 'Get my wallet' })
  @ApiResponse({ status: 200, description: 'Wallet retrieved' })
  async getWallet(@CurrentUser('id') userId: string) {
    return this.walletService.getOrCreateWallet(userId);
  }

  @Get('transactions')
  @ApiOperation({ summary: 'Get my wallet transactions' })
  @ApiResponse({ status: 200, description: 'Transactions retrieved' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getTransactions(
    @CurrentUser('id') userId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.walletService.getTransactions(
      userId,
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
    );
  }

  @Post('withdraw')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Request withdrawal' })
  @ApiResponse({ status: 200, description: 'Withdrawal requested' })
  async requestWithdraw(
    @CurrentUser('id') userId: string,
    @Body() dto: WithdrawDto,
  ) {
    return this.walletService.requestWithdraw(userId, dto.amount, dto.bankInfo);
  }
}
