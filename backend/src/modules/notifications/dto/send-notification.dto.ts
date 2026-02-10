import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { NotificationType } from '@prisma/client';
import {
    IsArray,
    IsEnum,
    IsNotEmpty,
    IsObject,
    IsOptional,
    IsString,
} from 'class-validator';

export class SendPushNotificationDto {
  @ApiProperty({
    description: 'User ID to send notification to',
  })
  @IsString()
  @IsNotEmpty()
  userId: string;

  @ApiProperty({
    description: 'Notification type',
    enum: NotificationType,
  })
  @IsEnum(NotificationType)
  type: NotificationType;

  @ApiProperty({
    description: 'Notification title',
    example: 'Bạn có yêu cầu đặt lịch mới',
  })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({
    description: 'Notification body',
    example: 'Nguyễn Văn A muốn đặt lịch với bạn vào ngày 20/01/2026',
  })
  @IsString()
  @IsNotEmpty()
  body: string;

  @ApiPropertyOptional({
    description: 'Image URL for rich notification',
  })
  @IsString()
  @IsOptional()
  imageUrl?: string;

  @ApiPropertyOptional({
    description: 'Action type for deep linking',
    example: 'booking',
  })
  @IsString()
  @IsOptional()
  actionType?: string;

  @ApiPropertyOptional({
    description: 'Action ID for deep linking',
    example: 'booking-uuid-123',
  })
  @IsString()
  @IsOptional()
  actionId?: string;

  @ApiPropertyOptional({
    description: 'Additional data to include in notification payload',
  })
  @IsObject()
  @IsOptional()
  data?: Record<string, any>;
}

export class SendBatchNotificationDto {
  @ApiProperty({
    description: 'List of user IDs to send notification to',
    type: [String],
  })
  @IsArray()
  @IsString({ each: true })
  userIds: string[];

  @ApiProperty({
    description: 'Notification type',
    enum: NotificationType,
  })
  @IsEnum(NotificationType)
  type: NotificationType;

  @ApiProperty({
    description: 'Notification title',
  })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({
    description: 'Notification body',
  })
  @IsString()
  @IsNotEmpty()
  body: string;

  @ApiPropertyOptional({
    description: 'Image URL for rich notification',
  })
  @IsString()
  @IsOptional()
  imageUrl?: string;

  @ApiPropertyOptional({
    description: 'Action type for deep linking',
  })
  @IsString()
  @IsOptional()
  actionType?: string;

  @ApiPropertyOptional({
    description: 'Action ID for deep linking',
  })
  @IsString()
  @IsOptional()
  actionId?: string;

  @ApiPropertyOptional({
    description: 'Additional data to include in notification payload',
  })
  @IsObject()
  @IsOptional()
  data?: Record<string, any>;
}

// Internal DTO for queue job
export interface NotificationJobData {
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  imageUrl?: string;
  actionType?: string;
  actionId?: string;
  data?: Record<string, any>;
  // Internal flags
  saveToDb?: boolean;
  sendPush?: boolean;
  notificationId?: string;
}

export interface BatchNotificationJobData {
  userIds: string[];
  type: NotificationType;
  title: string;
  body: string;
  imageUrl?: string;
  actionType?: string;
  actionId?: string;
  data?: Record<string, any>;
}
