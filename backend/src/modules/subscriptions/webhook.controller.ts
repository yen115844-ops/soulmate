import {
    Body,
    Controller,
    HttpCode,
    HttpStatus,
    Logger,
    Post,
} from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { AppleNotificationV2Dto, GoogleRTDNDto } from './dto/webhook.dto';
import { SubscriptionWebhookService } from './subscription-webhook.service';
 
/**
 * Webhook Controller for App Store & Google Play Server Notifications
 *
 * Apple App Store Server Notifications V2:
 *   - Production URL: POST /api/v1/webhooks/apple/notifications
 *   - Sandbox URL:    POST /api/v1/webhooks/apple/notifications/sandbox
 *
 * Google Play Real-time Developer Notifications (RTDN):
 *   - URL: POST /api/v1/webhooks/google/notifications
 *
 * These endpoints are PUBLIC (no auth) — Apple/Google call them directly.
 * Security is handled by verifying the signed payloads.
 */
@ApiTags('Webhooks')
@Controller('webhooks')
export class WebhookController {
  private readonly logger = new Logger(WebhookController.name);

  constructor(
    private readonly webhookService: SubscriptionWebhookService,
  ) {}

  // ==================== Apple App Store Server Notifications V2 ====================

  /**
   * Production endpoint for Apple App Store Server Notifications V2
   *
   * Configure in App Store Connect:
   *   App → App Information → App Store Server Notifications
   *   Production Server URL: https://your-domain.com/api/v1/webhooks/apple/notifications
   */
  @Post('apple/notifications')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Apple App Store Server Notifications V2 (Production)',
    description: 'Receives server-to-server notifications from Apple for subscription lifecycle events in production.',
  })
  async handleAppleNotification(
    @Body() body: AppleNotificationV2Dto,
  ) {
    this.logger.log('[Apple Production] Received notification');

    try {
      await this.webhookService.handleAppleNotification(body, 'Production');
      return { status: 'ok' };
    } catch (error) {
      this.logger.error(
        `[Apple Production] Failed to process notification: ${error.message}`,
        error.stack,
      );
      // Still return 200 to Apple to prevent retries for processing errors
      // Apple will retry on non-2xx responses
      return { status: 'error', message: 'Notification received but processing failed' };
    }
  }

  /**
   * Sandbox endpoint for Apple App Store Server Notifications V2
   *
   * Configure in App Store Connect:
   *   App → App Information → App Store Server Notifications
   *   Sandbox Server URL: https://your-domain.com/api/v1/webhooks/apple/notifications/sandbox
   */
  @Post('apple/notifications/sandbox')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Apple App Store Server Notifications V2 (Sandbox)',
    description: 'Receives server-to-server notifications from Apple for subscription lifecycle events in sandbox/testing.',
  })
  async handleAppleSandboxNotification(
    @Body() body: AppleNotificationV2Dto,
  ) {
    this.logger.log('[Apple Sandbox] Received notification');

    try {
      await this.webhookService.handleAppleNotification(body, 'Sandbox');
      return { status: 'ok' };
    } catch (error) {
      this.logger.error(
        `[Apple Sandbox] Failed to process notification: ${error.message}`,
        error.stack,
      );
      return { status: 'error', message: 'Notification received but processing failed' };
    }
  }

  // ==================== Google Play Real-time Developer Notifications ====================

  /**
   * Google Play RTDN endpoint
   *
   * Configure in Google Play Console:
   *   Monetization setup → Real-time developer notifications
   *   Topic: projects/{project-id}/topics/{topic-name}
   *   Push endpoint: https://your-domain.com/api/v1/webhooks/google/notifications
   */
  @Post('google/notifications')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Google Play Real-time Developer Notifications',
    description: 'Receives Pub/Sub push notifications from Google Play for subscription lifecycle events.',
  })
  async handleGoogleNotification(@Body() body: GoogleRTDNDto) {
    this.logger.log('[Google RTDN] Received notification');

    try {
      await this.webhookService.handleGoogleNotification(body);
      return { status: 'ok' };
    } catch (error) {
      this.logger.error(
        `[Google RTDN] Failed to process notification: ${error.message}`,
        error.stack,
      );
      // Return 200 to prevent Pub/Sub retries for processing errors
      return { status: 'error', message: 'Notification received but processing failed' };
    }
  }
}
