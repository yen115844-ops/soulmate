import { Global, Module } from '@nestjs/common';
import { PrismaModule } from '../../database/prisma/prisma.module';
import { SettingsController } from './settings.controller';
import { SettingsService } from './settings.service';
import { TermsController } from './terms.controller';

@Global()
@Module({
  imports: [PrismaModule],
  controllers: [SettingsController, TermsController],
  providers: [SettingsService],
  exports: [SettingsService],
})
export class SettingsModule {}
