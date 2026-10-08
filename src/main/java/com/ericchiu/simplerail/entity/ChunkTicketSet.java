package com.ericchiu.simplerail.entity;

import java.util.HashSet;
import java.util.Set;
import java.util.function.LongConsumer;
import java.util.function.LongPredicate;

/** Per-owner diff: add first, await readiness, then release. No global ticket state. */
public final class ChunkTicketSet {
    private final Set<Long> applied = new HashSet<>();
    public Set<Long> applied() { return Set.copyOf(applied); }

    public boolean update(Set<Long> wanted, boolean complete, LongConsumer add,
                          LongPredicate ready, LongConsumer remove) {
        for (long chunk : wanted) {
            if (!applied.contains(chunk)) { add.accept(chunk); applied.add(chunk); }
        }
        if (!complete || !wanted.stream().allMatch(ready::test)) return false;
        for (long chunk : Set.copyOf(applied)) {
            if (!wanted.contains(chunk)) { remove.accept(chunk); applied.remove(chunk); }
        }
        return true;
    }

    public void clear(LongConsumer remove) {
        for (long chunk : Set.copyOf(applied)) { remove.accept(chunk); applied.remove(chunk); }
    }

    public static void includeBuffer(Set<Long> chunks, int blockX, int blockZ) {
        int centerX = Math.floorDiv(blockX, 16), centerZ = Math.floorDiv(blockZ, 16);
        for (int x = centerX - 1; x <= centerX + 1; x++) {
            for (int z = centerZ - 1; z <= centerZ + 1; z++)
                chunks.add((x & 0xffffffffL) | ((z & 0xffffffffL) << 32));
        }
    }
}
