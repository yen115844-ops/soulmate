import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { CommunityCacheService } from './community-cache.service';
import { CommunityController } from './community.controller';
import { CommunityService } from './community.service';

@Module({
  imports: [NotificationsModule],
  controllers: [CommunityController],
  providers: [CommunityService, CommunityCacheService],
})
export class CommunityModule {}
