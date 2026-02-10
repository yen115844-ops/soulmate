import { BullModule } from '@nestjs/bull';
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../../database/prisma/prisma.module';
import { NotificationsController } from './notifications.controller';
import { NotificationsGateway } from './notifications.gateway';
import { NotificationsService } from './notifications.service';
import {
    NOTIFICATION_QUEUE,
    NotificationProcessor,
} from './processors/notification.processor';
import { DeviceTokenService } from './services/device-token.service';
import { FcmService } from './services/fcm.service';

@Module({
  imports: [
    PrismaModule,
    ConfigModule,
    BullModule.registerQueue({
      name: NOTIFICATION_QUEUE,
    }),
  ],
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    FcmService,
    DeviceTokenService,
    NotificationProcessor,
    NotificationsGateway,
  ],
  exports: [NotificationsService, FcmService, DeviceTokenService, NotificationsGateway],
})
export class NotificationsModule {}

