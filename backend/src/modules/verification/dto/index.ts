import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';
import { KycStatus } from '../../../generated/prisma/client';

export class SubmitSelfieDto {
  @ApiPropertyOptional({ description: 'Device fingerprint/info for fraud detection' })
  @IsOptional()
  @IsString()
  deviceInfo?: string;
}

export class ReviewVerificationDto {
  @ApiProperty({ enum: ['VERIFIED', 'REJECTED'], description: 'New status' })
  @IsIn(['VERIFIED', 'REJECTED'])
  @IsNotEmpty()
  status: KycStatus;

  @ApiPropertyOptional({ description: 'Reason for rejection' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  rejectionReason?: string;

  @ApiPropertyOptional({ description: 'Admin review note (internal)' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reviewNote?: string;
}

export class GetVerificationListDto {
  @ApiPropertyOptional()
  @IsOptional()
  page?: number;

  @ApiPropertyOptional()
  @IsOptional()
  limit?: number;

  @ApiPropertyOptional({ enum: ['NONE', 'PENDING', 'VERIFIED', 'REJECTED'] })
  @IsOptional()
  @IsIn(['NONE', 'PENDING', 'VERIFIED', 'REJECTED'])
  status?: KycStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  sortBy?: string;

  @ApiPropertyOptional({ enum: ['asc', 'desc'] })
  @IsOptional()
  sortOrder?: 'asc' | 'desc';
}
