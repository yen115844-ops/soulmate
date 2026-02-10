import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import type { Transporter } from 'nodemailer';

/**
 * Email service for sending OTP and transactional emails.
 * Requires: npm install nodemailer && npm install -D @types/nodemailer
 */
@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: Transporter | null = null;

  constructor(private readonly configService: ConfigService) {
    this.initTransporter();
  }

  private initTransporter() {
    const user = this.configService.get<string>('email.user');
    const password = this.configService.get<string>('email.password');
    if (!user || !password) {
      this.logger.warn('Email credentials not configured (EMAIL_USER, EMAIL_PASSWORD). OTP emails will be logged only.');
      return null;
    }
    this.transporter = nodemailer.createTransport({
      host: this.configService.get<string>('email.host', 'smtp.gmail.com'),
      port: this.configService.get<number>('email.port', 587),
      secure: false,
      auth: { user, pass: password },
    });
    return this.transporter;
  }

  /**
   * Send OTP code to email for verification (e.g. register, reset password)
   */
  async sendOtpEmail(to: string, otp: string, purpose: 'verify_email' | 'reset_password' = 'verify_email'): Promise<void> {
    const from = this.configService.get<string>('email.from', 'noreply@matesocial.com');
    const subject = purpose === 'verify_email'
      ? 'Xác thực email - Mate Social'
      : 'Đặt lại mật khẩu - Mate Social';
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
        <h2 style="color: #333;">${purpose === 'verify_email' ? 'Xác thực email của bạn' : 'Đặt lại mật khẩu'}</h2>
        <p>Mã xác thực của bạn là:</p>
        <p style="font-size: 28px; font-weight: bold; letter-spacing: 8px; color: #6366f1;">${otp}</p>
        <p style="color: #666;">Mã có hiệu lực trong 10 phút. Không chia sẻ mã này với bất kỳ ai.</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;" />
        <p style="color: #999; font-size: 12px;">Mate Social</p>
      </div>
    `;

    if (this.transporter) {
      await this.transporter.sendMail({ from, to, subject, html });
      this.logger.log(`OTP email sent to ${to}`);
    } else {
      this.logger.warn(`[DEV] OTP for ${to}: ${otp}`);
    }
  }
}
