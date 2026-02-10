import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsIn, IsOptional, IsString } from 'class-validator';

export class UpdateSettingsDto {
  // Notifications
  @ApiPropertyOptional({ description: 'Enable push notifications' })
  @IsBoolean()
  @IsOptional()
  pushNotificationsEnabled?: boolean;

  @ApiPropertyOptional({ description: 'Enable message notifications' })
  @IsBoolean()
  @IsOptional()
  messageNotificationsEnabled?: boolean;

  @ApiPropertyOptional({ description: 'Enable notification sound' })
  @IsBoolean()
  @IsOptional()
  soundEnabled?: boolean;

  // Appearance
  @ApiPropertyOptional({ description: 'Enable dark mode' })
  @IsBoolean()
  @IsOptional()
  darkModeEnabled?: boolean;

  @ApiPropertyOptional({ description: 'Use system theme' })
  @IsBoolean()
  @IsOptional()
  useSystemTheme?: boolean;

  @ApiPropertyOptional({ description: 'Language code', example: 'vi' })
  @IsString()
  @IsIn(['vi', 'en'])
  @IsOptional()
  language?: string;

  // Privacy
  @ApiPropertyOptional({ description: 'Enable location access' })
  @IsBoolean()
  @IsOptional()
  locationEnabled?: boolean;

  @ApiPropertyOptional({ description: 'Show online status' })
  @IsBoolean()
  @IsOptional()
  showOnlineStatus?: boolean;

  @ApiPropertyOptional({ 
    description: 'Who can send messages', 
    enum: ['everyone', 'verified', 'none'] 
  })
  @IsString()
  @IsIn(['everyone', 'verified', 'none'])
  @IsOptional()
  allowMessagesFrom?: string;
}

export class UserSettingsResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  userId: string;

  @ApiProperty()
  pushNotificationsEnabled: boolean;

  @ApiProperty()
  messageNotificationsEnabled: boolean;

  @ApiProperty()
  soundEnabled: boolean;

  @ApiProperty()
  darkModeEnabled: boolean;

  @ApiProperty()
  useSystemTheme: boolean;

  @ApiProperty()
  language: string;

  @ApiProperty()
  locationEnabled: boolean;

  @ApiProperty()
  showOnlineStatus: boolean;

  @ApiProperty()
  allowMessagesFrom: string;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}
