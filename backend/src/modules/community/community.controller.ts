import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import {
  CreateCommentDto,
  CreatePostDto,
  QueryCommentsDto,
  QueryCommunityFeedDto,
} from './dto';
import { CommunityService } from './community.service';

@ApiTags('Community')
@Controller('community')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class CommunityController {
  constructor(private readonly community: CommunityService) {}

  @Post('posts')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Đăng bài lên feed cộng đồng' })
  async createPost(
    @CurrentUser('id') userId: string,
    @Body() dto: CreatePostDto,
  ) {
    return this.community.createPost(userId, dto);
  }

  @Get('posts')
  @ApiOperation({ summary: 'Feed toàn cục (cursor), có likedByMe' })
  async listPosts(
    @CurrentUser('id') userId: string,
    @Query() query: QueryCommunityFeedDto,
  ) {
    return this.community.listFeed(userId, query);
  }

  @Get('posts/:postId')
  @ApiOperation({ summary: 'Chi tiết post (Redis cache payload + likedByMe)' })
  async getPost(
    @CurrentUser('id') userId: string,
    @Param('postId', ParseUUIDPipe) postId: string,
  ) {
    return this.community.getPostById(userId, postId);
  }

  @Delete('posts/:postId')
  @ApiOperation({ summary: 'Xóa mềm bài của chính mình' })
  async deletePost(
    @CurrentUser('id') userId: string,
    @Param('postId', ParseUUIDPipe) postId: string,
  ) {
    return this.community.deletePost(userId, postId);
  }

  @Post('posts/:postId/like')
  @ApiOperation({ summary: 'Toggle like (idempotent theo phiên làm việc)' })
  async toggleLike(
    @CurrentUser('id') userId: string,
    @Param('postId', ParseUUIDPipe) postId: string,
  ) {
    return this.community.toggleLike(userId, postId);
  }

  @Get('posts/:postId/comments')
  @ApiOperation({ summary: 'Danh sách comment (cursor)' })
  async listComments(
    @Param('postId', ParseUUIDPipe) postId: string,
    @Query() query: QueryCommentsDto,
  ) {
    return this.community.listComments(postId, query);
  }

  @Post('posts/:postId/comments')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Viết comment' })
  async createComment(
    @CurrentUser('id') userId: string,
    @Param('postId', ParseUUIDPipe) postId: string,
    @Body() dto: CreateCommentDto,
  ) {
    return this.community.addComment(userId, postId, dto);
  }
}
