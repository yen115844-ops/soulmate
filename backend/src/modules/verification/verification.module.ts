import { Module } from '@nestjs/common';
import { MulterModule } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { v4 as uuidv4 } from 'uuid';
import { PrismaModule } from '../../database/prisma/prisma.module';
import { NotificationsModule } from '../notifications';
import { VerificationController } from './verification.controller';
import { VerificationService } from './verification.service';

@Module({
  imports: [
    PrismaModule,
    NotificationsModule,
    MulterModule.register({
      storage: diskStorage({
        destination: join(process.cwd(), 'uploads', 'verification'),
        filename: (req, file, callback) => {
          const uniqueSuffix = uuidv4();
          const ext = extname(file.originalname);
          callback(null, `selfie-${uniqueSuffix}${ext}`);
        },
      }),
      limits: {
        fileSize: 10 * 1024 * 1024, // 10MB for selfies
      },
      fileFilter: (req, file, callback) => {
        if (!file.mimetype.match(/\/(jpg|jpeg|png|webp)$/)) {
          callback(new Error('Only image files are allowed!'), false);
        }
        callback(null, true);
      },
    }),
  ],
  controllers: [VerificationController],
  providers: [VerificationService],
  exports: [VerificationService],
})
export class VerificationModule {}
