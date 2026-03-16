import fs from 'fs';
import path from 'path';
import { logger } from './logger.js';

function parseEnvFile(): Record<string, string> {
  const envFile = path.join(process.cwd(), '.env');
  let content: string;
  try {
    content = fs.readFileSync(envFile, 'utf-8');
  } catch (err) {
    logger.debug({ err }, '.env file not found, using defaults');
    return {};
  }

  const result: Record<string, string> = {};
  for (const line of content.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eqIdx = trimmed.indexOf('=');
    if (eqIdx === -1) continue;
    const key = trimmed.slice(0, eqIdx).trim();
    let value = trimmed.slice(eqIdx + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (key && value) result[key] = value;
  }

  return result;
}

/**
 * Parse the .env file and return values for the requested keys.
 * Falls back to process.env for keys not found in .env (e.g. when the host
 * process was started via `doppler run` which injects secrets into process.env).
 * Does NOT load anything into process.env — callers decide what to
 * do with the values. This keeps secrets out of the process environment
 * so they don't leak to child processes.
 */
export function readEnvFile(keys: string[]): Record<string, string> {
  const all = parseEnvFile();
  const result: Record<string, string> = {};
  for (const key of keys) {
    if (all[key]) result[key] = all[key];
    else if (process.env[key]) result[key] = process.env[key]!;
  }
  return result;
}

/**
 * Parse the .env file and return ALL key-value pairs, excluding the given keys.
 */
export function readAllEnvFile(exclude: string[] = []): Record<string, string> {
  const all = parseEnvFile();
  const excluded = new Set(exclude);
  return Object.fromEntries(Object.entries(all).filter(([k]) => !excluded.has(k)));
}
