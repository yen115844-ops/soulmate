import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { UserRole } from '../../generated/prisma/client';
import { UpdateAppSettingsDto, UpdateTermsDto } from './dto';
import { SettingsService } from './settings.service';

@ApiTags('Admin Settings')
@Controller('admin/settings')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
@ApiBearerAuth('JWT-auth')
export class SettingsController {
  constructor(private readonly settingsService: SettingsService) {}

  @Get()
  @ApiOperation({ summary: 'Get all app settings (Admin)' })
  @ApiResponse({
    status: 200,
    description: 'Settings with items and values map',
  })
  async getAll() {
    return this.settingsService.getAll();
  }

  @Put()
  @ApiOperation({ summary: 'Update app settings by key-value map (Admin)' })
  @ApiResponse({ status: 200, description: 'Updated settings' })
  async update(@Body() dto: UpdateAppSettingsDto) {
    return this.settingsService.updateValues(dto.values);
  }

  @Get('terms')
  @ApiOperation({ summary: 'Get terms and privacy content (Admin)' })
  @ApiResponse({
    status: 200,
    description: 'Terms of service, terms and conditions, privacy policy',
  })
  async getTerms() {
    const [termsOfService, termsAndConditions, privacyPolicy] =
      await Promise.all([
        this.settingsService.getTermsContent('terms_of_service'),
        this.settingsService.getTermsContent('terms_and_conditions'),
        this.settingsService.getPrivacyPolicyContent(),
      ]);
    return { termsOfService, termsAndConditions, privacyPolicy };
  }

  @Put('terms')
  @ApiOperation({ summary: 'Update terms/privacy content (Admin)' })
  @ApiResponse({ status: 200, description: 'Updated terms and privacy' })
  async updateTerms(@Body() dto: UpdateTermsDto) {
    const values: Record<string, string> = {};
    if (dto.termsOfService !== undefined)
      values.terms_of_service = dto.termsOfService;
    if (dto.termsAndConditions !== undefined)
      values.terms_and_conditions = dto.termsAndConditions;
    if (dto.privacyPolicy !== undefined)
      values.privacy_policy = dto.privacyPolicy;
    if (Object.keys(values).length > 0) {
      await this.settingsService.updateValues(values);
    }
    const [termsOfService, termsAndConditions, privacyPolicy] =
      await Promise.all([
        this.settingsService.getTermsContent('terms_of_service'),
        this.settingsService.getTermsContent('terms_and_conditions'),
        this.settingsService.getPrivacyPolicyContent(),
      ]);
    return { termsOfService, termsAndConditions, privacyPolicy };
  }
}
