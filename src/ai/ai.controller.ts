import { Controller, Post, Body, Sse, Query } from '@nestjs/common';
import { Observable } from 'rxjs';
import { AiService } from './ai.service';

@Controller('ai')
export class AiController {
  constructor(private readonly aiService: AiService) {}

  // POST /ai/chat  — short responses, returns JSON
  @Post('chat')
  async chat(@Body('message') message: string): Promise<{ reply: string }> {
    const reply = await this.aiService.chat(message);
    return { reply };
  }

  // GET /ai/chat/stream?message=...  — long responses, streams via SSE
  @Sse('chat/stream')
  chatStream(@Query('message') message: string): Observable<MessageEvent> {
    return new Observable((subscriber) => {
      (async () => {
        for await (const chunk of this.aiService.chatStream(message)) {
          subscriber.next({ data: chunk } as MessageEvent);
        }
        subscriber.complete();
      })().catch((err) => subscriber.error(err));
    });
  }
}
