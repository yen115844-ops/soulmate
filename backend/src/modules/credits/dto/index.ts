import { Transform } from 'class-transformer';
import { IsBoolean, IsEnum, IsNotEmpty, IsNumber, IsOptional, IsString, Min } from 'class-validator';

/**
 * DTO for verifying credit purchase via IAP
 */
export class VerifyCreditPurchaseDto {
  @IsEnum(['ios', 'android'])
  platform: 'ios' | 'android';

  @IsString()
  @IsNotEmpty()
  productId: string;

  @IsString()
  @IsNotEmpty()
  transactionId: string;

  @IsString()
  @IsNotEmpty()
  receiptData: string;
}

/**
 * DTO for withdrawal request
 */
export class WithdrawCreditsDto {
  @IsNumber()
  @Min(10, { message: 'Minimum withdrawal is 10 credits' })
  amount: number;

  @IsString()
  @IsOptional()
  note?: string;
}

/**
 * DTO for transferring credits (internal use)
 */
export class TransferCreditsDto {
  @IsString()
  @IsNotEmpty()
  fromUserId: string;

  @IsString()
  @IsNotEmpty()
  toUserId: string;

  @IsNumber()
  @Min(1)
  amount: number;

  @IsString()
  @IsOptional()
  bookingId?: string;

  @IsString()
  @IsOptional()
  description?: string;
}

/**
 * DTO for updating bank info
 */
export class UpdateBankInfoDto {
  @IsString()
  @IsNotEmpty()
  bankName: string;

  @IsString()
  @IsNotEmpty()
  bankAccountNo: string;

  @IsString()
  @IsNotEmpty()
  bankAccountName: string;
}

/**
 * DTO for creating a credit package (Admin)
 */
export class CreateCreditPackageDto {
  @IsString()
  @IsNotEmpty()
  code: string;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  nameVi: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsNumber()
  @Min(1)
  creditAmount: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  bonusCredits?: number;

  @IsNumber()
  @Min(0)
  priceVnd: number;

  @IsString()
  @IsOptional()
  appleProductId?: string;

  @IsString()
  @IsOptional()
  googleProductId?: string;

  @IsNumber()
  @IsOptional()
  originalPrice?: number;

  @IsNumber()
  @IsOptional()
  discountPercent?: number;

  @IsBoolean()
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  isActive?: boolean;

  @IsBoolean()
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  isBestValue?: boolean;

  @IsNumber()
  @IsOptional()
  sortOrder?: number;
}

/**
 * DTO for updating a credit package (Admin)
 */
export class UpdateCreditPackageDto {
  @IsString()
  @IsOptional()
  code?: string;

  @IsString()
  @IsOptional()
  name?: string;

  @IsString()
  @IsOptional()
  nameVi?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsNumber()
  @Min(1)
  @IsOptional()
  creditAmount?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  bonusCredits?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  priceVnd?: number;

  @IsString()
  @IsOptional()
  appleProductId?: string;

  @IsString()
  @IsOptional()
  googleProductId?: string;

  @IsNumber()
  @IsOptional()
  originalPrice?: number;

  @IsNumber()
  @IsOptional()
  discountPercent?: number;

  @IsBoolean()
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  isActive?: boolean;

  @IsBoolean()
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  isBestValue?: boolean;

  @IsNumber()
  @IsOptional()
  sortOrder?: number;
}
