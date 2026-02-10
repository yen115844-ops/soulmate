import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsUrl, MaxLength } from 'class-validator';

export class SubmitKycDto {
  @ApiProperty({ description: 'Front ID card image URL' })
  @IsString()
  @IsUrl()
  idCardFrontUrl: string;

  @ApiProperty({ description: 'Back ID card image URL' })
  @IsString()
  @IsUrl()
  idCardBackUrl: string;

  @ApiProperty({ description: 'Selfie image URL' })
  @IsString()
  @IsUrl()
  selfieUrl: string;

  @ApiPropertyOptional({ description: 'ID card number' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  idCardNumber?: string;

  @ApiPropertyOptional({ description: 'Full name on ID card' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  idCardName?: string;
}

export class KycStatusResponseDto {
  @ApiProperty()
  status: string;

  @ApiPropertyOptional()
  idCardFrontUrl?: string;

  @ApiPropertyOptional()
  idCardBackUrl?: string;

  @ApiPropertyOptional()
  selfieUrl?: string;

  @ApiPropertyOptional()
  rejectionReason?: string;

  @ApiPropertyOptional()
  submittedAt?: Date;

  @ApiPropertyOptional()
  verifiedAt?: Date;
}
