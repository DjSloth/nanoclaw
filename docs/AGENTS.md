<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-03-26 | Updated: 2026-03-26 -->

# docs

## Purpose
Architecture documentation, design rationale, security model, and specification documents for NanoClaw. Read these before making architectural decisions or security-sensitive changes.

## Key Files

| File | Description |
|------|-------------|
| `REQUIREMENTS.md` | Architecture decisions and design rationale — why things are the way they are |
| `SECURITY.md` | Full security model: container boundaries, mount allowlist, credential handling |
| `SKILLS_ARCHITECTURE.md` | Skills system deep dive: git merge mechanics, apply flow, conflict resolution |
| `SPEC.md` | Functional specification for NanoClaw behavior |
| `SDK_DEEP_DIVE.md` | Claude Agent SDK internals relevant to NanoClaw's container invocation pattern |
| `DEBUG_CHECKLIST.md` | Step-by-step checklist for diagnosing common runtime issues |
| `APPLE-CONTAINER-NETWORKING.md` | Networking specifics for Apple Container runtime on macOS |

## For AI Agents

### Working In This Directory
- Read `SECURITY.md` before touching `src/container-runner.ts`, `src/mount-security.ts`, or `src/credential-proxy.ts`
- Read `REQUIREMENTS.md` before proposing architectural changes — many "obvious" alternatives were considered and rejected
- Read `SKILLS_ARCHITECTURE.md` before working on `skills-engine/` or `.claude/skills/`
- These are documentation files — do not create code here

<!-- MANUAL: -->
