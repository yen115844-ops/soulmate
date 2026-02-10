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
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service';

// ==================== EVENTS ====================

// Events from client
export const CHAT_CLIENT_EVENTS = {
  // Connection
  AUTHENTICATE: 'chat:authenticate',
  
  // Conversation
  JOIN_CONVERSATION: 'chat:join_conversation',
  LEAVE_CONVERSATION: 'chat:leave_conversation',
  
  // Messages
  SEND_MESSAGE: 'chat:send_message',
  
  // Typing
  TYPING_START: 'chat:typing_start',
  TYPING_STOP: 'chat:typing_stop',
  
  // Read receipts
  MARK_READ: 'chat:mark_read',
  
  // Online status
  GET_ONLINE_STATUS: 'chat:get_online_status',
};

// Events to client
export const CHAT_SERVER_EVENTS = {
  // Connection
  AUTHENTICATED: 'chat:authenticated',
  ERROR: 'chat:error',
  
  // Conversation
  JOINED_CONVERSATION: 'chat:joined_conversation',
  LEFT_CONVERSATION: 'chat:left_conversation',
  
  // Messages
  NEW_MESSAGE: 'chat:new_message',
  MESSAGE_SENT: 'chat:message_sent',
  MESSAGE_DELIVERED: 'chat:message_delivered',
  
  // Typing
  USER_TYPING: 'chat:user_typing',
  USER_STOPPED_TYPING: 'chat:user_stopped_typing',
  
  // Read receipts
  MESSAGE_READ: 'chat:message_read',
  MESSAGES_READ: 'chat:messages_read',
  
  // Online status
  USER_ONLINE: 'chat:user_online',
  USER_OFFLINE: 'chat:user_offline',
  ONLINE_STATUS: 'chat:online_status',
  
  // Conversation updates
  CONVERSATION_UPDATED: 'chat:conversation_updated',
  
  // Block events
  USER_BLOCKED: 'chat:user_blocked',
  USER_UNBLOCKED: 'chat:user_unblocked',
};

// ==================== INTERFACES ====================

interface AuthenticatePayload {
  token: string;
  userId: string;
}

interface JoinConversationPayload {
  conversationId: string;
}

interface SendMessagePayload {
  conversationId: string;
  content: string;
  type?: 'text' | 'image' | 'voice' | 'location';
  tempId?: string; // Client-side temporary ID for optimistic UI
  mediaUrl?: string;
  location?: {
    lat: number;
    lng: number;
    address?: string;
  };
}

interface TypingPayload {
  conversationId: string;
}

interface MarkReadPayload {
  conversationId: string;
  messageId?: string; // Last read message ID
}

interface GetOnlineStatusPayload {
  userIds: string[];
}

interface SocketWithUser extends Socket {
  userId?: string;
  conversationRooms?: Set<string>;
}

// ==================== GATEWAY ====================

