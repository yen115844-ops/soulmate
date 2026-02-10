import { ExecutionContext, Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

/**
 * Optional JWT Authentication Guard
 * Unlike JwtAuthGuard, this guard will:
 * - Attach user to request if valid token is present
 * - Allow request to continue even without token (user will be undefined)
 */
@Injectable()
export class OptionalJwtAuthGuard extends AuthGuard('jwt') {
  canActivate(context: ExecutionContext) {
    // Always try to authenticate, but don't block if it fails
    return super.canActivate(context);
  }

  handleRequest<TUser = any>(
    err: any,
    user: TUser,
    _info: any,
    _context: ExecutionContext,
  ): TUser | undefined {
    // If there's an error or no user, just return undefined instead of throwing
    // This allows the request to continue without authentication
    if (err || !user) {
      return undefined as any;
    }
    return user;
  }
}
