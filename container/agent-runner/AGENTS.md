<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-03-26 | Updated: 2026-03-26 -->

# container/agent-runner

## Purpose
Node.js process that runs inside the container and wraps the Claude Agent SDK. It receives the prompt and session ID via stdin (JSON), invokes Claude Code, and writes structured output back to stdout using sentinel markers that the host process (`src/container-runner.ts`) parses.

## Key Files

| File | Description |
|------|-------------|
| `src/` | Agent-runner TypeScript source |
| `package.json` | Dependencies for the agent-runner (separate from host package.json) |
| `tsconfig.json` | TypeScript config for agent-runner |

## For AI Agents

### Working In This Directory
- The agent-runner is a separate Node.js package with its own `package.json` and `tsconfig.json`
- Changes here require rebuilding the container image with `./container/build.sh`
- Output must use the exact sentinel markers (`---NANOCLAW_OUTPUT_START---` / `---NANOCLAW_OUTPUT_END---`) that the host parser expects
- The agent-runner communicates with the host via stdout JSON lines, not direct function calls

### Common Patterns
- Input arrives via stdin as a single JSON object with `prompt`, `sessionId`, `groupFolder`, `chatJid`, `isMain` fields
- Each result streamed from Claude is emitted as a JSON line wrapped in sentinel markers
- Session ID persistence: the new session ID is passed back in each output line for the host to store

## Dependencies

### Internal
- Must match the `ContainerInput` / `ContainerOutput` interfaces defined in `src/container-runner.ts`

### External
- `@anthropic-ai/claude-code` — Claude Agent SDK
- Node.js 20+

<!-- MANUAL: -->
