import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
    IsArray,
    IsBoolean,
    IsEnum,
    IsNumber,
    IsOptional,
    IsString,
    Max,
    MaxLength,
    Min,
    MinLength,
    ValidateNested,
} from 'class-validator';
import { SlotStatus, UserStatus } from '../../../generated/prisma/client';

/** Rich gallery entry (URL + optional size), e.g. from POST /upload/image */
export class PartnerProfilePhotoItemDto {
  @ApiProperty({ example: '/api/upload/files/uuid.jpg' })
  @IsString()
  url: string;

  @ApiPropertyOptional({ example: 1080, description: 'Pixel width after optimize' })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(1)
  @Max(20000)
  width?: number;

  @ApiPropertyOptional({ example: 1440 })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(1)
  @Max(20000)
  height?: number;
}

export class CreatePartnerProfileDto {
  @ApiProperty({ example: 500000, description: 'Hourly rate in VND' })
  @IsNumber()
  @Type(() => Number)
  @Min(0)
  hourlyRate: number;

  @ApiPropertyOptional({ example: 3, default: 3 })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(1)
  @Max(24)
  minimumHours?: number;

  @ApiPropertyOptional({ example: 'VND', default: 'VND' })
  @IsOptional()
  @IsString()
  currency?: string;

  @ApiProperty({
    example: ['walking', 'movie', 'coffee'],
    description: 'Service types offered',
  })
  @IsArray()
  @IsString({ each: true })
  serviceTypes: string[];

