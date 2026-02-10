import { DynamicModule, Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {
  /**
   * Register PrismaModule asynchronously
   * Useful when you need to load configuration from ConfigService
   */
  static forRoot(): DynamicModule {
    return {
      module: PrismaModule,
      providers: [PrismaService],
      exports: [PrismaService],
      global: true,
    };
  }
}
