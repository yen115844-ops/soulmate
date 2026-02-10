import {
    Body,
    Controller,
    Delete,
    Get,
    Param,
    Post,
    Put,
    Query,
    UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { ChatGateway } from './chat.gateway';
import { ChatService } from './chat.service';
import {
    CreateConversationDto,
    QueryConversationsDto,
    QueryMessagesDto,
    SearchMessagesDto,
    SendFirstMessageDto,
    SendMessageDto,
    ToggleMuteDto,
} from './dto';

@ApiTags('Chat')
@Controller('chat')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ChatController {
  constructor(
    private readonly chatService: ChatService,
    private readonly chatGateway: ChatGateway,
  ) {}

  @Get('conversations')
  @ApiOperation({ summary: 'Get all conversations for current user' })
  @ApiResponse({ status: 200, description: 'Conversations retrieved' })
  async getConversations(
    @CurrentUser('id') userId: string,
    @Query() dto: QueryConversationsDto,
  ) {
    return this.chatService.getConversations(userId, dto);
  }

  @Post('conversations')
  @ApiOperation({ summary: 'Get or create a conversation with another user (creates only if initialMessage provided)' })
  @ApiResponse({ status: 200, description: 'Conversation retrieved or created' })
  @ApiResponse({ status: 404, description: 'User not found' })
  async getOrCreateConversation(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateConversationDto,
  ) {
    return this.chatService.getOrCreateConversation(userId, dto);
  }

  @Get('conversations/find/:participantId')
  @ApiOperation({ summary: 'Find existing conversation with a user (does not create new one)' })
  @ApiResponse({ status: 200, description: 'Conversation found or virtual conversation info' })
  @ApiResponse({ status: 404, description: 'User not found' })
  async findConversation(
    @CurrentUser('id') userId: string,
    @Param('participantId') participantId: string,
  ) {
    return this.chatService.findConversation(userId, participantId);
  }

  @Post('conversations/send-first')
  @ApiOperation({ summary: 'Create conversation and send first message (atomic operation)' })
  @ApiResponse({ status: 201, description: 'Conversation created and message sent' })
  @ApiResponse({ status: 404, description: 'User not found' })
  async sendFirstMessage(
    @CurrentUser('id') userId: string,
    @Body() dto: SendFirstMessageDto,
  ) {
    const result = await this.chatService.createConversationWithMessage(
      userId,
      dto.participantId,
      dto.message,
    );
    
    // Emit socket event to notify the other participant (not sender)
    await this.chatGateway.emitNewMessage(result.conversation.id, {
      id: result.message.id,
      conversationId: result.conversation.id,
      senderId: result.message.senderId,
      sender: result.message.sender,
      content: result.message.content,
      type: result.message.type,
      status: result.message.status,
      createdAt: result.message.createdAt,
    }, userId);
    
    // Also notify both users about new conversation
    this.chatGateway.emitConversationUpdate(userId, result.conversation);
    this.chatGateway.emitConversationUpdate(dto.participantId, result.conversation);
    
    return result;
  }

  @Get('conversations/:conversationId')
  @ApiOperation({ summary: 'Get conversation by ID' })
  @ApiResponse({ status: 200, description: 'Conversation retrieved' })
  @ApiResponse({ status: 404, description: 'Conversation not found' })
  async getConversationById(
    @CurrentUser('id') userId: string,
    @Param('conversationId') conversationId: string,
  ) {
    return this.chatService.getConversationById(conversationId, userId);
  }

  @Get('conversations/:conversationId/messages')
  @ApiOperation({ summary: 'Get messages for a conversation' })
  @ApiResponse({ status: 200, description: 'Messages retrieved' })
  @ApiResponse({ status: 404, description: 'Conversation not found' })
  async getMessages(
    @CurrentUser('id') userId: string,
    @Param('conversationId') conversationId: string,
    @Query() dto: QueryMessagesDto,
  ) {
    return this.chatService.getMessages(userId, conversationId, dto);
  }

  @Get('conversations/:conversationId/messages/search')
  @ApiOperation({ summary: 'Search messages in a conversation' })
  @ApiResponse({ status: 200, description: 'Search results retrieved' })
  @ApiResponse({ status: 404, description: 'Conversation not found' })
  async searchMessages(
    @CurrentUser('id') userId: string,
    @Param('conversationId') conversationId: string,
    @Query() dto: SearchMessagesDto,
  ) {
    return this.chatService.searchMessages(userId, conversationId, dto);
  }

  @Post('conversations/:conversationId/messages')
  @ApiOperation({ summary: 'Send a message in a conversation' })
  @ApiResponse({ status: 201, description: 'Message sent' })
  @ApiResponse({ status: 404, description: 'Conversation not found' })
  async sendMessage(
    @CurrentUser('id') userId: string,
    @Param('conversationId') conversationId: string,
    @Body() dto: SendMessageDto,
  ) {
    const message = await this.chatService.sendMessage(userId, conversationId, dto);
    
    // Emit socket event to notify other participants in real-time
    // Pass userId as senderId so sender doesn't receive duplicate
    await this.chatGateway.emitNewMessage(conversationId, {
      id: message.id,
      conversationId,
      senderId: message.senderId,
      sender: message.sender,
      content: message.content,
      type: message.type,
      status: message.status,
      mediaUrl: message.mediaUrl,
      createdAt: message.createdAt,
    }, userId);
    
    return message;
  }

  @Post('conversations/:conversationId/read')
  @ApiOperation({ summary: 'Mark all messages in conversation as read' })
  @ApiResponse({ status: 200, description: 'Messages marked as read' })
  async markAsRead(
    @CurrentUser('id') userId: string,
    @Param('conversationId') conversationId: string,
  ) {
    await this.chatService.markMessagesAsRead(userId, conversationId);
    return { success: true };
  }

  @Put('conversations/:conversationId/mute')
  @ApiOperation({ summary: 'Toggle mute for a conversation' })
  @ApiResponse({ status: 200, description: 'Mute status updated' })
  @ApiResponse({ status: 404, description: 'Conversation not found' })
  async toggleMute(
    @CurrentUser('id') userId: string,
    @Param('conversationId') conversationId: string,
    @Body() dto: ToggleMuteDto,
  ) {
    return this.chatService.toggleMuteConversation(userId, conversationId, dto.muted);
  }

  @Delete('conversations/:conversationId')
  @ApiOperation({ summary: 'Delete/remove conversation from list' })
  @ApiResponse({ status: 200, description: 'Conversation removed' })
  @ApiResponse({ status: 404, description: 'Conversation not found' })
  async deleteConversation(
    @CurrentUser('id') userId: string,
    @Param('conversationId') conversationId: string,
  ) {
    return this.chatService.leaveConversation(userId, conversationId);
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Get total unread message count' })
  @ApiResponse({ status: 200, description: 'Unread count retrieved' })
  async getUnreadCount(@CurrentUser('id') userId: string) {
    const count = await this.chatService.getUnreadCount(userId);
    return { unreadCount: count };
  }

  @Get('online-status')
  @ApiOperation({ summary: 'Get online status for users' })
  @ApiResponse({ status: 200, description: 'Online status retrieved' })
  async getOnlineStatus(
    @Query('userIds') userIdsStr: string,
  ) {
    const userIds = userIdsStr ? userIdsStr.split(',') : [];
    return this.chatService.getOnlineStatus(userIds);
  }
}
