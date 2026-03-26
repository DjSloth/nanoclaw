<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-03-26 | Updated: 2026-03-26 -->

# src/channels

## Purpose
Channel abstraction layer. Each file implements the `Channel` interface from `src/types.ts` for a specific messaging platform. The registry pattern allows the main process to discover and instantiate channels without hardcoded references.

## Key Files

| File | Description |
|------|-------------|
| `index.ts` | Barrel import — importing this file causes all channels to self-register |
| `registry.ts` | Channel factory registry: `registerChannel`, `getChannelFactory`, `getRegisteredChannelNames` |
| `whatsapp.ts` | WhatsApp channel via Baileys library — connection, QR auth, send/receive, typing indicator, group sync |

## For AI Agents

### Working In This Directory
- New channels are added via skills (e.g., `/add-telegram`, `/add-discord`), not by modifying this directory directly in PRs
- Each channel must implement the full `Channel` interface from `src/types.ts`
- Channels self-register by calling `registerChannel()` from their module — the barrel import in `index.ts` triggers registration
- Channels return `null` from their factory when credentials are missing (not an error — just skipped at startup)

### Testing Requirements
- `registry.test.ts` and `whatsapp.test.ts` cover the core logic
- Channel connection tests require live credentials — not suitable for CI

### Common Patterns
- Factory function pattern: `registerChannel('name', (opts) => credentials ? new Channel(opts) : null)`
- JID (Jabber ID) is the universal group/chat identifier across all channels
- `ownsJid(jid)` determines which channel is responsible for routing a given JID

## Dependencies

### Internal
- `src/types.ts` — `Channel`, `OnInboundMessage`, `OnChatMetadata` interfaces
- `src/db.ts` — message and chat storage

### External
- `@whiskeysockets/baileys` — WhatsApp Web protocol implementation

<!-- MANUAL: -->
