package evidence.t037;

import java.util.UUID;
import java.util.function.LongSupplier;

/** Diagnostic candidate only; not the T-038 production timer or an OLD data converter. */
public final class TimerState {
    public static final long MAX_MILLIS = (long) Integer.MAX_VALUE * 1000L;
    private final LongSupplier clock;
    private UUID cart;
    private long budget;
    private long baseline;
    private boolean paused = true;

    public TimerState(LongSupplier clock) { this.clock = clock; }
    public static long secondsToMillis(int seconds) {
        if (seconds < 0) throw new IllegalArgumentException("negative seconds");
        return Math.multiplyExact((long) seconds, 1000L);
    }
    public void restore(UUID cart, long remaining) {
        this.cart = cart != null && remaining > 0 && remaining <= MAX_MILLIS ? cart : null;
        budget = this.cart == null ? 0 : remaining;
        paused = true;
    }
    public void start(UUID cart, long millis) { restore(cart, millis); resume(); }
    public void resume() {
        if (paused) { baseline = clock.getAsLong(); paused = false; }
    }
    public long remaining() {
        if (cart == null) return 0;
        if (paused) return budget;
        long elapsed = Math.max(0L, (clock.getAsLong() - baseline) / 1_000_000L);
        return elapsed >= budget ? 0 : budget - elapsed;
    }
    public UUID cart() { return remaining() > 0 ? cart : null; }
    public boolean paused() { return paused; }
}
