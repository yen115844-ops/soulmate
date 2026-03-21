import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { SettingsService } from './settings.service';

@ApiTags('Public')
@Controller('public/app-config')
export class AppConfigController {
  constructor(private readonly settingsService: SettingsService) {}

  @Get()
  @Public()
  @ApiOperation({
    summary: 'Get app feature flags and config for mobile client',
  })
  @ApiResponse({ status: 200, description: 'App config and feature flags' })
  async getAppConfig() {
    const [requirePremiumForBooking, requireApprovalForPartner] =
      await Promise.all([
        this.settingsService.getBool('require_premium_for_booking', true),
        this.settingsService.getBool('require_approval_for_partner', false),
      ]);

    return {
      requirePremiumForBooking,
      requireApprovalForPartner,
    };
  }
}
