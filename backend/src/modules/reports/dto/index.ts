import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsIn, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateReportDto {
  @ApiProperty({ description: 'ID of the user being reported' })
  @IsNotEmpty()
  @IsString()
  reportedId: string;

  @ApiProperty({ description: 'Report type', enum: ['user', 'review', 'message', 'booking'] })
  @IsNotEmpty()
  @IsIn(['user', 'review', 'message', 'booking'])
  type: string;

  @ApiPropertyOptional({ description: 'Reference ID (e.g., review ID, booking ID)' })
  @IsOptional()
  @IsString()
  referenceId?: string;

  @ApiProperty({ description: 'Reason for report' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(200)
  reason: string;

  @ApiPropertyOptional({ description: 'Detailed description' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;

  @ApiPropertyOptional({ description: 'Evidence URLs (photos)' })
  @IsOptional()
  @IsArray()
  evidence?: string[];
}

export class ResolveReportDto {
  @ApiProperty({ description: 'Resolution status', enum: ['resolved', 'rejected'] })
  @IsNotEmpty()
  @IsIn(['resolved', 'rejected'])
  status: string;

  @ApiPropertyOptional({ description: 'Resolution note' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  resolution?: string;
}

export class ReportQueryDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  status?: string;

  @ApiPropertyOptional()
  @IsOptional()
  page?: number;

  @ApiPropertyOptional()
  @IsOptional()
  limit?: number;
}
