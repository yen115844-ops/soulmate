import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class TriggerSosDto {
  @ApiProperty({ description: 'Latitude of user location' })
  @IsNotEmpty()
  latitude: number;

  @ApiProperty({ description: 'Longitude of user location' })
  @IsNotEmpty()
  longitude: number;

  @ApiPropertyOptional({ description: 'Address description' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ description: 'Related booking ID' })
  @IsOptional()
  @IsString()
  bookingId?: string;
}

export class ResolveSosDto {
  @ApiProperty({ description: 'Resolution note' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(1000)
  resolutionNote: string;

  @ApiPropertyOptional({ description: 'Mark as false alarm' })
  @IsOptional()
  @IsBoolean()
  isFalseAlarm?: boolean;
}

export class LogLocationDto {
  @ApiProperty()
  @IsNotEmpty()
  latitude: number;

  @ApiProperty()
  @IsNotEmpty()
  longitude: number;

  @ApiPropertyOptional()
  @IsOptional()
  accuracy?: number;

  @ApiPropertyOptional()
  @IsOptional()
  speed?: number;

  @ApiPropertyOptional()
  @IsOptional()
  heading?: number;

  @ApiProperty({ description: 'Booking ID for location tracking' })
  @IsNotEmpty()
  @IsString()
  bookingId: string;
}

// Re-export from users module
export {
  CreateEmergencyContactDto,
  UpdateEmergencyContactDto,
} from '../../users/dto';
