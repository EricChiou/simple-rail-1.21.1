package com.ericchiu.simplerail.blockentity;

import java.util.Objects;
import java.util.UUID;
import java.util.function.LongSupplier;

/** Real elapsed time while loaded; persisted snapshots are paused remaining milliseconds. */
public final class HoldingTimer {
    public static final long MAX_MILLIS = (long) Integer.MAX_VALUE * 1000L;
    private final LongSupplier clock;
    private UUID cart;
    private long remainingAtResume;
    private long resumedAt;
    private boolean paused = true;

    public HoldingTimer(LongSupplier clock) {
        this.clock = Objects.requireNonNull(clock);
    }

    public static long secondsToMillis(int seconds) {
        if (seconds < 0) {
            throw new IllegalArgumentException("Holding seconds must be nonnegative.");
        }
        return Math.multiplyExact((long) seconds, 1000L);
    }

    public void restore(UUID cart, long remainingMillis) {
        boolean valid = cart != null && remainingMillis >= 0 && remainingMillis <= MAX_MILLIS;
        this.cart = valid ? cart : null;
        remainingAtResume = valid ? remainingMillis : 0;
        paused = true;
    }

    public void start(UUID cart, int seconds) {
        restore(Objects.requireNonNull(cart), secondsToMillis(seconds));
        resume();
    }

    public void resume() {
        if (paused) {
            resumedAt = clock.getAsLong();
            paused = false;
        }
    }

    public void pause() {
        remainingAtResume = remainingMillis();
        paused = true;
    }

    public long remainingMillis() {
        if (cart == null || paused) {
            return remainingAtResume;
        }
        // Keep one baseline so repeated observations do not discard fractional milliseconds.
        long elapsed = Math.max(0L, (clock.getAsLong() - resumedAt) / 1_000_000L);
        return elapsed >= remainingAtResume ? 0 : remainingAtResume - elapsed;
    }

    public UUID cartUuid() {
        // Keep the expired UUID: the same cart must continue to be released, not start again.
        return cart;
    }
}
