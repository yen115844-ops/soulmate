import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Gender, KycStatus, UserRole, UserStatus } from '@prisma/client';
import { Type } from 'class-transformer';
import { IsArray, IsDateString, IsEnum, IsNumber, IsOptional, IsString, IsUrl, IsUUID, Max, MaxLength, Min } from 'class-validator';

export class UpdateProfileDto {
  @ApiPropertyOptional({ example: 'Nguyen Van A' })
  @IsOptional()
  @IsString()
  fullName?: string;

  @ApiPropertyOptional({ example: 'Van A' })
  @IsOptional()
  @IsString()
  displayName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUrl()
  avatarUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUrl()
  coverPhotoUrl?: string;

  @ApiPropertyOptional({ example: 'Hello, I love traveling!' })
  @IsOptional()
  @IsString()
  bio?: string;

  @ApiPropertyOptional({ enum: Gender })
  @IsOptional()
  @IsEnum(Gender)
  gender?: Gender;

  @ApiPropertyOptional({ example: '1995-06-15' })
  @IsOptional()
  @IsDateString()
  dateOfBirth?: string;

  @ApiPropertyOptional({ example: 170, minimum: 100, maximum: 250 })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(100)
  @Max(250)
  heightCm?: number;

  @ApiPropertyOptional({ example: 65, minimum: 30, maximum: 200 })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(30)
  @Max(200)
  weightKg?: number;

  @ApiPropertyOptional({ description: 'Province/City ID from master data' })
  @IsOptional()
  @IsUUID()
  provinceId?: string;

  @ApiPropertyOptional({ description: 'District ID from master data' })
  @IsOptional()
  @IsUUID()
  districtId?: string;

  @ApiPropertyOptional({ example: 'Ho Chi Minh City', description: 'Display name (denormalized), auto-populated from provinceId if not provided' })
  @IsOptional()
  @IsString()
  city?: string;

  @ApiPropertyOptional({ example: 'District 1', description: 'Display name (denormalized), auto-populated from districtId if not provided' })
  @IsOptional()
  @IsString()
  district?: string;

  @ApiPropertyOptional({ example: '123 Nguyen Hue Street' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: ['Vietnamese', 'English'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  languages?: string[];

  @ApiPropertyOptional({ example: ['movies', 'travel', 'coffee'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  interests?: string[];

  @ApiPropertyOptional({ example: ['singing', 'dancing'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  talents?: string[];

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsUrl({}, { each: true })
  photos?: string[];
}

export class UpdateLocationDto {
  @ApiPropertyOptional({ example: 10.762622 })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  currentLat?: number;

  @ApiPropertyOptional({ example: 106.660172 })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  currentLng?: number;

  @ApiPropertyOptional({ description: 'Province/City ID from master data' })
  @IsOptional()
  @IsUUID()
  provinceId?: string;

  @ApiPropertyOptional({ description: 'District ID from master data' })
  @IsOptional()
  @IsUUID()
  districtId?: string;

  @ApiPropertyOptional({ example: 'Ho Chi Minh City' })
  @IsOptional()
  @IsString()
  city?: string;

  @ApiPropertyOptional({ example: 'District 1' })
  @IsOptional()
  @IsString()
  district?: string;
}

export class UpdateUserStatusDto {
  @ApiProperty({ example: 'ACTIVE', enum: UserStatus })
  @IsEnum(UserStatus)
  status: UserStatus;

  @ApiPropertyOptional({ example: 'Admin updated status' })
  @IsOptional()
  @IsString()
  reason?: string;
}

export class AdminUserQueryDto {
  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ example: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  @Max(100)
  limit?: number;

  @ApiPropertyOptional({ description: 'Search by email, phone, or name' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ enum: UserRole })
  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;

  @ApiPropertyOptional({ enum: UserStatus })
  @IsOptional()
  @IsEnum(UserStatus)
  status?: UserStatus;

  @ApiPropertyOptional({ description: 'Sort by field', example: 'createdAt' })
  @IsOptional()
  @IsString()
  sortBy?: string;

  @ApiPropertyOptional({ description: 'Sort order', enum: ['asc', 'desc'] })
  @IsOptional()
  @IsString()
  sortOrder?: 'asc' | 'desc';
}

// KYC Admin DTOs
export class AdminKycQueryDto {
  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ example: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  @Max(100)
  limit?: number;

  @ApiPropertyOptional({ description: 'Search by user email or name' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ enum: KycStatus })
  @IsOptional()
  @IsEnum(KycStatus)
  status?: KycStatus;

  @ApiPropertyOptional({ description: 'Sort by field', example: 'submittedAt' })
  @IsOptional()
  @IsString()
  sortBy?: string;

  @ApiPropertyOptional({ description: 'Sort order', enum: ['asc', 'desc'] })
  @IsOptional()
  @IsString()
  sortOrder?: 'asc' | 'desc';
}

export class ReviewKycDto {
  @ApiProperty({ enum: KycStatus, example: 'VERIFIED' })
  @IsEnum(KycStatus)
  status: KycStatus;

  @ApiPropertyOptional({ example: 'ID card information does not match' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  rejectionReason?: string;

  @ApiPropertyOptional({ example: 'Reviewed and approved by admin' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reviewNote?: string;
}
