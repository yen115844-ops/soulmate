import { Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { ThrottlerModuleOptions } from '@nestjs/throttler';
import {
    InjectThrottlerOptions,
    InjectThrottlerStorage,
    ThrottlerGuard,
    ThrottlerStorage,
} from '@nestjs/throttler';

/**
 * Rate limit được tính theo từng "người" (identity):
 * - Đã đăng nhập (có JWT hợp lệ): theo userId (req.user.id)
 * - Chưa đăng nhập / route public (login, register): theo IP (req.ip)
 *
 * Key mặc định: hash(Controller-Handler-ThrottlerName-Tracker)
 * → Mỗi endpoint có bucket riêng cho mỗi identity (100 req/phút/endpoint/user).
 *
 * Ba throttler áp dụng đồng thời (phải thỏa cả 3):
 * - short: 3 req/giây (burst)
 * - medium: 20 req/10 giây
 * - long: 100 req/phút
 */
@Injectable()
export class ThrottlerUserGuard extends ThrottlerGuard {
  constructor(
    @InjectThrottlerOptions() options: ThrottlerModuleOptions,
    @InjectThrottlerStorage() storage: ThrottlerStorage,
    reflector: Reflector,
  ) {
    super(options, storage, reflector);
  }

  protected async getTracker(req: Record<string, any>): Promise<string> {
    const user = req.user as { id?: string } | undefined;
    if (user?.id) {
      return String(user.id);
    }
    return req.ip ?? 'unknown';
  }
}
