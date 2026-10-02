package com.ericchiu.simplerail.blockentity;

import com.ericchiu.simplerail.config.CommonConfig;

/** Tick arithmetic for the signal timer; unrelated to the real-time holding rail. */
public final class SignalTimerTiming {
    private SignalTimerTiming() {}

    public static int offTicks(int configuredSeconds) {
        long interval = (long) configuredSeconds * CommonConfig.SIGNAL_TICKS_PER_SECOND;
        long off = interval - CommonConfig.SIGNAL_PULSE_TICKS;
        // A zero/short interval must still allow a scheduled low edge. The API
        // accepts int delays, so saturate rather than overflowing to a negative.
        return (int) Math.max(1L, Math.min((long) Integer.MAX_VALUE, off));
    }
}
