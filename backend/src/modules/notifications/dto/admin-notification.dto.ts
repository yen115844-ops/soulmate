import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { NotificationType } from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import {
    IsArray,
    IsBoolean,
    IsEnum,
    IsNumber,
    IsOptional,
    IsString,
    MaxLength,
    Min,
    MinLength,
} from 'class-validator';

export class AdminQueryNotificationsDto {
  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  limit?: number = 20;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ enum: NotificationType })
  @IsOptional()
  @IsEnum(NotificationType)
  type?: NotificationType;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  userId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  isRead?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  sortBy?: string = 'createdAt';

  @ApiPropertyOptional({ enum: ['asc', 'desc'] })
  @IsOptional()
  @IsString()
  sortOrder?: 'asc' | 'desc' = 'desc';
}

export class AdminSendNotificationDto {
  @ApiProperty({ description: 'Notification title' })
  @IsString()
  @MinLength(1)
  @MaxLength(200)
  title: string;

  @ApiProperty({ description: 'Notification body' })
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  body: string;

  @ApiPropertyOptional({ enum: NotificationType })
  @IsOptional()
  @IsEnum(NotificationType)
  type?: NotificationType = NotificationType.SYSTEM;

  @ApiPropertyOptional({ description: 'Image URL' })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiPropertyOptional({ description: 'Action type for deep linking' })
  @IsOptional()
  @IsString()
  actionType?: string;

  @ApiPropertyOptional({ description: 'Action ID for deep linking' })
  @IsOptional()
  @IsString()
  actionId?: string;

  @ApiPropertyOptional({ description: 'Additional data as JSON' })
  @IsOptional()
  data?: any;

  @ApiPropertyOptional({ description: 'Send push notification', default: true })
  @IsOptional()
  @IsBoolean()
  sendPush?: boolean = true;

  @ApiPropertyOptional({ description: 'User IDs to send to (for targeted send)' })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  userIds?: string[];
}

export class PushQueueStatusDto {
  @ApiPropertyOptional({ description: 'Last push/queue error message (e.g. on production VPS)' })
  lastError?: string | null;
  @ApiPropertyOptional({ description: 'ISO timestamp of last error' })
  lastErrorAt?: string | null;
  @ApiProperty({ description: 'Number of failed jobs in queue' })
  failedCount: number;
  @ApiProperty({ description: 'Number of jobs waiting in queue' })
  waitingCount: number;
}

export class NotificationStats {
  total: number;
  unread: number;
  read: number;
  byType: {
    type: NotificationType;
    count: number;
  }[];
  today: number;
  thisWeek: number;
  thisMonth: number;
  /** Push queue status and last error for debugging (e.g. production)' */
  pushQueue?: PushQueueStatusDto;
}
