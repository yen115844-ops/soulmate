import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { SettingsService } from './settings.service';

@ApiTags('Public')
@Controller('public/support')
export class SupportController {
  constructor(private readonly settingsService: SettingsService) {}

  @Get()
  @Public()
  @ApiOperation({
    summary: 'Get support info for public support page (no auth)',
  })
  @ApiResponse({ status: 200, description: 'Support email, phone, URL' })
  async getSupportInfo() {
    const values = await this.settingsService.getValues([
      'support_email',
      'support_phone',
      'support_url',
      'app_name',
    ]);
    return {
      supportEmail: values.support_email ?? 'ngocbinhan8888@gmail.com',
      supportPhone: values.support_phone ?? '',
      supportUrl: values.support_url ?? '',
      appName: values.app_name ?? 'Mate Social',
    };
  }
}
