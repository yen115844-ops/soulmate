import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiConsumes,
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
import { UploadService } from '../upload/upload.service';
import { ReviewVerificationDto, SubmitSelfieDto } from './dto';
import { VerificationService } from './verification.service';

@ApiTags('Verification')
@Controller('verification')
export class VerificationController {
  constructor(
    private readonly verificationService: VerificationService,
    private readonly uploadService: UploadService,
  ) {}

  // ==================== User Routes ====================

  @Post('submit-selfie')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @UseInterceptors(FileInterceptor('selfie'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({
    summary: 'Submit selfie for soft verification (liveness check)',
  })
  @ApiResponse({ status: 201, description: 'Selfie submitted and processed' })
  @ApiResponse({ status: 400, description: 'Invalid file or already verified' })
  async submitSelfie(
    @CurrentUser('id') userId: string,
    @UploadedFile() selfie: Express.Multer.File,
    @Body() dto: SubmitSelfieDto,
  ) {
    if (!selfie) {
      throw new Error('Selfie file is required');
    }

    this.uploadService.validateMagicBytes(selfie);
    await this.uploadService.optimizeImage(selfie, {
      maxWidth: 1280,
      maxHeight: 1280,
      quality: 84,
    });

    return this.verificationService.submitSelfie(userId, selfie, dto);
  }

  @Get('status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current verification status' })
  @ApiResponse({ status: 200, description: 'Verification status returned' })
  async getStatus(@CurrentUser('id') userId: string) {
    return this.verificationService.getStatus(userId);
  }

  // ==================== Admin Routes ====================

  @Get('admin/stats')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get verification stats for admin dashboard' })
  @ApiResponse({ status: 200, description: 'Stats returned' })
  async adminGetStats() {
    return this.verificationService.adminGetStats();
  }

  @Get('admin/list')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get paginated verification list' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: ['NONE', 'PENDING', 'VERIFIED', 'REJECTED'],
  })
  @ApiQuery({ name: 'search', required: false, type: String })
  @ApiQuery({ name: 'sortBy', required: false, type: String })
  @ApiQuery({ name: 'sortOrder', required: false, enum: ['asc', 'desc'] })
  @ApiResponse({ status: 200, description: 'Verification list returned' })
  async adminGetList(
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('status') status?: 'NONE' | 'PENDING' | 'VERIFIED' | 'REJECTED',
    @Query('search') search?: string,
    @Query('sortBy') sortBy?: string,
    @Query('sortOrder') sortOrder?: 'asc' | 'desc',
  ) {
    return this.verificationService.adminGetList({
      page: page ? Number(page) : undefined,
      limit: limit ? Number(limit) : undefined,
      status: status as any,
      search,
      sortBy,
      sortOrder,
    });
  }

  @Get('admin/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get verification detail by ID' })
  @ApiResponse({ status: 200, description: 'Verification detail returned' })
  @ApiResponse({ status: 404, description: 'Verification not found' })
  async adminGetById(@Param('id') id: string) {
    return this.verificationService.adminGetById(id);
  }

  @Patch('admin/:id/review')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Review verification (approve/reject)' })
  @ApiResponse({ status: 200, description: 'Verification reviewed' })
  @ApiResponse({ status: 404, description: 'Verification not found' })
  async adminReview(
    @Param('id') id: string,
    @CurrentUser('id') adminId: string,
    @Body() dto: ReviewVerificationDto,
  ) {
    return this.verificationService.adminReview(id, adminId, dto);
  }
}
