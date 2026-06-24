import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AiModule } from './ai/ai.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,   // makes ConfigService available everywhere without re-importing
      envFilePath: '.env',
    }),
    AiModule,
  ],
})
export class AppModule {}
