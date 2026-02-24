import { Global, Module } from '@nestjs/common';
import { PrismaModule } from '../../database/prisma/prisma.module';
import { SettingsController } from './settings.controller';
import { SettingsService } from './settings.service';
import { SupportController } from './support.controller';
import { TermsController } from './terms.controller';

@Global()
@Module({
  imports: [PrismaModule],
  controllers: [SettingsController, TermsController, SupportController],
  providers: [SettingsService],
  exports: [SettingsService],
})
export class SettingsModule {}
