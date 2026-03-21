import { Module } from '@nestjs/common';
import { PrismaModule } from '../../database/prisma/prisma.module';
import { CreditsModule } from '../credits/credits.module';
import { NotificationsModule } from '../notifications';
import { SubscriptionsModule } from '../subscriptions/subscriptions.module';
import { BookingsController } from './bookings.controller';
import { BookingsService } from './bookings.service';

@Module({
  imports: [
    PrismaModule,
    NotificationsModule,
    SubscriptionsModule,
    CreditsModule,
  ],
  controllers: [BookingsController],
  providers: [BookingsService],
  exports: [BookingsService],
})
export class BookingsModule {}
