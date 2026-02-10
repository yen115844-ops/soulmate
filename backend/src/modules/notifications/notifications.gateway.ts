import { Logger } from '@nestjs/common';
import {
    ConnectedSocket,
    MessageBody,
    OnGatewayConnection,
    OnGatewayDisconnect,
    OnGatewayInit,
    SubscribeMessage,
    WebSocketGateway,
    WebSocketServer,
} from '@nestjs/websockets';
import { Notification } from '@prisma/client';
import { Server, Socket } from 'socket.io';

// Events from client
export const NOTIFICATION_CLIENT_EVENTS = {
  SUBSCRIBE: 'notification:subscribe',
  UNSUBSCRIBE: 'notification:unsubscribe',
  MARK_READ: 'notification:mark-read',
};

// Events to client
export const NOTIFICATION_SERVER_EVENTS = {
  NEW_NOTIFICATION: 'notification:new',
  UNREAD_COUNT: 'notification:unread-count',
  MARKED_READ: 'notification:marked-read',
};

interface SubscribePayload {
  userId: string;
  token: string;
}

@WebSocketGateway({
  namespace: '/notifications',
  cors: {
    origin: '*',
    credentials: true,
  },
})
export class NotificationsGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  private readonly logger = new Logger(NotificationsGateway.name);
  private userSockets: Map<string, Set<string>> = new Map();

  @WebSocketServer()
  server: Server;

  afterInit(server: Server) {
    this.logger.log('Notifications WebSocket Gateway initialized');
  }

  handleConnection(client: Socket) {
    this.logger.debug(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.debug(`Client disconnected: ${client.id}`);
    
    // Remove client from all user rooms
    this.userSockets.forEach((sockets, userId) => {
      if (sockets.has(client.id)) {
        sockets.delete(client.id);
        if (sockets.size === 0) {
          this.userSockets.delete(userId);
        }
      }
    });
  }

  /**
   * Subscribe to user's notification channel
   */
  @SubscribeMessage(NOTIFICATION_CLIENT_EVENTS.SUBSCRIBE)
  handleSubscribe(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: SubscribePayload,
  ) {
    const { userId, token } = payload;

    // TODO: Validate token/user
    // For now, just join the room

    const roomName = this.getUserRoom(userId);
    client.join(roomName);

    // Track user's sockets
    if (!this.userSockets.has(userId)) {
      this.userSockets.set(userId, new Set());
    }
    this.userSockets.get(userId)!.add(client.id);

    this.logger.debug(`Client ${client.id} subscribed to user ${userId}`);

    return { success: true, room: roomName };
  }

  /**
   * Unsubscribe from user's notification channel
   */
  @SubscribeMessage(NOTIFICATION_CLIENT_EVENTS.UNSUBSCRIBE)
  handleUnsubscribe(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { userId: string },
  ) {
    const { userId } = payload;
    const roomName = this.getUserRoom(userId);
    
    client.leave(roomName);

    // Remove from tracking
    const sockets = this.userSockets.get(userId);
    if (sockets) {
      sockets.delete(client.id);
      if (sockets.size === 0) {
        this.userSockets.delete(userId);
      }
    }

    this.logger.debug(`Client ${client.id} unsubscribed from user ${userId}`);

    return { success: true };
  }

  /**
   * Emit new notification to user
   */
  emitNotification(userId: string, notification: Partial<Notification>) {
    const roomName = this.getUserRoom(userId);
    this.server.to(roomName).emit(NOTIFICATION_SERVER_EVENTS.NEW_NOTIFICATION, {
      notification: {
        id: notification.id,
        type: notification.type,
        title: notification.title,
        body: notification.body,
        imageUrl: notification.imageUrl,
        actionType: notification.actionType,
        actionId: notification.actionId,
        data: notification.data,
        isRead: notification.isRead,
        createdAt: notification.createdAt,
      },
    });

    this.logger.debug(`Emitted notification to user ${userId}`);
  }

  /**
   * Emit unread count update to user
   */
  emitUnreadCount(userId: string, unreadCount: number) {
    const roomName = this.getUserRoom(userId);
    this.server.to(roomName).emit(NOTIFICATION_SERVER_EVENTS.UNREAD_COUNT, {
      unreadCount,
    });
  }

  /**
   * Emit notification marked as read
   */
  emitMarkedRead(userId: string, notificationIds: string[]) {
    const roomName = this.getUserRoom(userId);
    this.server.to(roomName).emit(NOTIFICATION_SERVER_EVENTS.MARKED_READ, {
      notificationIds,
    });
  }

  /**
   * Check if user is connected
   */
  isUserConnected(userId: string): boolean {
    const sockets = this.userSockets.get(userId);
    return sockets !== undefined && sockets.size > 0;
  }

  /**
   * Get user room name
   */
  private getUserRoom(userId: string): string {
    return `user:${userId}:notifications`;
  }
}
