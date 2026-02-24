import { downloadMediaMessage } from '@whiskeysockets/baileys';
import { WAMessage, WASocket } from '@whiskeysockets/baileys';

import { readEnvFile } from './env.js';

interface TranscriptionConfig {
  model: string;
  enabled: boolean;
  fallbackMessage: string;
}

const DEFAULT_CONFIG: TranscriptionConfig = {
  model: 'whisper-large-v3',
  enabled: true,
  fallbackMessage: '[Voice Message - transcription unavailable]',
};

async function transcribeWithGroq(
  audioBuffer: Buffer,
  config: TranscriptionConfig,
): Promise<string | null> {
  const env = readEnvFile(['GROQ_API_KEY']);
  const apiKey = env.GROQ_API_KEY;

  if (!apiKey) {
    console.warn('GROQ_API_KEY not set in .env');
    return null;
  }

  try {
    const FormData = (await import('form-data')).default;
    const form = new FormData();
    form.append('file', audioBuffer, {
      filename: 'voice.ogg',
      contentType: 'audio/ogg',
    });
    form.append('model', config.model);
    form.append('response_format', 'text');

    const response = await fetch('https://api.groq.com/openai/v1/audio/transcriptions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        ...form.getHeaders(),
      },
      body: form.getBuffer(),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Groq transcription failed:', response.status, errorText);
      return null;
    }

    const transcript = await response.text();
    return transcript;
  } catch (err) {
    console.error('Groq transcription failed:', err);
    return null;
  }
}

export async function transcribeAudioMessage(
  msg: WAMessage,
  sock: WASocket,
): Promise<string | null> {
  const config = DEFAULT_CONFIG;

  if (!config.enabled) {
    return config.fallbackMessage;
  }

  try {
    const buffer = (await downloadMediaMessage(
      msg,
      'buffer',
      {},
      {
        logger: console as any,
        reuploadRequest: sock.updateMediaMessage,
      },
    )) as Buffer;

    if (!buffer || buffer.length === 0) {
      console.error('Failed to download audio message');
      return config.fallbackMessage;
    }

    console.log(`Downloaded audio message: ${buffer.length} bytes`);

    const transcript = await transcribeWithGroq(buffer, config);

    if (!transcript) {
      return config.fallbackMessage;
    }

    return transcript.trim();
  } catch (err) {
    console.error('Transcription error:', err);
    return config.fallbackMessage;
  }
}

export function isVoiceMessage(msg: WAMessage): boolean {
  return msg.message?.audioMessage?.ptt === true;
}
