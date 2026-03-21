import { Global, Module } from '@nestjs/common';
import { PrismaModule } from '../../database/prisma/prisma.module';
import { AppConfigController } from './app-config.controller';
import { SettingsController } from './settings.controller';
import { SettingsService } from './settings.service';
import { SupportController } from './support.controller';
import { TermsController } from './terms.controller';

@Global()
@Module({
  imports: [PrismaModule],
  controllers: [SettingsController, TermsController, SupportController, AppConfigController],
  providers: [SettingsService],
  exports: [SettingsService],
})
export class SettingsModule {}
