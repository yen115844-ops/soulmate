import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../../database/prisma/prisma.module';
import { NotificationsModule } from '../notifications';
import { SubscriptionWebhookService } from './subscription-webhook.service';
import { SubscriptionsController } from './subscriptions.controller';
import { SubscriptionsService } from './subscriptions.service';
import { WebhookController } from './webhook.controller';

@Module({
  imports: [PrismaModule, NotificationsModule, ConfigModule],
  controllers: [SubscriptionsController, WebhookController],
  providers: [SubscriptionsService, SubscriptionWebhookService],
  exports: [SubscriptionsService],
})
export class SubscriptionsModule {}
