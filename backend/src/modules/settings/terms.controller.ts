import { BadRequestException, Controller, Get, Param } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { SettingsService } from './settings.service';

const VALID_TERMS_TYPES = [
  'terms-of-service',
  'terms-and-conditions',
  'privacy-policy',
] as const;

@ApiTags('Public')
@Controller('public/terms')
export class TermsController {
  constructor(private readonly settingsService: SettingsService) {}

  @Get(':type')
  @ApiOperation({ summary: 'Get terms/privacy content by type (Public)' })
  @ApiResponse({ status: 200, description: 'Terms or privacy policy content' })
  async getTerms(@Param('type') type: string) {
    if (!VALID_TERMS_TYPES.includes(type as (typeof VALID_TERMS_TYPES)[number])) {
      throw new BadRequestException(
        'type must be terms-of-service, terms-and-conditions or privacy-policy',
      );
    }
    const content =
      type === 'privacy-policy'
        ? await this.settingsService.getPrivacyPolicyContent()
        : await this.settingsService.getTermsContent(
            type === 'terms-of-service' ? 'terms_of_service' : 'terms_and_conditions',
          );
    return { content };
  }
}
