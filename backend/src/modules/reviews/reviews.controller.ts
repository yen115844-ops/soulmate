import {
    Body,
    Controller,
    Delete,
    Get,
    HttpCode,
    HttpStatus,
    Param,
    Patch,
    Post,
    Query,
    UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import {
    CreateReviewDto,
    CreateReviewResponseDto,
    QueryReviewsDto,
    UpdateReviewDto,
} from './dto';
import { ReviewsService } from './reviews.service';

@ApiTags('Reviews')
@Controller('reviews')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a review for a booking' })
  @ApiResponse({ status: 201, description: 'Review created' })
  @ApiResponse({ status: 400, description: 'Booking not completed' })
  @ApiResponse({ status: 409, description: 'Already reviewed' })
  async createReview(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateReviewDto,
  ) {
    return this.reviewsService.createReview(userId, dto);
  }

  @Get('received')
  @ApiOperation({ summary: 'Get reviews I received' })
  @ApiResponse({ status: 200, description: 'Reviews list' })
  async getReviewsReceived(
    @CurrentUser('id') userId: string,
    @Query() dto: QueryReviewsDto,
  ) {
    return this.reviewsService.getReviewsReceived(userId, dto);
  }

  @Get('given')
  @ApiOperation({ summary: 'Get reviews I gave' })
  @ApiResponse({ status: 200, description: 'Reviews list' })
  async getReviewsGiven(
    @CurrentUser('id') userId: string,
    @Query() dto: QueryReviewsDto,
  ) {
    return this.reviewsService.getReviewsGiven(userId, dto);
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get my review statistics' })
  @ApiResponse({ status: 200, description: 'Review stats' })
  async getMyReviewStats(@CurrentUser('id') userId: string) {
    return this.reviewsService.getReviewStats(userId);
  }

  @Public()
  @Get('user/:userId/stats')
  @ApiOperation({ summary: 'Get review statistics for a user (public)' })
  @ApiResponse({ status: 200, description: 'Review stats' })
  async getUserReviewStats(@Param('userId') userId: string) {
    return this.reviewsService.getReviewStats(userId);
  }

  @Public()
  @Get('user/:userId')
  @ApiOperation({ summary: 'Get reviews for a specific user (public)' })
  @ApiResponse({ status: 200, description: 'Reviews list' })
  async getUserReviews(
    @Param('userId') userId: string,
    @Query() dto: QueryReviewsDto,
  ) {
    return this.reviewsService.getReviewsReceived(userId, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update my review' })
  @ApiResponse({ status: 200, description: 'Review updated' })
  @ApiResponse({ status: 400, description: 'Update window expired' })
  async updateReview(
    @CurrentUser('id') userId: string,
    @Param('id') reviewId: string,
    @Body() dto: UpdateReviewDto,
  ) {
    return this.reviewsService.updateReview(userId, reviewId, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete my review' })
  @ApiResponse({ status: 200, description: 'Review deleted' })
  async deleteReview(
    @CurrentUser('id') userId: string,
    @Param('id') reviewId: string,
  ) {
    return this.reviewsService.deleteReview(userId, reviewId);
  }

  @Post(':id/response')
  @ApiOperation({ summary: 'Respond to a review' })
  @ApiResponse({ status: 201, description: 'Response created' })
  @ApiResponse({ status: 409, description: 'Response already exists' })
  async createResponse(
    @CurrentUser('id') userId: string,
    @Param('id') reviewId: string,
    @Body() dto: CreateReviewResponseDto,
  ) {
    return this.reviewsService.createReviewResponse(userId, reviewId, dto);
  }
}
