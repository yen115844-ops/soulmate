import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsObject } from 'class-validator';

/**
 * DTO for updating app settings.
 * Body is a key-value map: { "key_name": "value", ... }
 * Values are stored as strings; backend does not type them.
 */
export class UpdateAppSettingsDto {
  @ApiProperty({
    description: 'Key-value map of setting keys to values (all strings)',
    example: {
      app_name: 'Mate Social',
      support_email: 'support@matesocial.vn',
      min_booking_hours: '1',
    },
  })
  @IsObject()
  values!: Record<string, string>;
}

export class AppSettingItemDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  key!: string;

  @ApiProperty()
  value!: string;

  @ApiPropertyOptional()
  description?: string;
}

export class AppSettingsResponseDto {
  @ApiProperty({ type: [Object], description: 'List of settings with id, key, value, description' })
  items!: Array<{ id: string; key: string; value: string; description?: string }>;

  @ApiProperty({ description: 'Key-value map for easy form binding' })
  values!: Record<string, string>;
}
