import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export enum DevicePlatform {
  IOS = 'ios',
  ANDROID = 'android',
  WEB = 'web',
}

export class RegisterDeviceDto {
  @ApiProperty({
    description: 'FCM device token',
    example: 'fMhKxR8rQ8...',
  })
  @IsString()
  @IsNotEmpty()
  token: string;

  @ApiProperty({
    description: 'Device platform',
    enum: DevicePlatform,
    example: DevicePlatform.IOS,
  })
  @IsEnum(DevicePlatform)
  @IsNotEmpty()
  platform: DevicePlatform;

  @ApiPropertyOptional({
    description: 'Device information (model, OS version, etc.)',
    example: 'iPhone 15 Pro, iOS 17.2',
  })
  @IsString()
  @IsOptional()
  deviceInfo?: string;
}

export class UnregisterDeviceDto {
  @ApiProperty({
    description: 'FCM device token to remove',
    example: 'fMhKxR8rQ8...',
  })
  @IsString()
  @IsNotEmpty()
  token: string;
}
