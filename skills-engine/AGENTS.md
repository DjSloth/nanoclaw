<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-03-26 | Updated: 2026-03-26 -->

# skills-engine

## Purpose
The skills management engine used by host-side skills (`.claude/skills/`) to apply, update, migrate, and uninstall skill transformations to the NanoClaw installation. This is a separate TypeScript package that skills import when they need to modify the codebase.

## Key Files

| File | Description |
|------|-------------|
| `index.ts` | Barrel export for all public engine APIs |
| `apply.ts` | Core skill application logic — applies file operations from skill manifests |
| `backup.ts` | Creates/restores/clears backups before skill application |
| `constants.ts` | Shared constants: BASE_DIR, CUSTOM_DIR, NANOCLAW_DIR, LOCK_FILE, STATE_FILE, SKILLS_SCHEMA_VERSION |
| `customize.ts` | Customize session management (start/commit/abort) for tracking skill-applied changes |
| `file-ops.ts` | Executes file operations (create, patch, append, delete) defined in skill manifests |
| `fs-utils.ts` | Filesystem utilities used across the engine |
| `init.ts` | Initializes the `.nanoclaw/` tracking directory |
| `lock.ts` | File-based locking to prevent concurrent skill operations |
| `manifest.ts` | Reads and validates skill manifests — version checks, conflict detection, dependency resolution |
| `merge.ts` | Git-aware file merging for skill updates |
| `migrate.ts` | Migrates existing installations to new skills schema versions |
| `path-remap.ts` | Records and resolves file path remappings when skills relocate files |
| `rebase.ts` | Rebases custom modifications on top of upstream updates |
| `replay.ts` | Re-applies skill transformations (used during updates) |
| `state.ts` | Reads/writes `.nanoclaw/state.yaml` — tracks applied skills, custom modifications, file hashes |
| `structured.ts` | Structured merging for JSON/YAML files (package.json deps, docker-compose services, .env additions) |
| `types.ts` | TypeScript types for skill manifests, file operations, state |
| `uninstall.ts` | Removes a skill's transformations from the installation |
| `update.ts` | Applies upstream updates while preserving customizations |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `__tests__/` | Unit tests for engine modules |

## For AI Agents

### Working In This Directory
- This is internal infrastructure — skills call it, it is not called directly by users
- Changes here require `npm run build` in the skills-engine directory and may affect all skill operations
- The state file (`.nanoclaw/state.yaml`) is the source of truth for what has been applied — do not modify it manually
- Locking (`lock.ts`) prevents concurrent operations — if a lock file is stuck, investigate before deleting it

### Testing Requirements
- Run `npm test` from the skills-engine directory to execute unit tests
- Test the full apply/update/uninstall cycle manually on a test installation

### Common Patterns
- All public operations acquire a lock first via `acquireLock()`
- State is written atomically to prevent corruption
- File hashes are used to detect user modifications before overwriting

## Dependencies

### External
- `js-yaml` — YAML state file parsing
- `semver` — version comparison for manifest compatibility checks

<!-- MANUAL: -->
