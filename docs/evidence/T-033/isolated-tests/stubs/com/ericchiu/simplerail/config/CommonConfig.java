package com.ericchiu.simplerail.config;
/** Isolated config publication double, not the real ConfigSpec lifecycle. */
public final class CommonConfig {
    public record Snapshot(boolean destoryNeedPower) {}
    public static Snapshot active;
    public static int reads;
    public static Snapshot current() {
        reads++;
        if (active == null) throw new IllegalStateException("Unloaded isolated config");
        return active;
    }
}
