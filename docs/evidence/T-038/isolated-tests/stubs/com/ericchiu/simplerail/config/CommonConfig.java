package com.ericchiu.simplerail.config;
/** Explicit publication double: ConfigSpec lifecycle is not exercised here. */
public final class CommonConfig {
    public static int reads;
    public static int seconds = 5;
    public static int lastLevel;
    public static Snapshot current() { reads++; return new Snapshot(); }
    public static final class Snapshot {
        public int holdingWaitSeconds(int level) { lastLevel=level; return seconds; }
    }
}
