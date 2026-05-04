import { describe, it, expect } from 'vitest';

import { InflightTracker } from './inflight-tracker.js';

function deferred<T = void>(): {
  promise: Promise<T>;
  resolve: (value: T) => void;
  reject: (err: unknown) => void;
} {
  let resolve!: (value: T) => void;
  let reject!: (err: unknown) => void;
  const promise = new Promise<T>((res, rej) => {
    resolve = res;
    reject = rej;
  });
  return { promise, resolve, reject };
}

describe('InflightTracker', () => {
  it('awaitAll resolves immediately when nothing is tracked', async () => {
    const t = new InflightTracker<string>();
    await t.awaitAll('chat');
    expect(t.size('chat')).toBe(0);
  });

  it('awaitAll waits for tracked promises to settle', async () => {
    const t = new InflightTracker<string>();
    const d = deferred();
    let settled = false;
    t.track(
      'chat',
      d.promise.then(() => {
        settled = true;
      }),
    );

    const done = t.awaitAll('chat');
    expect(settled).toBe(false);
    d.resolve();
    await done;
    expect(settled).toBe(true);
    expect(t.size('chat')).toBe(0);
  });

  it('re-checks for promises added during the await', async () => {
    const t = new InflightTracker<string>();
    const first = deferred();
    const second = deferred();

    const seenSizes: number[] = [];
    t.track('chat', first.promise);

    const done = (async () => {
      seenSizes.push(t.size('chat'));
      // schedule a new arrival mid-await
      setTimeout(() => {
        t.track('chat', second.promise);
        first.resolve();
      }, 5);
      await t.awaitAll('chat');
      seenSizes.push(t.size('chat'));
    })();

    setTimeout(() => second.resolve(), 20);
    await done;
    expect(seenSizes[0]).toBe(1);
    expect(seenSizes[1]).toBe(0);
  });

  it('isolates keys — awaiting one key does not block on others', async () => {
    const t = new InflightTracker<string>();
    const never = deferred();
    t.track('chat-A', never.promise);
    t.track('chat-B', Promise.resolve());

    await t.awaitAll('chat-B');
    expect(t.size('chat-A')).toBe(1);
    expect(t.size('chat-B')).toBe(0);
    never.resolve();
  });

  it('does not throw when a tracked promise rejects', async () => {
    const t = new InflightTracker<string>();
    // Swallow the original rejection at the call site so it does not become
    // an unhandled rejection — the tracker only cares about settlement.
    const rejecting = Promise.reject(new Error('boom')).catch(() => {
      throw new Error('boom');
    });
    t.track('chat', rejecting);

    await expect(t.awaitAll('chat')).resolves.toBeUndefined();
    expect(t.size('chat')).toBe(0);
  });
});
