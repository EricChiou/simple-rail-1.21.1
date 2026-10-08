package com.ericchiu.simplerail.config;
public final class CommonConfig { public static boolean enabled=true; public static Snapshot current(){return new Snapshot(enabled);} public record Snapshot(boolean locomotiveChunkLoadingEnabled){} }
