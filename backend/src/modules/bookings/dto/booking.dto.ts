import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { BookingStatus } from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import { IsArray, IsDateString, IsEnum, IsNumber, IsOptional, IsString, IsUUID, Max, Min } from 'class-validator';

export class CreateBookingDto {
  @ApiProperty({ description: 'Partner user ID' })
  @IsUUID()
  partnerId: string;

  @ApiProperty({ example: 'walking', description: 'Service type' })
  @IsString()
  serviceType: string;

  @ApiProperty({ example: '2026-01-20' })
  @IsDateString()
  date: string;

  @ApiProperty({ example: '14:00' })
  @IsString()
  startTime: string;

  @ApiProperty({ example: '17:00' })
  @IsString()
  endTime: string;

  @ApiPropertyOptional({ example: 'Cafe ABC, 123 Nguyen Hue, District 1' })
  @IsOptional()
  @IsString()
  meetingLocation?: string;

  @ApiPropertyOptional({ example: 10.762622 })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  meetingLat?: number;

  @ApiPropertyOptional({ example: 106.660172 })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  meetingLng?: number;

  @ApiPropertyOptional({ example: 'I would like to go walking in the park' })
  @IsOptional()
  @IsString()
  userNote?: string;
}

export class UpdateBookingStatusDto {
  @ApiProperty({ example: 'CONFIRMED', enum: BookingStatus })
  @IsEnum(BookingStatus)
  status: BookingStatus;

  @ApiPropertyOptional({ example: 'Admin updated the status' })
  @IsOptional()
  @IsString()
  reason?: string;
}

export class CancelBookingDto {
  @ApiProperty({ example: 'Schedule conflict' })
  @IsString()
  reason: string;
}

export class CompleteBookingDto {
  @ApiPropertyOptional({ example: 'Great experience!' })
  @IsOptional()
  @IsString()
  note?: string;
}

export class BookingQueryDto {
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

  @ApiPropertyOptional({ enum: BookingStatus, isArray: true, description: 'Filter by status (can be comma-separated)' })
  @IsOptional()
  @Transform(({ value }) => {
    if (typeof value === 'string') {
      return value.split(',').map(s => s.trim());
    }
    return Array.isArray(value) ? value : [value];
  })
  @IsArray()
  @IsEnum(BookingStatus, { each: true })
  status?: BookingStatus[];

  @ApiPropertyOptional({ example: '2026-01-01' })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({ example: '2026-01-31' })
  @IsOptional()
  @IsDateString()
  endDate?: string;
}

export class AdminBookingQueryDto extends BookingQueryDto {
  @ApiPropertyOptional({ description: 'Search by booking code, user name, or partner name' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ description: 'Filter by user ID' })
  @IsOptional()
  @IsUUID()
  userId?: string;

  @ApiPropertyOptional({ description: 'Filter by partner ID' })
  @IsOptional()
  @IsUUID()
  partnerId?: string;

  @ApiPropertyOptional({ description: 'Sort by field', example: 'createdAt' })
  @IsOptional()
  @IsString()
  sortBy?: string;

  @ApiPropertyOptional({ description: 'Sort order', enum: ['asc', 'desc'] })
  @IsOptional()
  @IsString()
  sortOrder?: 'asc' | 'desc';
}
