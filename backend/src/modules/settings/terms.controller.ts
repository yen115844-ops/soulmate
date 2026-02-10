import { BadRequestException, Controller, Get, Param } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { SettingsService } from './settings.service';

const VALID_TERMS_TYPES = ['terms-of-service', 'terms-and-conditions'] as const;

@ApiTags('Public')
@Controller('public/terms')
export class TermsController {
  constructor(private readonly settingsService: SettingsService) {}

  @Get(':type')
  @ApiOperation({ summary: 'Get terms content by type (Public)' })
  @ApiResponse({ status: 200, description: 'Terms content' })
  async getTerms(@Param('type') type: string) {
    if (!VALID_TERMS_TYPES.includes(type as (typeof VALID_TERMS_TYPES)[number])) {
      throw new BadRequestException(
        'type must be terms-of-service or terms-and-conditions',
      );
    }
    const key =
      type === 'terms-of-service' ? 'terms_of_service' : 'terms_and_conditions';
    const content = await this.settingsService.getTermsContent(key);
    return { content };
  }
}
