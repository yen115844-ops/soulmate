import { BadRequestException, ConflictException, Injectable, Logger, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { UserRole, UserStatus } from '@prisma/client';
import { randomInt } from 'crypto';
import { comparePassword, hashPassword } from '../../common/utils/hash.util';
import { PrismaService } from '../../database/prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { SettingsService } from '../settings/settings.service';
import { ChangePasswordDto, ForgotPasswordDto, LoginDto, RefreshTokenDto, RegisterDto, ResendOtpDto, ResetPasswordDto, VerifyOtpDto } from './dto';
import { EmailService } from './services/email.service';

export interface JwtPayload {
  sub: string;
  email: string;
  role: UserRole;
}

export interface TokenResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  private readonly OTP_EXPIRY_MINUTES = 10;
  private readonly OTP_PURPOSE_VERIFY_EMAIL = 'verify_email';
  private readonly OTP_PURPOSE_RESET_PASSWORD = 'reset_password';
  private readonly OTP_MAX_ATTEMPTS = 5;

  private readonly LOCK_DURATION_MINUTES = 15;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly emailService: EmailService,
    private readonly settingsService: SettingsService,
    private readonly notificationsService: NotificationsService,
  ) {}

  /**
   * Register a new user - creates account PENDING and sends OTP to email for verification
   */
  async register(dto: RegisterDto) {
    const existingUser = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (existingUser) {
      throw new ConflictException('Email này đã được đăng ký');
    }
    if (dto.phone) {
      const existingPhone = await this.prisma.user.findUnique({
        where: { phone: dto.phone },
      });
      if (existingPhone) {
        throw new ConflictException('Số điện thoại này đã được đăng ký');
      }
    }

    await this.validatePasswordBySettings(dto.password);
    const passwordHash = await hashPassword(dto.password);
    const otp = this.generateOtp();

    const user = await this.prisma.$transaction(async (tx) => {
      const newUser = await tx.user.create({
        data: {
          email: dto.email,
          phone: dto.phone,
          passwordHash,
          role: UserRole.USER,
          status: UserStatus.PENDING,
        },
      });
      await tx.profile.create({
        data: { userId: newUser.id, fullName: dto.fullName },
      });
      await tx.wallet.create({
        data: { userId: newUser.id, balance: 0, pendingBalance: 0 },
      });
      const expiresAt = new Date(Date.now() + this.OTP_EXPIRY_MINUTES * 60 * 1000);
      await tx.otpCode.create({
        data: {
          target: dto.email,
          targetType: 'email',
          code: otp,
          purpose: this.OTP_PURPOSE_VERIFY_EMAIL,
          expiresAt,
        },
      });
      return newUser;
    });

    await this.emailService.sendOtpEmail(dto.email, otp, 'verify_email');
    this.logger.log(`New user registered (pending verification): ${user.email}`);

    await this.notificationsService
      .notifyAdminsIfEnabled('new_user_alert', 'Người dùng mới đăng ký', `${dto.email} vừa đăng ký tài khoản.`, { email: dto.email, userId: user.id })
      .catch((err) => this.logger.warn(`Failed to notify admins: ${err?.message}`));

    return {
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        status: user.status,
      },
      message: 'Vui lòng xác thực email. Mã OTP đã được gửi đến hộp thư của bạn.',
    };
  }

  /**
   * Verify OTP and activate user (after email registration)
   */
  async verifyOtp(dto: VerifyOtpDto) {
    const otpRecord = await this.prisma.otpCode.findFirst({
      where: {
        target: dto.email,
        targetType: 'email',
        purpose: this.OTP_PURPOSE_VERIFY_EMAIL,
        isUsed: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otpRecord) {
      throw new BadRequestException('Mã OTP không hợp lệ hoặc đã hết hạn');
    }

    // Check brute-force: max attempts exceeded
    if (otpRecord.attempts >= this.OTP_MAX_ATTEMPTS) {
      // Invalidate this OTP
      await this.prisma.otpCode.update({
        where: { id: otpRecord.id },
        data: { isUsed: true },
      });
      throw new BadRequestException('Đã nhập sai OTP quá nhiều lần. Vui lòng yêu cầu mã mới.');
    }

    if (otpRecord.code !== dto.otp.trim()) {
      // Increment attempt count
      await this.prisma.otpCode.update({
        where: { id: otpRecord.id },
        data: { attempts: { increment: 1 } },
      });
      const remaining = this.OTP_MAX_ATTEMPTS - otpRecord.attempts - 1;
      throw new BadRequestException(
        remaining > 0
          ? `Mã OTP không đúng. Còn ${remaining} lần thử.`
          : 'Đã nhập sai OTP quá nhiều lần. Vui lòng yêu cầu mã mới.',
      );
    }

    const user = await this.prisma.$transaction(async (tx) => {
      await tx.otpCode.update({
        where: { id: otpRecord.id },
        data: { isUsed: true, usedAt: new Date() },
      });
      const updated = await tx.user.update({
        where: { email: dto.email },
        data: { status: UserStatus.ACTIVE },
        include: { profile: true },
      });
      return updated;
    });

    const tokens = await this.generateTokens(user);
    await this.saveRefreshToken(user.id, tokens.refreshToken);
    this.logger.log(`Email verified and user activated: ${user.email}`);

    return {
      user: {
        id: user.id,
        email: user.email,
        phone: user.phone,
        role: user.role,
        status: user.status,
        kycStatus: user.kycStatus,
        profile: user.profile,
      },
      ...tokens,
    };
  }

  /**
   * Resend OTP to email (for pending registration)
   */
  async resendOtp(dto: ResendOtpDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (!user || user.status !== UserStatus.PENDING) {
      throw new NotFoundException('Không tìm thấy tài khoản chờ xác thực với email này');
    }

    const otp = this.generateOtp();
    const expiresAt = new Date(Date.now() + this.OTP_EXPIRY_MINUTES * 60 * 1000);
    await this.prisma.otpCode.create({
      data: {
        target: dto.email,
        targetType: 'email',
        code: otp,
        purpose: this.OTP_PURPOSE_VERIFY_EMAIL,
        expiresAt,
      },
    });
    await this.emailService.sendOtpEmail(dto.email, otp, 'verify_email');
    this.logger.log(`OTP resent to ${dto.email}`);
    return { message: 'Mã OTP đã được gửi lại đến email của bạn' };
  }

  /**
   * Forgot password - send OTP to email (only for ACTIVE users)
   */
  async forgotPassword(dto: ForgotPasswordDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (!user) {
      throw new NotFoundException('Không tìm thấy tài khoản với email này');
    }
    if (user.status !== UserStatus.ACTIVE) {
      throw new BadRequestException('Tài khoản chưa được kích hoạt. Vui lòng xác thực email trước.');
    }

    const otp = this.generateOtp();
    const expiresAt = new Date(Date.now() + this.OTP_EXPIRY_MINUTES * 60 * 1000);
    await this.prisma.otpCode.create({
      data: {
        target: dto.email,
        targetType: 'email',
        code: otp,
        purpose: this.OTP_PURPOSE_RESET_PASSWORD,
        expiresAt,
      },
    });
    await this.emailService.sendOtpEmail(dto.email, otp, 'reset_password');
    this.logger.log(`Forgot password OTP sent to ${dto.email}`);
    return { message: 'Mã OTP đã được gửi đến email của bạn. Vui lòng kiểm tra hộp thư.' };
  }

  /**
   * Reset password with OTP (from forgot password flow)
   */
  async resetPassword(dto: ResetPasswordDto) {
    const otpRecord = await this.prisma.otpCode.findFirst({
      where: {
        target: dto.email,
        targetType: 'email',
        purpose: this.OTP_PURPOSE_RESET_PASSWORD,
        isUsed: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otpRecord) {
      throw new BadRequestException('Mã OTP không hợp lệ hoặc đã hết hạn');
    }

    // Check brute-force: max attempts exceeded
    if (otpRecord.attempts >= this.OTP_MAX_ATTEMPTS) {
      await this.prisma.otpCode.update({
        where: { id: otpRecord.id },
        data: { isUsed: true },
      });
      throw new BadRequestException('Đã nhập sai OTP quá nhiều lần. Vui lòng yêu cầu mã mới.');
    }

    if (otpRecord.code !== dto.otp.trim()) {
      await this.prisma.otpCode.update({
        where: { id: otpRecord.id },
        data: { attempts: { increment: 1 } },
      });
      const remaining = this.OTP_MAX_ATTEMPTS - otpRecord.attempts - 1;
      throw new BadRequestException(
        remaining > 0
          ? `Mã OTP không đúng. Còn ${remaining} lần thử.`
          : 'Đã nhập sai OTP quá nhiều lần. Vui lòng yêu cầu mã mới.',
      );
    }

    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (!user) {
      throw new NotFoundException('Không tìm thấy tài khoản');
    }

    await this.validatePasswordBySettings(dto.newPassword);
    const passwordHash = await hashPassword(dto.newPassword);
    await this.prisma.$transaction(async (tx) => {
      await tx.otpCode.update({
        where: { id: otpRecord.id },
        data: { isUsed: true, usedAt: new Date() },
      });
      await tx.user.update({
        where: { id: user.id },
        data: { passwordHash },
      });
    });

    this.logger.log(`Password reset for ${dto.email}`);
    return { message: 'Đặt lại mật khẩu thành công. Bạn có thể đăng nhập bằng mật khẩu mới.' };
  }

  private generateOtp(): string {
    return randomInt(100000, 999999).toString();
  }

  /**
   * Login with email and password
   */
  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
      include: {
        profile: true,
      },
    });

    if (!user) {
      throw new UnauthorizedException('Email hoặc mật khẩu không đúng');
    }

    const maxLoginAttempts = await this.settingsService.getNumber('max_login_attempts', 5);
    const now = new Date();
    if (user.lockedUntil && user.lockedUntil > now) {
      const mins = Math.ceil((user.lockedUntil.getTime() - now.getTime()) / 60000);
      throw new UnauthorizedException(`Tài khoản tạm khóa do đăng nhập sai quá nhiều lần. Thử lại sau ${mins} phút.`);
    }

    const isPasswordValid = await comparePassword(dto.password, user.passwordHash);
    if (!isPasswordValid) {
      const newAttempts = (user.failedLoginAttempts ?? 0) + 1;
      const updates: { failedLoginAttempts: number; lockedUntil?: Date } = { failedLoginAttempts: newAttempts };
      if (newAttempts >= maxLoginAttempts) {
        const lockUntil = new Date(now.getTime() + this.LOCK_DURATION_MINUTES * 60 * 1000);
        updates.lockedUntil = lockUntil;
      }
      await this.prisma.user.update({
        where: { id: user.id },
        data: updates,
      });
      if (newAttempts >= maxLoginAttempts) {
        throw new UnauthorizedException(`Đăng nhập sai quá ${maxLoginAttempts} lần. Tài khoản tạm khóa ${this.LOCK_DURATION_MINUTES} phút.`);
      }
      throw new UnauthorizedException('Email hoặc mật khẩu không đúng');
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: { failedLoginAttempts: 0, lockedUntil: null },
    });

    if (user.status === UserStatus.PENDING) {
      throw new UnauthorizedException('Vui lòng xác thực email trước khi đăng nhập. Kiểm tra hộp thư để lấy mã OTP.');
    }
    if (user.status === UserStatus.BANNED) {
      throw new UnauthorizedException('Tài khoản của bạn đã bị cấm vĩnh viễn');
    }
    if (user.status === UserStatus.SUSPENDED) {
      throw new UnauthorizedException('Tài khoản của bạn đã bị tạm khóa');
    }
    if (user.status === UserStatus.DELETED) {
      throw new UnauthorizedException('Tài khoản này đã bị xóa');
    }

    // Generate tokens
    const tokens = await this.generateTokens(user);

    // Save refresh token
    await this.saveRefreshToken(user.id, tokens.refreshToken);

    // Update lastActiveAt for partner profile (so "online" shows on Home/Favorites)
    await this.prisma.partnerProfile.updateMany({
      where: { userId: user.id },
      data: { lastActiveAt: new Date() },
    });

    this.logger.log(`User logged in: ${user.email}`);

    return {
      user: {
        id: user.id,
        email: user.email,
        phone: user.phone,
        role: user.role,
        status: user.status,
        kycStatus: user.kycStatus,
        profile: user.profile,
      },
      ...tokens,
    };
  }

  /**
   * Refresh access token
   */
  async refreshToken(dto: RefreshTokenDto) {
    try {
      // Verify refresh token
      const payload = this.jwtService.verify<JwtPayload>(dto.refreshToken, {
        secret: this.configService.get<string>('jwt.refreshSecret'),
      });

      // Check if refresh token exists in database
      const storedToken = await this.prisma.refreshToken.findFirst({
        where: {
          userId: payload.sub,
          token: dto.refreshToken,
          expiresAt: { gt: new Date() },
          revokedAt: null,
        },
        include: { user: true },
      });

      if (!storedToken) {
        throw new UnauthorizedException('Token không hợp lệ hoặc đã hết hạn');
      }

      // Generate new tokens
      const tokens = await this.generateTokens(storedToken.user);

      // Revoke old refresh token
      await this.prisma.refreshToken.update({
        where: { id: storedToken.id },
        data: { revokedAt: new Date() },
      });

      // Save new refresh token
      await this.saveRefreshToken(storedToken.user.id, tokens.refreshToken);

      return tokens;
    } catch (error) {
      throw new UnauthorizedException('Token không hợp lệ hoặc đã hết hạn');
    }
  }

  /**
   * Logout - revoke refresh token
   */
  async logout(userId: string, refreshToken: string) {
    await this.prisma.refreshToken.updateMany({
      where: {
        userId,
        token: refreshToken,
      },
      data: { revokedAt: new Date() },
    });

    return { message: 'Đăng xuất thành công' };
  }

  /**
   * Logout from all devices
   */
  async logoutAll(userId: string) {
    await this.prisma.refreshToken.updateMany({
      where: {
        userId,
        revokedAt: null,
      },
      data: { revokedAt: new Date() },
    });

    return { message: 'Đã đăng xuất khỏi tất cả thiết bị' };
  }

  /**
   * Change password
   */
  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('Không tìm thấy người dùng');
    }

    // Verify current password
    const isCurrentPasswordValid = await comparePassword(dto.currentPassword, user.passwordHash);
    if (!isCurrentPasswordValid) {
      throw new BadRequestException('Mật khẩu hiện tại không đúng');
    }

    await this.validatePasswordBySettings(dto.newPassword);
    const newPasswordHash = await hashPassword(dto.newPassword);

    // Update password
    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash: newPasswordHash },
    });

    // Revoke all refresh tokens (force re-login on all devices)
    await this.logoutAll(userId);

    return { message: 'Đổi mật khẩu thành công' };
  }

  /**
   * Validate user for JWT strategy
   */
  async validateUser(payload: JwtPayload) {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      include: { profile: true },
    });

    if (!user || user.status === UserStatus.BANNED || user.status === UserStatus.DELETED) {
      return null;
    }

    return {
      id: user.id,
      email: user.email,
      role: user.role,
      status: user.status,
      kycStatus: user.kycStatus,
      profile: user.profile,
    };
  }

  /**
   * Generate access and refresh tokens
   * Access token: short-lived (15 minutes)
   * Refresh token: long-lived (session_timeout from app_settings, default 30 days)
   */
  private async generateTokens(user: { id: string; email: string; role: UserRole }): Promise<TokenResponse> {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };

    const sessionTimeoutDays = await this.settingsService.getNumber('session_timeout', 30);
    const accessExpiresInSeconds = 15 * 60; // 15 minutes
    const refreshExpiresInSeconds = sessionTimeoutDays * 24 * 3600;

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: this.configService.get<string>('jwt.accessSecret'),
        expiresIn: accessExpiresInSeconds,
      }),
      this.jwtService.signAsync(payload, {
        secret: this.configService.get<string>('jwt.refreshSecret'),
        expiresIn: refreshExpiresInSeconds,
      }),
    ]);

    return { accessToken, refreshToken, expiresIn: accessExpiresInSeconds };
  }

  /**
   * Save refresh token to database (expiry from app_settings.session_timeout in days)
   */
  private async saveRefreshToken(userId: string, token: string) {
    const sessionTimeoutDays = await this.settingsService.getNumber('session_timeout', 30);
    const expiresAt = new Date(Date.now() + sessionTimeoutDays * 24 * 3600 * 1000);

    await this.prisma.refreshToken.create({
      data: {
        userId,
        token,
        expiresAt,
      },
    });
  }

  /**
   * Validate password against app_settings: password_min_length, enforce_strong_password
   */
  private async validatePasswordBySettings(password: string): Promise<void> {
    const minLength = await this.settingsService.getNumber('password_min_length', 8);
    const enforceStrong = await this.settingsService.getBool('enforce_strong_password', true);
    if (password.length < minLength) {
      throw new BadRequestException(`Mật khẩu phải có ít nhất ${minLength} ký tự`);
    }
    if (enforceStrong) {
      const hasLower = /[a-z]/.test(password);
      const hasUpper = /[A-Z]/.test(password);
      const hasNumber = /\d/.test(password);
      const hasSymbol = /[@$!%*?&.#^_\-+=[\]{}();:'",<>/~`|\\]/.test(password);
      if (!hasLower || !hasUpper || !hasNumber || !hasSymbol) {
        throw new BadRequestException('Mật khẩu phải có chữ hoa, chữ thường, số và ký hiệu đặc biệt');
      }
    }
  }

  /**
   * Get current user with full profile
   */
  async getCurrentUser(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        profile: true,
        partnerProfile: true,
      },
    });

    if (!user) {
      throw new NotFoundException('Không tìm thấy người dùng');
    }

    // Remove sensitive data
    const { passwordHash, ...userData } = user;
    return { user: userData };
  }

  /**
   * Delete account (soft delete - sets status to BANNED)
   * User can request to delete their own account
   */
  async deleteAccount(userId: string, password: string) {
    // Verify user exists
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('Không tìm thấy người dùng');
    }

    // Verify password before deletion
    const isPasswordValid = await comparePassword(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new BadRequestException('Mật khẩu không chính xác');
    }

    // Soft delete: update status to DELETED and anonymize data
    await this.prisma.$transaction(async (tx) => {
      // Update user status
      await tx.user.update({
        where: { id: userId },
        data: {
          status: UserStatus.DELETED,
          email: `deleted_${userId}@deleted.account`,
          phone: null,
        },
      });

      // Anonymize profile
      await tx.profile.updateMany({
        where: { userId },
        data: {
          fullName: 'Tài khoản đã xóa',
          displayName: null,
          bio: null,
          avatarUrl: null,
        },
      });

      // Revoke all refresh tokens
      await tx.refreshToken.updateMany({
        where: { userId },
        data: { revokedAt: new Date() },
      });
    });

    this.logger.log(`User deleted account: ${user.email}`);

    return { message: 'Tài khoản đã được xóa thành công' };
  }
}
