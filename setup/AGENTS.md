<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-03-26 | Updated: 2026-03-26 -->

# setup

## Purpose
Setup utilities used during initial installation and service registration. These modules handle environment configuration, platform detection, service registration (systemd/launchd), and WhatsApp authentication setup.

## Key Files

| File | Description |
|------|-------------|
| `index.ts` | Barrel export for setup utilities |
| `environment.ts` | Environment validation and .env file generation |
| `groups.ts` | Creates initial group folder structure |
| `mounts.ts` | Generates mount allowlist configuration |
| `platform.ts` | Detects OS platform (macOS/Linux) and service manager (launchd/systemd) |
| `register.ts` | Registers NanoClaw as a system service (launchd plist or systemd unit) |
| `service.ts` | Service management (start/stop/restart/status) via platform-native commands |
| `status.ts` | Checks running status of NanoClaw service and dependencies |
| `verify.ts` | Post-setup verification — checks all components are correctly configured |
| `container.ts` | Container runtime setup and health checks |
| `whatsapp-auth.ts` | WhatsApp QR code authentication flow |

## For AI Agents

### Working In This Directory
- These modules are called by the `/setup` skill — not at runtime
- Platform detection in `platform.ts` controls which service manager commands are used
- After modifying service registration, test on both macOS (launchd) and Linux (systemd) if possible

### Testing Requirements
- `environment.test.ts`, `platform.test.ts`, `register.test.ts`, `service.test.ts` cover core logic
- Full integration test requires running on the target platform

### Common Patterns
- All service management goes through `platform.ts` detection first
- Service registration writes files to `~/Library/LaunchAgents/` (macOS) or `~/.config/systemd/user/` (Linux)

## Dependencies

### Internal
- Called exclusively by `.claude/skills/setup/SKILL.md`

### External
- Platform-native service managers (launchd, systemd)

<!-- MANUAL: -->
