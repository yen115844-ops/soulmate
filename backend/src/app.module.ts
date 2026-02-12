import { BullModule } from '@nestjs/bull';
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerModule } from '@nestjs/throttler';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { OptionalJwtAuthGuard } from './common/guards/optional-jwt-auth.guard';
import { ThrottlerUserGuard } from './common/guards/throttler-user.guard';
import {
    appConfig,
    cloudinaryConfig,
    databaseConfig,
    emailConfig,
    firebaseConfig,
    jwtConfig,
    redisConfig,
    sosConfig,
    stripeConfig,
    twilioConfig,
    uploadConfig,
    validationSchema,
} from './config';
import { PrismaModule } from './database/prisma';
import { AuthModule } from './modules/auth';
import { BookingsModule } from './modules/bookings';
import { ChatModule } from './modules/chat';
import { MasterDataModule } from './modules/master-data/master-data.module';
import { NotificationsModule } from './modules/notifications';
import { PartnersModule } from './modules/partners';
import { ReportsModule } from './modules/reports';
import { ReviewsModule } from './modules/reviews';
import { SafetyModule } from './modules/safety';
import { SettingsModule } from './modules/settings';
import { StatisticsModule } from './modules/statistics';
import { UploadModule } from './modules/upload';
import { UsersModule } from './modules/users';
import { WalletModule } from './modules/wallet';

@Module({
  imports: [
    // Config module - load .env with validation
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: [`.env.${process.env.NODE_ENV || 'development'}`, '.env.local', '.env'],
      load: [
        appConfig,
        databaseConfig,
        jwtConfig,
        redisConfig,
        uploadConfig,
        twilioConfig,
        firebaseConfig,
        stripeConfig,
        emailConfig,
        cloudinaryConfig,
        sosConfig,
      ],
      validationSchema,
      validationOptions: {
        abortEarly: false,
        allowUnknown: true,
      },
    }),

    // Rate limiting
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        throttlers: [
          {
            name: 'short',
            ttl: 1000,
            limit: configService.get<number>('THROTTLE_SHORT_LIMIT', 3),
          },
          {
            name: 'medium',
            ttl: 10000,
            limit: configService.get<number>('THROTTLE_MEDIUM_LIMIT', 20),
          },
          {
            name: 'long',
            ttl: 60000,
            limit: configService.get<number>('THROTTLE_LONG_LIMIT', 100),
          },
        ],
      }),
    }),

    // Database
    PrismaModule,

    // Bull Queue for background jobs
    BullModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        redis: {
          host: configService.get<string>('redis.host', 'localhost'),
          port: configService.get<number>('redis.port', 6379),
          password: configService.get<string>('redis.password'),
          maxRetriesPerRequest: null,
        },
      }),
    }),

    // Feature modules
    AuthModule,
    UsersModule,
    PartnersModule,
    BookingsModule,
    MasterDataModule,
    UploadModule,
    WalletModule,
    NotificationsModule,
    ReviewsModule,
    ChatModule,
    SettingsModule,
    StatisticsModule,
    SafetyModule,
    ReportsModule,
    // PaymentModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    // Optional JWT chạy trước để set req.user → ThrottlerUserGuard tính limit theo userId khi đã login
    { provide: APP_GUARD, useClass: OptionalJwtAuthGuard },
    { provide: APP_GUARD, useClass: ThrottlerUserGuard },
  ],
})
export class AppModule {}
