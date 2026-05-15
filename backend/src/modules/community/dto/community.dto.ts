import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class CreatePostDto {
  @ApiProperty({ example: 'Hôm nay đi cafe với nhóm mới — vui quá!' })
  @IsString()
  @MaxLength(8000)
  body!: string;

  @ApiPropertyOptional({
    description: 'Image URLs already uploaded via /upload/images',
    example: ['https://res.cloudinary.com/.../a.jpg'],
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @IsString({ each: true })
  @MaxLength(2048, { each: true })
  mediaUrls?: string[];
}

export class QueryCommunityFeedDto {
  @ApiPropertyOptional({ description: 'Opaque cursor from previous page' })
  @IsOptional()
  @IsString()
  @MaxLength(512)
  cursor?: string;

  @ApiPropertyOptional({ default: 20, maximum: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;

  @ApiPropertyOptional({
    description: 'If set, only posts by this author (public profiles)',
  })
  @IsOptional()
  @IsUUID()
  authorId?: string;

  @ApiPropertyOptional({
    description: 'Case-insensitive contains on post body',
    example: 'cafe',
  })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  search?: string;

  @ApiPropertyOptional({
    description: 'ISO 8601 — only posts created at or after this instant',
    example: '2025-01-01T00:00:00.000Z',
  })
  @IsOptional()
  @IsString()
  @MaxLength(40)
  since?: string;
}

export class CreateCommentDto {
  @ApiProperty({ example: 'Đẹp quá!' })
  @IsString()
  @MaxLength(2000)
  body!: string;
}

export class QueryCommentsDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(512)
  cursor?: string;

  @ApiPropertyOptional({ default: 30, maximum: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;
}
