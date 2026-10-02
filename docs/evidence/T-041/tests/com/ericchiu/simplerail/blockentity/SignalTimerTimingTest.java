package com.ericchiu.simplerail.blockentity;

/** Boundary checks against the production arithmetic without launching Minecraft. */
public final class SignalTimerTimingTest {
    private static int checked;

    public static void main(String[] args) {
        check(5, 90);
        check(10, 190);
        check(60, 1190);
        check(0, 1);
        check(1, 10);
        check(107_374_182, 2_147_483_630);
        check(107_374_183, Integer.MAX_VALUE);
        check(Integer.MAX_VALUE, Integer.MAX_VALUE);
        int previous = 0;
        for (int seconds = 0; seconds <= 250_000; seconds++) {
            int actual = SignalTimerTiming.offTicks(seconds);
            if (actual < 1 || actual < previous) {
                throw new AssertionError("Non-positive or decreasing interval at " + seconds);
            }
            previous = actual;
            checked++;
        }
        System.out.println("PASS " + checked + " interval boundary cases");
    }

    private static void check(int seconds, int expected) {
        int actual = SignalTimerTiming.offTicks(seconds);
        if (actual != expected) {
            throw new AssertionError(seconds + " seconds: expected " + expected + ", got " + actual);
        }
        checked++;
    }
}