  @ApiPropertyOptional({ example: 'Hello, I am a friendly partner!' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  introduction?: string;

  @ApiPropertyOptional({ example: 'Tôi là người thân thiện, vui vẻ...' })
  @IsOptional()
  @IsString()
  @MinLength(20)
  @MaxLength(200)
  bio?: string;

  @ApiPropertyOptional({ example: 2 })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(0)
  experienceYears?: number;

  // Bank info
  @ApiPropertyOptional({ example: 'Vietcombank' })
  @IsOptional()
  @IsString()
  bankName?: string;

  @ApiPropertyOptional({ example: '1234567890' })
  @IsOptional()
  @IsString()
  bankAccountNo?: string;

  @ApiPropertyOptional({ example: 'NGUYEN VAN A' })
  @IsOptional()
  @IsString()
  bankAccountName?: string;

  // Photos - URL strings (legacy); prefer photoItems when dimensions known
  @ApiPropertyOptional({ example: ['/api/upload/files/a.jpg'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photoUrls?: string[];

  @ApiPropertyOptional({ type: [PartnerProfilePhotoItemDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PartnerProfilePhotoItemDto)
  photoItems?: PartnerProfilePhotoItemDto[];
}

export class UpdatePartnerProfileDto {
  @ApiPropertyOptional({ example: 600000 })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(0)
  hourlyRate?: number;

  @ApiPropertyOptional({ example: 2 })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(1)
  @Max(24)
  minimumHours?: number;

  @ApiPropertyOptional({ example: ['walking', 'movie', 'coffee', 'party'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  serviceTypes?: string[];

  @ApiPropertyOptional({ example: 'Updated introduction' })
  @IsOptional()
  @IsString()
  introduction?: string;

  @ApiPropertyOptional({ example: 3 })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(0)
  experienceYears?: number;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  isAvailable?: boolean;

  // Bank info
  @ApiPropertyOptional({ example: 'Vietcombank' })
  @IsOptional()
  @IsString()
  bankName?: string;

  @ApiPropertyOptional({ example: '1234567890' })
  @IsOptional()
  @IsString()
  bankAccountNo?: string;

  @ApiPropertyOptional({ example: 'NGUYEN VAN A' })
  @IsOptional()
  @IsString()
  bankAccountName?: string;

  @ApiPropertyOptional({ example: ['/api/upload/files/a.jpg'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photoUrls?: string[];

  @ApiPropertyOptional({ type: [PartnerProfilePhotoItemDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PartnerProfilePhotoItemDto)
  photoItems?: PartnerProfilePhotoItemDto[];

  // Remove specific photos (match by URL)
  @ApiPropertyOptional({ example: ['/api/upload/files/old.jpg'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  removePhotoUrls?: string[];
}

export class CreateAvailabilitySlotDto {
  @ApiProperty({ example: '2026-01-15' })
  @IsString()
  date: string;

  @ApiProperty({ example: '09:00' })
  @IsString()
  startTime: string;

  @ApiProperty({ example: '17:00' })
  @IsString()
  endTime: string;

  @ApiPropertyOptional({ example: 'Available for morning dates' })
  @IsOptional()
  @IsString()
  note?: string;
}

export class UpdateAvailabilitySlotDto {
  @ApiPropertyOptional({ enum: Object.values(SlotStatus) })
  @IsOptional()
  @IsEnum(SlotStatus)
  status?: SlotStatus;

  @ApiPropertyOptional({ example: 'Updated note' })
  @IsOptional()
  @IsString()
  note?: string;
}

export class SearchPartnersDto {
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
  @Max(50)
  limit?: number;

  @ApiPropertyOptional({
    example: 'Nguyen',
    description: 'Search keyword (name, introduction)',
  })
  @IsOptional()
  @IsString()
  q?: string;

  @ApiPropertyOptional({ example: 'walking' })
  @IsOptional()
  @IsString()
  serviceType?: string;

  @ApiPropertyOptional({ example: 'FEMALE' })
  @IsOptional()
  @IsString()
  gender?: string;

  @ApiPropertyOptional({ example: 18 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(18)
  minAge?: number;

  @ApiPropertyOptional({ example: 30 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Max(100)
  maxAge?: number;

  @ApiPropertyOptional({ example: 100000 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  minRate?: number;

  @ApiPropertyOptional({ example: 1000000 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  maxRate?: number;

  @ApiPropertyOptional({ example: 10.762622 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  lat?: number;

  @ApiPropertyOptional({ example: 106.660172 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  lng?: number;

  @ApiPropertyOptional({ example: 10, description: 'Radius in km' })
  @IsOptional()
  @Type(() => Number)
  radius?: number;

  @ApiPropertyOptional({ description: 'Province/City ID from master data' })
  @IsOptional()
  @IsString()
  provinceId?: string;

  @ApiPropertyOptional({
    description: 'Province/City ID from master data (alias for provinceId)',
  })
  @IsOptional()
  @IsString()
  cityId?: string;

  @ApiPropertyOptional({ description: 'District ID from master data' })
  @IsOptional()
  @IsString()
  districtId?: string;

  @ApiPropertyOptional({
    example: 'rating',
    enum: ['rating', 'price_low', 'price_high', 'distance', 'newest'],
  })
  @IsOptional()
  @IsString()
  sortBy?: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  verifiedOnly?: boolean;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  availableNow?: boolean;
}

// Admin DTOs
export class AdminPartnerQueryDto {
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

  @ApiPropertyOptional({ example: 'nguyen' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ enum: Object.values(UserStatus) })
  @IsOptional()
  @IsEnum(UserStatus)
  status?: UserStatus;

  @ApiPropertyOptional({ example: 'walking' })
  @IsOptional()
  @IsString()
  serviceType?: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  isAvailable?: boolean;

  @ApiPropertyOptional({ example: 'createdAt' })
  @IsOptional()
  @IsString()
  sortBy?: string;

  @ApiPropertyOptional({ example: 'desc', enum: ['asc', 'desc'] })
  @IsOptional()
  @IsString()
  sortOrder?: 'asc' | 'desc';
}

export class UpdatePartnerStatusDto {
  @ApiProperty({ enum: Object.values(UserStatus) })
  @IsEnum(UserStatus)
  status: UserStatus;

  @ApiPropertyOptional({ example: 'Violating community guidelines' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
