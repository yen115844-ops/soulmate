import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

@Catch(HttpException)
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: HttpException, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    const status = exception.getStatus();

    const exceptionResponse = exception.getResponse();
    const error =
      typeof exceptionResponse === 'string'
        ? { message: exceptionResponse }
        : exceptionResponse;

    const errorResponse = {
      success: false,
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: request.url,
      method: request.method,
      ...error,
      ...(status === HttpStatus.PAYLOAD_TOO_LARGE
        ? this.buildUploadMeta(request)
        : {}),
    };

    this.logger.error(
      `${request.method} ${request.url} ${status}`,
      JSON.stringify(errorResponse),
    );

    response.status(status).json(errorResponse);
  }

  private buildUploadMeta(request: Request) {
    const contentLengthRaw = request.headers['content-length'];
    const contentLength = Number.parseInt(String(contentLengthRaw ?? '0'), 10);
    const contentLengthMb =
      Number.isFinite(contentLength) && contentLength > 0
        ? Number((contentLength / (1024 * 1024)).toFixed(2))
        : null;

    return {
      upload: {
        contentType: request.headers['content-type'] ?? null,
        contentLengthBytes: contentLength > 0 ? contentLength : null,
        contentLengthMb,
        configuredLimitMb: this.resolveConfiguredLimitMb(request.url),
      },
    };
  }

  private resolveConfiguredLimitMb(url: string): number | null {
    if (url.includes('/users/profile/avatar')) return 10;
    if (url.includes('/verification/submit-selfie')) return 10;
    if (url.includes('/upload/image') || url.includes('/upload/images'))
      return 10;
    return null;
  }
}

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const message =
      exception instanceof HttpException
        ? exception.message
        : 'Internal server error';

    const errorResponse = {
      success: false,
      statusCode: status,
      message,
      timestamp: new Date().toISOString(),
      path: request.url,
      method: request.method,
    };

    this.logger.error(
      `${request.method} ${request.url} ${status}`,
      exception instanceof Error ? exception.stack : String(exception),
    );

    response.status(status).json(errorResponse);
  }
}
