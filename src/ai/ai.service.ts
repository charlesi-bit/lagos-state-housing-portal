import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Anthropic from '@anthropic-ai/sdk';

@Injectable()
export class AiService implements OnModuleInit {
  private client: Anthropic;

  // Keep this string stable — any change busts the prompt cache
  private readonly SYSTEM_PROMPT = `
You are an assistant for the Lagos State Integrated Housing & Estate Portal (LSIHEP).
You help citizens with housing applications, estate queries, payment status, and eligibility checks.
Always respond in clear, plain language. If you cannot answer, direct the citizen to the relevant office.
  `.trim();

  constructor(private readonly config: ConfigService) {}

  onModuleInit() {
    this.client = new Anthropic({
      apiKey: this.config.getOrThrow<string>('ANTHROPIC_API_KEY'),
    });
  }

  // Short responses — returns the full text once complete
  async chat(userMessage: string): Promise<string> {
    const response = await this.client.messages.create({
      model: 'claude-opus-4-8',
      max_tokens: 1024,
      system: [
        {
          type: 'text',
          text: this.SYSTEM_PROMPT,
          cache_control: { type: 'ephemeral' },
        },
      ],
      messages: [{ role: 'user', content: userMessage }],
    });

    return (response.content[0] as Anthropic.TextBlock).text;
  }

  // Long responses — yields text chunks as they arrive
  async *chatStream(userMessage: string): AsyncGenerator<string> {
    const stream = this.client.messages.stream({
      model: 'claude-opus-4-8',
      max_tokens: 4096,
      system: [
        {
          type: 'text',
          text: this.SYSTEM_PROMPT,
          cache_control: { type: 'ephemeral' },
        },
      ],
      messages: [{ role: 'user', content: userMessage }],
    });

    // textStream yields each text delta as a string
    for await (const chunk of stream.textStream) {
      yield chunk;
    }
  }
}