@WebSocketGateway({
  namespace: '/chat',
  cors: {
    origin: '*',
    credentials: true,
  },
  transports: ['websocket', 'polling'],
})
export class ChatGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  private readonly logger = new Logger(ChatGateway.name);
  
  // Track online users: userId -> Set<socketId>
  private onlineUsers: Map<string, Set<string>> = new Map();
  
  // Track socket to user mapping: socketId -> userId
  private socketToUser: Map<string, string> = new Map();
  
  // Track typing users per conversation: conversationId -> Set<userId>
  private typingUsers: Map<string, Set<string>> = new Map();
  
  // Typing timeout handles: `${conversationId}:${userId}` -> timeout
  private typingTimeouts: Map<string, NodeJS.Timeout> = new Map();

  @WebSocketServer()
  server: Server;

  constructor(private readonly chatService: ChatService) {}

  // ==================== LIFECYCLE ====================

  afterInit(server: Server) {
    this.logger.log('Chat WebSocket Gateway initialized');
  }

  handleConnection(client: SocketWithUser) {
    this.logger.debug(`Client connecting: ${client.id}`);
    client.conversationRooms = new Set();
  }

  handleDisconnect(client: SocketWithUser) {
    this.logger.debug(`Client disconnected: ${client.id}`);
    
    const userId = this.socketToUser.get(client.id);
    if (userId) {
      // Remove socket from user's socket set
      const userSockets = this.onlineUsers.get(userId);
      if (userSockets) {
        userSockets.delete(client.id);
        
        // If no more sockets, user is offline
        if (userSockets.size === 0) {
          this.onlineUsers.delete(userId);
          // Sync with ChatService for API calls
          this.chatService.setUserOnline(userId, false);
          this.broadcastUserOffline(userId);
        }
      }
      
      // Clean up socket mapping
      this.socketToUser.delete(client.id);
      
      // Clear typing status for this user in all conversations
      this.clearUserTypingInAllConversations(userId);
    }
    
    // Leave all conversation rooms
    if (client.conversationRooms) {
      client.conversationRooms.forEach((room) => {
        client.leave(room);
      });
    }
  }

  // ==================== AUTHENTICATION ====================

  @SubscribeMessage(CHAT_CLIENT_EVENTS.AUTHENTICATE)
  async handleAuthenticate(
    @ConnectedSocket() client: SocketWithUser,
    @MessageBody() payload: AuthenticatePayload,
  ) {
    try {
      const { userId, token } = payload;
      
      // TODO: Validate JWT token
      // For now, we trust the userId from payload
      // In production, verify token and extract userId from it
      
      if (!userId) {
        return { success: false, error: 'User ID is required' };
      }
      
      // Store user info on socket
      client.userId = userId;
      this.socketToUser.set(client.id, userId);
      
      // Add to online users
      if (!this.onlineUsers.has(userId)) {
        this.onlineUsers.set(userId, new Set());
      }
      this.onlineUsers.get(userId)!.add(client.id);
      
      // Sync with ChatService for API calls
      this.chatService.setUserOnline(userId, true);
      
      // Join user's personal room for direct notifications
      client.join(`user:${userId}`);
      
      // Broadcast online status to others
      this.broadcastUserOnline(userId);
      
      // Send current online users to the newly connected user
      const currentOnlineUsers = this.getOnlineUserIds();
      client.emit(CHAT_SERVER_EVENTS.ONLINE_STATUS, {
        onlineUsers: currentOnlineUsers.reduce((acc, id) => {
          acc[id] = true;
          return acc;
        }, {} as Record<string, boolean>),
      });
      
      this.logger.debug(`User ${userId} authenticated with socket ${client.id}`);
      
      return { 
        success: true, 
        event: CHAT_SERVER_EVENTS.AUTHENTICATED,
        userId,
        onlineUsers: currentOnlineUsers,
      };
    } catch (error) {
      this.logger.error(`Authentication error: ${error.message}`);
      return { success: false, error: 'Authentication failed' };
    }
  }

  // ==================== CONVERSATION ====================

  @SubscribeMessage(CHAT_CLIENT_EVENTS.JOIN_CONVERSATION)
  async handleJoinConversation(
    @ConnectedSocket() client: SocketWithUser,
    @MessageBody() payload: JoinConversationPayload,
  ) {
    try {
      const userId = client.userId;
      if (!userId) {
        return { success: false, error: 'Not authenticated' };
      }
      
      const { conversationId } = payload;
      
      // Verify user is participant of this conversation
      const isParticipant = await this.chatService.isConversationParticipant(
        conversationId,
        userId,
      );
      
      if (!isParticipant) {
        return { success: false, error: 'Not a participant of this conversation' };
      }
      
      // Join conversation room
      const roomName = this.getConversationRoom(conversationId);
      client.join(roomName);
      client.conversationRooms?.add(roomName);
      
      // Mark messages as delivered when user joins
      await this.chatService.markMessagesAsDelivered(conversationId, userId);
      
      this.logger.debug(`User ${userId} joined conversation ${conversationId}`);
      
      // Notify other participants that user is in the chat
      client.to(roomName).emit(CHAT_SERVER_EVENTS.USER_ONLINE, {
        conversationId,
        userId,
        timestamp: new Date().toISOString(),
      });
      
      return { 
        success: true, 
        event: CHAT_SERVER_EVENTS.JOINED_CONVERSATION,
        conversationId,
      };
    } catch (error) {
      this.logger.error(`Join conversation error: ${error.message}`);
      return { success: false, error: 'Failed to join conversation' };
    }
  }

  @SubscribeMessage(CHAT_CLIENT_EVENTS.LEAVE_CONVERSATION)
  handleLeaveConversation(
    @ConnectedSocket() client: SocketWithUser,
    @MessageBody() payload: JoinConversationPayload,
  ) {
    const userId = client.userId;
    if (!userId) {
      return { success: false, error: 'Not authenticated' };
    }
    
    const { conversationId } = payload;
    const roomName = this.getConversationRoom(conversationId);
    
    client.leave(roomName);
    client.conversationRooms?.delete(roomName);
    
    // Clear typing status
    this.clearUserTyping(conversationId, userId);
    
    this.logger.debug(`User ${userId} left conversation ${conversationId}`);
    
    return { 
      success: true, 
      event: CHAT_SERVER_EVENTS.LEFT_CONVERSATION,
      conversationId,
    };
  }

  // ==================== MESSAGES ====================

  @SubscribeMessage(CHAT_CLIENT_EVENTS.SEND_MESSAGE)
  async handleSendMessage(
    @ConnectedSocket() client: SocketWithUser,
    @MessageBody() payload: SendMessagePayload,
  ) {
    try {
      const userId = client.userId;
      if (!userId) {
        return { success: false, error: 'Not authenticated' };
      }
      
      const { conversationId, content, type = 'text', tempId, mediaUrl, location } = payload;
      
      // Clear typing status when sending message
      this.clearUserTyping(conversationId, userId);
      
      // Save message via service
      const message = await this.chatService.sendMessage(userId, conversationId, {
        content,
        type,
        mediaUrl,
        location,
      });
      
      // Broadcast message to all participants in conversation
      const roomName = this.getConversationRoom(conversationId);
      this.server.to(roomName).emit(CHAT_SERVER_EVENTS.NEW_MESSAGE, {
        message: {
          id: message.id,
          conversationId,
          senderId: message.senderId,
          sender: message.sender,
          content: message.content,
          type: message.type,
          status: message.status,
          mediaUrl: message.mediaUrl,
          createdAt: message.createdAt,
        },
        tempId, // Return tempId so client can match optimistic update
      });
      
      // Send delivered status to online recipients
      await this.notifyMessageDelivered(conversationId, message.id, userId);
      
      this.logger.debug(`Message sent in conversation ${conversationId} by user ${userId}`);
      
      return { 
        success: true, 
        event: CHAT_SERVER_EVENTS.MESSAGE_SENT,
        message: {
          id: message.id,
          tempId,
          status: message.status,
          createdAt: message.createdAt,
        },
      };
    } catch (error) {
      this.logger.error(`Send message error: ${error.message}`);
      // Return specific error message for blocked users
      if (error.message?.includes('Không thể nhắn tin')) {
        return { success: false, error: error.message };
      }
      return { success: false, error: 'Failed to send message' };
    }
  }

  // ==================== TYPING ====================

  @SubscribeMessage(CHAT_CLIENT_EVENTS.TYPING_START)
  handleTypingStart(
    @ConnectedSocket() client: SocketWithUser,
    @MessageBody() payload: TypingPayload,
  ) {
    const userId = client.userId;
    if (!userId) {
      return { success: false, error: 'Not authenticated' };
    }
    
    const { conversationId } = payload;
    const roomName = this.getConversationRoom(conversationId);
    
    // Track typing user
    if (!this.typingUsers.has(conversationId)) {
      this.typingUsers.set(conversationId, new Set());
    }
    this.typingUsers.get(conversationId)!.add(userId);
    
    // Broadcast typing to other participants
    client.to(roomName).emit(CHAT_SERVER_EVENTS.USER_TYPING, {
      conversationId,
      userId,
      timestamp: new Date().toISOString(),
    });
    
    // Auto-clear typing after 5 seconds
    const timeoutKey = `${conversationId}:${userId}`;
    if (this.typingTimeouts.has(timeoutKey)) {
      clearTimeout(this.typingTimeouts.get(timeoutKey)!);
    }
    
    this.typingTimeouts.set(
      timeoutKey,
      setTimeout(() => {
        this.clearUserTyping(conversationId, userId);
        client.to(roomName).emit(CHAT_SERVER_EVENTS.USER_STOPPED_TYPING, {
          conversationId,
          userId,
        });
      }, 5000),
    );
    
    return { success: true };
  }

  @SubscribeMessage(CHAT_CLIENT_EVENTS.TYPING_STOP)
  handleTypingStop(
    @ConnectedSocket() client: SocketWithUser,
    @MessageBody() payload: TypingPayload,
  ) {
    const userId = client.userId;
    if (!userId) {
      return { success: false, error: 'Not authenticated' };
    }
    
    const { conversationId } = payload;
    
    this.clearUserTyping(conversationId, userId);
    
    // Broadcast stop typing
    const roomName = this.getConversationRoom(conversationId);
    client.to(roomName).emit(CHAT_SERVER_EVENTS.USER_STOPPED_TYPING, {
      conversationId,
      userId,
    });
    
    return { success: true };
  }

  // ==================== READ RECEIPTS ====================

  @SubscribeMessage(CHAT_CLIENT_EVENTS.MARK_READ)
  async handleMarkRead(
    @ConnectedSocket() client: SocketWithUser,
    @MessageBody() payload: MarkReadPayload,
  ) {
    try {
      const userId = client.userId;
      if (!userId) {
        return { success: false, error: 'Not authenticated' };
      }
      
      const { conversationId, messageId } = payload;
      
      // Mark messages as read in database
      await this.chatService.markMessagesAsRead(userId, conversationId);
      
      // Broadcast read receipt to sender(s)
      const roomName = this.getConversationRoom(conversationId);
      client.to(roomName).emit(CHAT_SERVER_EVENTS.MESSAGES_READ, {
        conversationId,
        readBy: userId,
        lastReadMessageId: messageId,
        readAt: new Date().toISOString(),
      });
      
      return { success: true };
    } catch (error) {
      this.logger.error(`Mark read error: ${error.message}`);
      return { success: false, error: 'Failed to mark as read' };
    }
  }

  // ==================== ONLINE STATUS ====================

  @SubscribeMessage(CHAT_CLIENT_EVENTS.GET_ONLINE_STATUS)
  handleGetOnlineStatus(
    @ConnectedSocket() client: SocketWithUser,
    @MessageBody() payload: GetOnlineStatusPayload,
  ) {
    const { userIds } = payload;
    
    const onlineStatus: Record<string, boolean> = {};
    for (const userId of userIds) {
      onlineStatus[userId] = this.isUserOnline(userId);
    }
    
    return {
      success: true,
      event: CHAT_SERVER_EVENTS.ONLINE_STATUS,
      onlineStatus,
    };
  }

  // ==================== PUBLIC METHODS (Called from Service) ====================

  /**
   * Emit new message to conversation participants (from REST API)
   * Also emits to user rooms for participants not in the conversation room
   * @param senderId - The sender's user ID to exclude from notifications
   */
  async emitNewMessage(conversationId: string, message: any, senderId?: string) {
    const roomName = this.getConversationRoom(conversationId);
    
    // Get participants first to notify them individually (not sender)
    // This avoids sending duplicate to sender who already got the message from API response
    try {
      const participants = await this.chatService.getConversationParticipants(conversationId);
      for (const participant of participants) {
        // Skip sender - they already got the message from REST API response
        if (senderId && participant.userId === senderId) {
          continue;
        }
        // Emit to user's personal room (for participants not in conversation room)
        this.server.to(`user:${participant.userId}`).emit(CHAT_SERVER_EVENTS.NEW_MESSAGE, { 
          message,
          conversationId,
        });
      }
      
      // Also emit to conversation room for users who have joined
      // But exclude sender's sockets
      if (senderId) {
        const senderSockets = this.onlineUsers.get(senderId);
        if (senderSockets) {
          // Use except() to exclude sender's sockets from room broadcast
          this.server.to(roomName).except([...senderSockets].map(s => s)).emit(CHAT_SERVER_EVENTS.NEW_MESSAGE, { 
            message,
            conversationId,
          });
        } else {
          // No sender sockets, just broadcast to room
          this.server.to(roomName).emit(CHAT_SERVER_EVENTS.NEW_MESSAGE, { message, conversationId });
        }
      } else {
        // No senderId provided, broadcast to all in room
        this.server.to(roomName).emit(CHAT_SERVER_EVENTS.NEW_MESSAGE, { message, conversationId });
      }
    } catch (error) {
      this.logger.error(`Failed to notify participants: ${error.message}`);
    }
  }

  /**
   * Emit conversation update (new conversation, updated preview, etc)
   */
  emitConversationUpdate(userId: string, conversation: any) {
    this.server.to(`user:${userId}`).emit(CHAT_SERVER_EVENTS.CONVERSATION_UPDATED, {
      conversation,
    });
  }

  /**
   * Emit user blocked event to both users
   * This allows real-time removal of conversation from lists
   */
  emitUserBlocked(blockerId: string, blockedId: string) {
    // Notify the blocked user
    this.server.to(`user:${blockedId}`).emit(CHAT_SERVER_EVENTS.USER_BLOCKED, {
      blockedBy: blockerId,
      action: 'blocked',
    });
    
    // Also notify the blocker (in case they have multiple devices)
    this.server.to(`user:${blockerId}`).emit(CHAT_SERVER_EVENTS.USER_BLOCKED, {
      blockedUserId: blockedId,
      action: 'you_blocked',
    });
    
    this.logger.debug(`User ${blockerId} blocked user ${blockedId} - notified both parties`);
  }

  /**
   * Emit user unblocked event to both users
   */
  emitUserUnblocked(unblockerId: string, unblockedId: string) {
    // Notify the unblocked user
    this.server.to(`user:${unblockedId}`).emit(CHAT_SERVER_EVENTS.USER_UNBLOCKED, {
      unblockedBy: unblockerId,
      action: 'unblocked',
    });
    
    // Also notify the unblocker
    this.server.to(`user:${unblockerId}`).emit(CHAT_SERVER_EVENTS.USER_UNBLOCKED, {
      unblockedUserId: unblockedId,
      action: 'you_unblocked',
    });
    
    this.logger.debug(`User ${unblockerId} unblocked user ${unblockedId} - notified both parties`);
  }

  /**
   * Check if user is online
   */
  isUserOnline(userId: string): boolean {
    const sockets = this.onlineUsers.get(userId);
    return sockets !== undefined && sockets.size > 0;
  }

  /**
   * Get online user IDs
   */
  getOnlineUserIds(): string[] {
    return Array.from(this.onlineUsers.keys());
  }

  // ==================== PRIVATE HELPERS ====================

  private getConversationRoom(conversationId: string): string {
    return `conversation:${conversationId}`;
  }

  private broadcastUserOnline(userId: string) {
    // Broadcast to all connected clients that this user is online
    this.server.emit(CHAT_SERVER_EVENTS.USER_ONLINE, {
      userId,
      timestamp: new Date().toISOString(),
    });
  }

  private broadcastUserOffline(userId: string) {
    this.server.emit(CHAT_SERVER_EVENTS.USER_OFFLINE, {
      userId,
      timestamp: new Date().toISOString(),
    });
  }

  private clearUserTyping(conversationId: string, userId: string) {
    const typingSet = this.typingUsers.get(conversationId);
    if (typingSet) {
      typingSet.delete(userId);
      if (typingSet.size === 0) {
        this.typingUsers.delete(conversationId);
      }
    }
    
    const timeoutKey = `${conversationId}:${userId}`;
    if (this.typingTimeouts.has(timeoutKey)) {
      clearTimeout(this.typingTimeouts.get(timeoutKey)!);
      this.typingTimeouts.delete(timeoutKey);
    }
  }

  private clearUserTypingInAllConversations(userId: string) {
    this.typingUsers.forEach((typingSet, conversationId) => {
      if (typingSet.has(userId)) {
        typingSet.delete(userId);
        
        // Broadcast stop typing
        const roomName = this.getConversationRoom(conversationId);
        this.server.to(roomName).emit(CHAT_SERVER_EVENTS.USER_STOPPED_TYPING, {
          conversationId,
          userId,
        });
      }
    });
    
    // Clear timeouts
    this.typingTimeouts.forEach((timeout, key) => {
      if (key.endsWith(`:${userId}`)) {
        clearTimeout(timeout);
        this.typingTimeouts.delete(key);
      }
    });
  }

  private async notifyMessageDelivered(
    conversationId: string,
    messageId: string,
    senderId: string,
  ) {
    // Get other participants in conversation who are online
    const participants = await this.chatService.getConversationParticipants(conversationId);
    
    const onlineRecipients = participants
      .filter((p) => p.userId !== senderId && this.isUserOnline(p.userId))
      .map((p) => p.userId);
    
    if (onlineRecipients.length > 0) {
      // Update message status to delivered
      await this.chatService.updateMessageStatus(messageId, 'DELIVERED');
      
      // Notify sender that message was delivered
      this.server.to(`user:${senderId}`).emit(CHAT_SERVER_EVENTS.MESSAGE_DELIVERED, {
        conversationId,
        messageId,
        deliveredTo: onlineRecipients,
        deliveredAt: new Date().toISOString(),
      });
    }
  }
}
