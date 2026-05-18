// Tracks in-flight async work per key. Used by channels to expose pending
// per-chat message-handler promises to the orchestrator, so the message loop
// can await all known downloads before draining state.

export class InflightTracker<K> {
  private readonly map = new Map<K, Set<Promise<unknown>>>();

  track<T>(key: K, promise: Promise<T>): Promise<T> {
    let set = this.map.get(key);
    if (!set) {
      set = new Set();
      this.map.set(key, set);
    }
    const tracked: Promise<unknown> = promise.finally(() => {
      const current = this.map.get(key);
      if (!current) return;
      current.delete(tracked);
      if (current.size === 0) this.map.delete(key);
    });
    set.add(tracked);
    return promise;
  }

  async awaitAll(key: K): Promise<void> {
    while (true) {
      const set = this.map.get(key);
      if (!set || set.size === 0) return;
      await Promise.allSettled([...set]);
    }
  }

  size(key: K): number {
    return this.map.get(key)?.size ?? 0;
  }
}
