import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ApiResponseDto<T = any> {
  @ApiProperty({ default: true })
  success: boolean;

  @ApiPropertyOptional()
  message?: string;

  @ApiPropertyOptional()
  data?: T;

  @ApiPropertyOptional()
  error?: any;

  @ApiPropertyOptional()
  timestamp?: string;

  constructor(partial: Partial<ApiResponseDto<T>>) {
    Object.assign(this, {
      ...partial,
      timestamp: new Date().toISOString(),
    });
  }

  static success<T>(data?: T, message?: string): ApiResponseDto<T> {
    return new ApiResponseDto({
      success: true,
      message,
      data,
    });
  }

  static error(message: string, error?: any): ApiResponseDto {
    return new ApiResponseDto({
      success: false,
      message,
      error,
    });
  }
}

export class ErrorResponseDto {
  @ApiProperty({ default: false })
  success: boolean;

  @ApiProperty()
  message: string;

  @ApiPropertyOptional()
  error?: string;

  @ApiProperty()
  statusCode: number;

  @ApiProperty()
  timestamp: string;

  @ApiPropertyOptional()
  path?: string;
}
