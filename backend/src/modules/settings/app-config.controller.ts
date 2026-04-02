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
    const [
      // General
      appName,
      supportEmail,
      supportPhone,
      supportUrl,
      supportHotline,
      defaultCurrency,
      defaultLanguage,
      // Booking
      minBookingHours,
      maxBookingHours,
      advanceBookingDays,
      cancellationHours,
      serviceFeePercent,
      platformFeeRate,
      allowInstantBooking,
      requirePremiumForBooking,
      requirePremiumForChat,
      // Security
      requireApprovalForPartner,
      requireKycForPartner,
      maxEmergencyContacts,
    ] = await Promise.all([
      // General
      this.settingsService.getValue('app_name'),
      this.settingsService.getValue('support_email'),
      this.settingsService.getValue('support_phone'),
      this.settingsService.getValue('support_url'),
      this.settingsService.getValue('support_hotline'),
      this.settingsService.getValue('default_currency'),
      this.settingsService.getValue('default_language'),
      // Booking
      this.settingsService.getNumber('min_booking_hours', 1),
      this.settingsService.getNumber('max_booking_hours', 8),
      this.settingsService.getNumber('advance_booking_days', 30),
      this.settingsService.getNumber('cancellation_hours', 24),
      this.settingsService.getNumber('service_fee_percent', 15),
      this.settingsService.getNumber('platform_fee_rate', 0.15),
      this.settingsService.getBool('allow_instant_booking', true),
      this.settingsService.getBool('require_premium_for_booking', true),
      this.settingsService.getBool('require_premium_for_chat', true),
      // Security
      this.settingsService.getBool('require_approval_for_partner', false),
      this.settingsService.getBool('require_kyc_for_partner', true),
      this.settingsService.getNumber('max_emergency_contacts', 5),
    ]);

    return {
      // General
      appName: appName ?? 'Mate Social',
      supportEmail: supportEmail ?? '',
      supportPhone: supportPhone ?? '',
      supportUrl: supportUrl ?? '',
      supportHotline: supportHotline ?? '',
      defaultCurrency: defaultCurrency ?? 'VND',
      defaultLanguage: defaultLanguage ?? 'vi',
      // Booking
      minBookingHours,
      maxBookingHours,
      advanceBookingDays,
      cancellationHours,
      serviceFeePercent,
      platformFeeRate,
      allowInstantBooking,
      requirePremiumForBooking,
      requirePremiumForChat,
      // Security
      requireApprovalForPartner,
      requireKycForPartner,
      maxEmergencyContacts,
    };
  }
}
