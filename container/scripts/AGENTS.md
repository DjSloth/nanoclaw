<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-03-26 | Updated: 2026-03-26 -->

# container/scripts

## Purpose
Helper shell scripts that run inside the container during skill initialization to configure credentials and integrations.

## Key Files

| File | Description |
|------|-------------|
| `init-git-creds.sh` | Configures git credentials inside the container for GitHub operations |
| `init-gws-creds.sh` | Initializes Google Workspace OAuth credentials inside the container |

## For AI Agents

### Working In This Directory
- These scripts are called by container-side skills during setup, not by the host
- Scripts run as the unprivileged `node` user inside the container
- Changes here require rebuilding the container image

<!-- MANUAL: -->
