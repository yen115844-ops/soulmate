import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsBoolean, IsNumber, IsObject, IsOptional, IsString, MaxLength, Min, ValidateNested } from 'class-validator';

export class CreateConversationDto {
  @ApiProperty({ description: 'User ID of the other participant' })
  @IsString()
  participantId: string;

  @ApiPropertyOptional({ description: 'Initial message content' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  initialMessage?: string;
}

export class SendMessageDto {
  @ApiProperty({ description: 'Message content' })
  @IsString()
  @MaxLength(2000)
  content: string;

  @ApiPropertyOptional({ description: 'Message type: text, image, system', default: 'text' })
  @IsOptional()
  @IsString()
  type?: string;
}

export class LocationDto {
  @ApiProperty({ description: 'Latitude' })
  @IsNumber()
  lat: number;

  @ApiProperty({ description: 'Longitude' })
  @IsNumber()
  lng: number;

  @ApiPropertyOptional({ description: 'Address string' })
  @IsOptional()
  @IsString()
  address?: string;
}

export class SendMessageWithMediaDto {
  @ApiPropertyOptional({ description: 'Message content' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  content?: string;

  @ApiPropertyOptional({ description: 'Message type: text, image, voice, location', default: 'text' })
  @IsOptional()
  @IsString()
  type?: string;

  @ApiPropertyOptional({ description: 'Media URL (for image/voice messages)' })
  @IsOptional()
  @IsString()
  mediaUrl?: string;

  @ApiPropertyOptional({ description: 'Location data (for location messages)' })
  @IsOptional()
  @ValidateNested()
  @Type(() => LocationDto)
  location?: LocationDto;
}

export class QueryConversationsDto {
  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ example: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  limit?: number;
}

export class QueryMessagesDto {
  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ example: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  limit?: number;

  @ApiPropertyOptional({ description: 'Cursor for pagination (message ID)' })
  @IsOptional()
  @IsString()
  before?: string;
}

// ==================== Socket Event DTOs ====================

export class SocketAuthenticateDto {
  @ApiProperty({ description: 'JWT access token' })
  @IsString()
  token: string;

  @ApiProperty({ description: 'User ID' })
  @IsString()
  userId: string;
}

export class SocketJoinConversationDto {
  @ApiProperty({ description: 'Conversation ID to join' })
  @IsString()
  conversationId: string;
}

export class SocketTypingDto {
  @ApiProperty({ description: 'Conversation ID' })
  @IsString()
  conversationId: string;
}

export class SocketSendMessageDto {
  @ApiProperty({ description: 'Conversation ID' })
  @IsString()
  conversationId: string;

  @ApiProperty({ description: 'Message content' })
  @IsString()
  @MaxLength(2000)
  content: string;

  @ApiPropertyOptional({ description: 'Message type', default: 'text' })
  @IsOptional()
  @IsString()
  type?: 'text' | 'image' | 'voice' | 'location';

  @ApiPropertyOptional({ description: 'Client-side temporary ID for optimistic UI' })
  @IsOptional()
  @IsString()
  tempId?: string;

  @ApiPropertyOptional({ description: 'Media URL' })
  @IsOptional()
  @IsString()
  mediaUrl?: string;

  @ApiPropertyOptional({ description: 'Location data' })
  @IsOptional()
  @IsObject()
  location?: {
    lat: number;
    lng: number;
    address?: string;
  };
}

export class SocketMarkReadDto {
  @ApiProperty({ description: 'Conversation ID' })
  @IsString()
  conversationId: string;

  @ApiPropertyOptional({ description: 'Last read message ID' })
  @IsOptional()
  @IsString()
  messageId?: string;
}

export class SocketOnlineStatusDto {
  @ApiProperty({ description: 'List of user IDs to check' })
  @IsString({ each: true })
  userIds: string[];
}

// ==================== API Request DTOs ====================

export class SendFirstMessageDto {
  @ApiProperty({ description: 'User ID of the recipient' })
  @IsString()
  participantId: string;

  @ApiProperty({ description: 'First message content' })
  @IsString()
  @MaxLength(2000)
  message: string;
}

export class SearchMessagesDto {
  @ApiProperty({ description: 'Search query' })
  @IsString()
  query: string;

  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ example: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  limit?: number;
}

export class ToggleMuteDto {
  @ApiProperty({ description: 'Mute status' })
  @IsBoolean()
  muted: boolean;
}
