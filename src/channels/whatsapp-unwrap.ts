// WhatsApp wraps disappearing, view-once, and caption-bearing media messages
// in outer envelope types whose only payload is an inner IMessage. The inbound
// handler reads fields like `imageMessage` directly off `msg.message`, so
// without unwrapping the inner content is invisible — the message looks empty
// and the attachment silently drops.

import type { proto } from '@whiskeysockets/baileys';

const WRAPPER_KEYS = [
  'ephemeralMessage',
  'viewOnceMessage',
  'viewOnceMessageV2',
  'viewOnceMessageV2Extension',
  'documentWithCaptionMessage',
] as const;

export function unwrapMessageContent(
  content: proto.IMessage | null | undefined,
): proto.IMessage | undefined {
  if (!content) return undefined;
  for (const key of WRAPPER_KEYS) {
    const inner = content[key]?.message;
    if (inner) return unwrapMessageContent(inner);
  }
  return content;
}
