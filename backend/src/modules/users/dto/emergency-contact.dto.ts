import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class CreateEmergencyContactDto {
  @ApiProperty({ description: 'Contact name', example: 'Bố' })
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  name: string;

  @ApiProperty({ description: 'Phone number', example: '0901234567' })
  @IsString()
  @Matches(/^[0-9]{10,11}$/, { message: 'Phone number must be 10-11 digits' })
  phone: string;

  @ApiPropertyOptional({ description: 'Relationship', example: 'parent' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  relationship?: string;

  @ApiPropertyOptional({ description: 'Is primary contact', default: false })
  @IsOptional()
  @IsBoolean()
  isPrimary?: boolean;
}

export class UpdateEmergencyContactDto {
  @ApiPropertyOptional({ description: 'Contact name', example: 'Bố' })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  name?: string;

  @ApiPropertyOptional({ description: 'Phone number', example: '0901234567' })
  @IsOptional()
  @IsString()
  @Matches(/^[0-9]{10,11}$/, { message: 'Phone number must be 10-11 digits' })
  phone?: string;

  @ApiPropertyOptional({ description: 'Relationship', example: 'parent' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  relationship?: string;

  @ApiPropertyOptional({ description: 'Is primary contact' })
  @IsOptional()
  @IsBoolean()
  isPrimary?: boolean;
}

export class EmergencyContactResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  name: string;

  @ApiProperty()
  phone: string;

  @ApiPropertyOptional()
  relationship?: string;

  @ApiProperty()
  isPrimary: boolean;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}
