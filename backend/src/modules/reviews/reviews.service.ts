import {
    BadRequestException,
    ConflictException,
    ForbiddenException,
    Injectable,
    Logger,
    NotFoundException,
} from '@nestjs/common';
import { BookingStatus } from '@prisma/client';
import { PrismaService } from '../../database/prisma/prisma.service';
import {
    CreateReviewDto,
    CreateReviewResponseDto,
    QueryReviewsDto,
    UpdateReviewDto,
} from './dto';

@Injectable()
export class ReviewsService {
  private readonly logger = new Logger(ReviewsService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a review for a booking
   */
  async createReview(userId: string, dto: CreateReviewDto) {
    // Check booking exists and is completed
    const booking = await this.prisma.booking.findUnique({
      where: { id: dto.bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.status !== BookingStatus.COMPLETED) {
      throw new BadRequestException('Can only review completed bookings');
    }

    // Determine reviewer and reviewee
    const isUser = booking.userId === userId;
    const isPartner = booking.partnerId === userId;

    if (!isUser && !isPartner) {
      throw new ForbiddenException('You are not part of this booking');
    }

    const reviewType = isUser ? 'user_to_partner' : 'partner_to_user';
    const revieweeId = isUser ? booking.partnerId : booking.userId;

    // Check if already reviewed
    const existingReview = await this.prisma.review.findFirst({
      where: {
        bookingId: dto.bookingId,
        reviewerId: userId,
      },
    });

    if (existingReview) {
      throw new ConflictException('You have already reviewed this booking');
    }

    // Create review
    const review = await this.prisma.review.create({
      data: {
        bookingId: dto.bookingId,
        reviewerId: userId,
        revieweeId,
        reviewType,
        overallRating: dto.overallRating,
        punctualityRating: dto.punctualityRating,
        communicationRating: dto.communicationRating,
        attitudeRating: dto.attitudeRating,
        appearanceRating: dto.appearanceRating,
        serviceQualityRating: dto.serviceQualityRating,
        comment: dto.comment,
        photoUrls: dto.photoUrls || [],
        tags: dto.tags || [],
        isAnonymous: dto.isAnonymous || false,
      },
      include: {
        reviewer: {
          include: {
            profile: {
              select: {
                fullName: true,
                displayName: true,
                avatarUrl: true,
              },
            },
          },
        },
      },
    });

    // Update partner profile stats if reviewing a partner
    if (reviewType === 'user_to_partner') {
      await this.updatePartnerReviewStats(revieweeId);
    }

    this.logger.log(`Review created: ${review.id}`);
    return review;
  }

  /**
   * Get reviews received by a user
   */
  async getReviewsReceived(userId: string, dto: QueryReviewsDto) {
    const { page = 1, limit = 10, minRating, sortBy = 'newest' } = dto;
    const skip = (page - 1) * limit;

    const where: any = {
      revieweeId: userId,
      isVisible: true,
    };

    if (minRating) {
      where.overallRating = { gte: minRating };
    }

    // Build order by
    let orderBy: any = { createdAt: 'desc' };
    if (sortBy === 'oldest') {
      orderBy = { createdAt: 'asc' };
    } else if (sortBy === 'highest') {
      orderBy = { overallRating: 'desc' };
    } else if (sortBy === 'lowest') {
      orderBy = { overallRating: 'asc' };
    }

    const [reviews, total] = await Promise.all([
      this.prisma.review.findMany({
        where,
        skip,
        take: limit,
        orderBy,
        include: {
          reviewer: {
            include: {
              profile: {
                select: {
                  fullName: true,
                  displayName: true,
                  avatarUrl: true,
                },
              },
            },
          },
          response: true,
        },
      }),
      this.prisma.review.count({ where }),
    ]);

    // Process anonymous reviews
    const processedReviews = reviews.map((review) => {
      if (review.isAnonymous) {
        return {
          ...review,
          reviewer: {
            id: 'anonymous',
            profile: {
              fullName: 'Người dùng ẩn danh',
              displayName: 'Ẩn danh',
              avatarUrl: null,
            },
          },
        };
      }
      return review;
    });

    const totalPages = Math.ceil(total / limit);

    return {
      data: processedReviews,
      meta: {
        total,
        page,
        limit,
        totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      },
    };
  }

  /**
   * Get reviews given by a user
   */
  async getReviewsGiven(userId: string, dto: QueryReviewsDto) {
    const { page = 1, limit = 10 } = dto;
    const skip = (page - 1) * limit;

    const [reviews, total] = await Promise.all([
      this.prisma.review.findMany({
        where: { reviewerId: userId },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          reviewee: {
            include: {
              profile: {
                select: {
                  fullName: true,
                  displayName: true,
                  avatarUrl: true,
                },
              },
            },
          },
          booking: true,
        },
      }),
      this.prisma.review.count({ where: { reviewerId: userId } }),
    ]);

    const totalPages = Math.ceil(total / limit);

    return {
      data: reviews,
      meta: {
        total,
        page,
        limit,
        totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      },
    };
  }

  /**
   * Get review statistics for a user
   */
  async getReviewStats(userId: string) {
    const reviews = await this.prisma.review.findMany({
      where: {
        revieweeId: userId,
        isVisible: true,
      },
      select: {
        overallRating: true,
        punctualityRating: true,
        communicationRating: true,
        attitudeRating: true,
      },
    });

    const total = reviews.length;
    if (total === 0) {
      return {
        averageRating: 0,
        totalReviews: 0,
        ratingDistribution: {
          1: 0,
          2: 0,
          3: 0,
          4: 0,
          5: 0,
        },
        subRatings: {
          punctuality: 0,
          communication: 0,
          attitude: 0,
        },
      };
    }

    // Calculate average
    const sumRating = reviews.reduce((sum, r) => sum + r.overallRating, 0);
    const averageRating = sumRating / total;

    // Rating distribution
    const ratingDistribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    reviews.forEach((r) => {
      ratingDistribution[r.overallRating as keyof typeof ratingDistribution]++;
    });

    // Sub-ratings
    const punctualityRatings = reviews.filter((r) => r.punctualityRating != null);
    const communicationRatings = reviews.filter((r) => r.communicationRating != null);
    const attitudeRatings = reviews.filter((r) => r.attitudeRating != null);

    return {
      averageRating: Number(averageRating.toFixed(1)),
      totalReviews: total,
      ratingDistribution,
      subRatings: {
        punctuality:
          punctualityRatings.length > 0
            ? punctualityRatings.reduce((sum, r) => sum + (r.punctualityRating || 0), 0) /
              punctualityRatings.length
            : 0,
        communication:
          communicationRatings.length > 0
            ? communicationRatings.reduce((sum, r) => sum + (r.communicationRating || 0), 0) /
              communicationRatings.length
            : 0,
        attitude:
          attitudeRatings.length > 0
            ? attitudeRatings.reduce((sum, r) => sum + (r.attitudeRating || 0), 0) /
              attitudeRatings.length
            : 0,
      },
    };
  }

  /**
   * Update review
   */
  async updateReview(userId: string, reviewId: string, dto: UpdateReviewDto) {
    const review = await this.prisma.review.findFirst({
      where: {
        id: reviewId,
        reviewerId: userId,
      },
    });

    if (!review) {
      throw new NotFoundException('Review not found');
    }

    // Only allow updates within 24 hours
    const hoursSinceCreation =
      (Date.now() - review.createdAt.getTime()) / (1000 * 60 * 60);
    if (hoursSinceCreation > 24) {
      throw new BadRequestException('Reviews can only be updated within 24 hours');
    }

    const updated = await this.prisma.review.update({
      where: { id: reviewId },
      data: dto,
    });

    // Update partner stats if rating changed
    if (dto.overallRating && review.reviewType === 'user_to_partner') {
      await this.updatePartnerReviewStats(review.revieweeId);
    }

    return updated;
  }

  /**
   * Delete review
   */
  async deleteReview(userId: string, reviewId: string) {
    const review = await this.prisma.review.findFirst({
      where: {
        id: reviewId,
        reviewerId: userId,
      },
    });

    if (!review) {
      throw new NotFoundException('Review not found');
    }

    await this.prisma.review.delete({
      where: { id: reviewId },
    });

    // Update partner stats
    if (review.reviewType === 'user_to_partner') {
      await this.updatePartnerReviewStats(review.revieweeId);
    }

    return { message: 'Review deleted successfully' };
  }

  /**
   * Create response to a review
   */
  async createReviewResponse(
    userId: string,
    reviewId: string,
    dto: CreateReviewResponseDto,
  ) {
    const review = await this.prisma.review.findFirst({
      where: {
        id: reviewId,
        revieweeId: userId,
      },
    });

    if (!review) {
      throw new NotFoundException('Review not found or you cannot respond to it');
    }

    // Check if response already exists
    const existing = await this.prisma.reviewResponse.findUnique({
      where: { reviewId },
    });

    if (existing) {
      throw new ConflictException('Response already exists');
    }

    return this.prisma.reviewResponse.create({
      data: {
        reviewId,
        responderId: userId,
        response: dto.response,
      },
    });
  }

  /**
   * Update partner review stats
   */
  private async updatePartnerReviewStats(partnerId: string) {
    const stats = await this.prisma.review.aggregate({
      where: {
        revieweeId: partnerId,
        isVisible: true,
        reviewType: 'user_to_partner',
      },
      _avg: { overallRating: true },
      _count: true,
    });

    await this.prisma.partnerProfile.updateMany({
      where: { userId: partnerId },
      data: {
        averageRating: stats._avg.overallRating || 0,
        totalReviews: stats._count,
      },
    });
  }
}
