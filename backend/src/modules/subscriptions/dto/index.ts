import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { SubscriptionStatus } from '../../../generated/prisma/client';

export class VerifyPurchaseDto {
  @ApiProperty({ enum: ['ios', 'android'], description: 'Platform' })
  @IsIn(['ios', 'android'])
  @IsNotEmpty()
  platform: 'ios' | 'android';

  @ApiProperty({ description: 'Product ID from store' })
  @IsString()
  @IsNotEmpty()
  productId: string;

  @ApiProperty({ description: 'Receipt data from IAP' })
  @IsString()
  @IsNotEmpty()
  receiptData: string;
}

export class RestorePurchasesDto {
  @ApiProperty({ enum: ['ios', 'android'], description: 'Platform' })
  @IsIn(['ios', 'android'])
  @IsNotEmpty()
  platform: 'ios' | 'android';

  @ApiProperty({ description: 'Receipt data for restore' })
  @IsString()
  @IsNotEmpty()
  receiptData: string;
}

export class GetSubscriptionsListDto {
  @ApiPropertyOptional()
  @IsOptional()
  page?: number;

  @ApiPropertyOptional()
  @IsOptional()
  limit?: number;

  @ApiPropertyOptional({ enum: ['ACTIVE', 'EXPIRED', 'CANCELLED'] })
  @IsOptional()
  @IsIn(['ACTIVE', 'EXPIRED', 'CANCELLED'])
  status?: SubscriptionStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  search?: string;
}
