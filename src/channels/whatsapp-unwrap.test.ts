import { describe, it, expect } from 'vitest';

import { unwrapMessageContent } from './whatsapp-unwrap.js';

describe('unwrapMessageContent', () => {
  it('returns undefined for null or undefined', () => {
    expect(unwrapMessageContent(null)).toBeUndefined();
    expect(unwrapMessageContent(undefined)).toBeUndefined();
  });

  it('returns the content unchanged when no wrapper is present', () => {
    const content = { imageMessage: { mimetype: 'image/jpeg' } };
    expect(unwrapMessageContent(content)).toBe(content);
  });

  it('unwraps ephemeralMessage (disappearing chats)', () => {
    const inner = { imageMessage: { caption: 'hi', mimetype: 'image/jpeg' } };
    expect(unwrapMessageContent({ ephemeralMessage: { message: inner } })).toBe(inner);
  });

  it('unwraps viewOnceMessage', () => {
    const inner = { imageMessage: { mimetype: 'image/jpeg' } };
    expect(unwrapMessageContent({ viewOnceMessage: { message: inner } })).toBe(inner);
  });

  it('unwraps viewOnceMessageV2', () => {
    const inner = { imageMessage: { mimetype: 'image/jpeg' } };
    expect(unwrapMessageContent({ viewOnceMessageV2: { message: inner } })).toBe(inner);
  });

  it('unwraps viewOnceMessageV2Extension', () => {
    const inner = { imageMessage: { mimetype: 'image/jpeg' } };
    expect(unwrapMessageContent({ viewOnceMessageV2Extension: { message: inner } })).toBe(inner);
  });

  it('unwraps documentWithCaptionMessage', () => {
    const inner = { documentMessage: { fileName: 'x.pdf', mimetype: 'application/pdf' } };
    expect(unwrapMessageContent({ documentWithCaptionMessage: { message: inner } })).toBe(inner);
  });

  it('recursively unwraps nested wrappers (ephemeral → viewOnceV2)', () => {
    const inner = { imageMessage: { caption: 'nested', mimetype: 'image/jpeg' } };
    const wrapped = {
      ephemeralMessage: { message: { viewOnceMessageV2: { message: inner } } },
    };
    expect(unwrapMessageContent(wrapped)).toBe(inner);
  });

  it('returns the wrapper as-is when the wrapper has no inner message', () => {
    const content = { ephemeralMessage: {} };
    expect(unwrapMessageContent(content)).toBe(content);
  });
});
