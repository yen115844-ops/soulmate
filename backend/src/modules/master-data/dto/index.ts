import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsInt, IsOptional, IsString, Min } from 'class-validator';

// ==================== Province DTOs ====================

export class CreateProvinceDto {
  @ApiProperty({ example: 'HCM' })
  @IsString()
  code: string;

  @ApiProperty({ example: 'Hồ Chí Minh' })
  @IsString()
  name: string;

  @ApiPropertyOptional({ example: 'Ho Chi Minh City' })
  @IsString()
  @IsOptional()
  nameEn?: string;

  @ApiPropertyOptional({ example: 0 })
  @IsInt()
  @Min(0)
  @IsOptional()
  sortOrder?: number;

  @ApiPropertyOptional({ example: true })
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

export class UpdateProvinceDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  code?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  nameEn?: string;

  @ApiPropertyOptional()
  @IsInt()
  @Min(0)
  @IsOptional()
  sortOrder?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

// ==================== District DTOs ====================

export class CreateDistrictDto {
  @ApiProperty()
  @IsString()
  provinceId: string;

  @ApiProperty({ example: 'Q1' })
  @IsString()
  code: string;

  @ApiProperty({ example: 'Quận 1' })
  @IsString()
  name: string;

  @ApiPropertyOptional({ example: 'District 1' })
  @IsString()
  @IsOptional()
  nameEn?: string;

  @ApiPropertyOptional()
  @IsInt()
  @Min(0)
  @IsOptional()
  sortOrder?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

export class UpdateDistrictDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  provinceId?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  code?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  nameEn?: string;

  @ApiPropertyOptional()
  @IsInt()
  @Min(0)
  @IsOptional()
  sortOrder?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

// ==================== Interest DTOs ====================

export class CreateInterestCategoryDto {
  @ApiProperty({ example: 'entertainment' })
  @IsString()
  code: string;

  @ApiProperty({ example: 'Giải trí' })
  @IsString()
  name: string;

  @ApiPropertyOptional({ example: 'Entertainment' })
  @IsString()
  @IsOptional()
  nameEn?: string;

  @ApiPropertyOptional({ example: '🎬' })
  @IsString()
  @IsOptional()
  icon?: string;

  @ApiPropertyOptional({ example: '#FF6B6B' })
  @IsString()
  @IsOptional()
  color?: string;

  @ApiPropertyOptional()
  @IsInt()
  @Min(0)
  @IsOptional()
  sortOrder?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

export class CreateInterestDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  categoryId?: string;

  @ApiProperty({ example: 'travel' })
  @IsString()
  code: string;

  @ApiProperty({ example: 'Du lịch' })
  @IsString()
  name: string;

  @ApiPropertyOptional({ example: 'Travel' })
  @IsString()
  @IsOptional()
  nameEn?: string;

  @ApiPropertyOptional({ example: 'travel' })
  @IsString()
  @IsOptional()
  icon?: string;

  @ApiPropertyOptional()
  @IsInt()
  @Min(0)
  @IsOptional()
  sortOrder?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

export class UpdateInterestDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  categoryId?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  code?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  nameEn?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  icon?: string;

  @ApiPropertyOptional()
  @IsInt()
  @Min(0)
  @IsOptional()
  sortOrder?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

// ==================== Talent DTOs ====================

export class CreateTalentCategoryDto {
  @ApiProperty({ example: 'music' })
  @IsString()
  code: string;

  @ApiProperty({ example: 'Âm nhạc' })
  @IsString()
  name: string;

  @ApiPropertyOptional({ example: 'Music' })
  @IsString()
  @IsOptional()
  nameEn?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  icon?: string;

  @ApiPropertyOptional()
  @IsInt()
  @Min(0)
  @IsOptional()
  sortOrder?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

export class CreateTalentDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  categoryId?: string;

  @ApiProperty({ example: 'singing' })
  @IsString()
  code: string;

  @ApiProperty({ example: 'Ca hát' })
  @IsString()
  name: string;

  @ApiPropertyOptional({ example: 'Singing' })
  @IsString()
  @IsOptional()
  nameEn?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  icon?: string;

  @ApiPropertyOptional()
  @IsInt()
  @Min(0)
  @IsOptional()
  sortOrder?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

export class UpdateTalentDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  categoryId?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  code?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  nameEn?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  icon?: string;

  @ApiPropertyOptional()
  @IsInt()
  @Min(0)
  @IsOptional()
  sortOrder?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

// ==================== Service Type DTOs ====================

export class CreateServiceTypeDto {
  @ApiProperty({ example: 'walking' })
  @IsString()
  code: string;

  @ApiProperty({ example: 'Walking' })
  @IsString()
  name: string;

  @ApiPropertyOptional({ example: 'Đi dạo' })
  @IsString()
  @IsOptional()
  nameVi?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  description?: string;

  @ApiPropertyOptional({ example: '🚶' })
  @IsString()
  @IsOptional()
  icon?: string;

  @ApiPropertyOptional()
  @IsInt()
  @Min(0)
  @IsOptional()
  sortOrder?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

export class UpdateServiceTypeDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  code?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  nameVi?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  description?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  icon?: string;

  @ApiPropertyOptional()
  @IsInt()
  @Min(0)
  @IsOptional()
  sortOrder?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

// ==================== Language DTOs ====================

export class CreateLanguageDto {
  @ApiProperty({ example: 'vi' })
  @IsString()
  code: string;

  @ApiProperty({ example: 'Tiếng Việt' })
  @IsString()
  name: string;

  @ApiPropertyOptional({ example: 'Tiếng Việt' })
  @IsString()
  @IsOptional()
  nativeName?: string;

  @ApiPropertyOptional({ example: '🇻🇳' })
  @IsString()
  @IsOptional()
  flag?: string;

  @ApiPropertyOptional()
  @IsInt()
  @Min(0)
  @IsOptional()
  sortOrder?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

export class UpdateLanguageDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  code?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  nativeName?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  flag?: string;

  @ApiPropertyOptional()
  @IsInt()
  @Min(0)
  @IsOptional()
  sortOrder?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
