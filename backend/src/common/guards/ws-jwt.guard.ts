import { CanActivate, ExecutionContext, Injectable, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Socket } from 'socket.io';

@Injectable()
export class WsJwtGuard implements CanActivate {
  private readonly logger = new Logger(WsJwtGuard.name);

  constructor(private readonly jwtService: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    try {
      const client: Socket = context.switchToWs().getClient();
      const token = this.extractToken(client);

      if (!token) {
        this.logger.warn('No token provided in WebSocket connection');
        return false;
      }

      const payload = await this.jwtService.verifyAsync(token);
      
      // Attach user info to socket
      (client as any).userId = payload.sub;
      (client as any).user = payload;

      return true;
    } catch (error) {
      this.logger.error(`WebSocket auth error: ${error.message}`);
      return false;
    }
  }

  private extractToken(client: Socket): string | null {
    // Try to get token from auth object
    const authToken = client.handshake?.auth?.token;
    if (authToken) {
      return authToken;
    }

    // Try to get token from headers
    const authHeader = client.handshake?.headers?.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7);
    }

    // Try to get token from query params
    const queryToken = client.handshake?.query?.token;
    if (queryToken) {
      return Array.isArray(queryToken) ? queryToken[0] : queryToken;
    }

    return null;
  }
}
