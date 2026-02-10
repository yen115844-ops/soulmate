import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

/**
 * DTO for updating terms content (Admin only).
 */
export class UpdateTermsDto {
  @ApiPropertyOptional({
    description: 'Terms of Service content (HTML or Markdown)',
  })
  @IsOptional()
  @IsString()
  termsOfService?: string;

  @ApiPropertyOptional({
    description: 'Terms and Conditions content (HTML or Markdown)',
  })
  @IsOptional()
  @IsString()
  termsAndConditions?: string;
}
