package com.ericchiu.simplerail.entity;

import java.util.Locale;

/** Stable facing values for the locomotive's synced byte and NEW-world data. */
public enum Facing8 {
    EAST(0, "east", 180.0F),
    WEST(1, "west", 0.0F),
    NORTH(2, "north", -90.0F),
    SOUTH(3, "south", 90.0F),
    NORTH_EAST(4, "north_east", -135.0F),
    NORTH_WEST(5, "north_west", -45.0F),
    SOUTH_EAST(6, "south_east", 135.0F),
    SOUTH_WEST(7, "south_west", 45.0F);

    private final byte wire;
    private final String saved;
    private final float yaw;

    Facing8(int wire, String saved, float yaw) {
        this.wire = (byte) wire;
        this.saved = saved;
        this.yaw = yaw;
    }

    public byte wire() { return wire; }
    public String saved() { return saved; }
    public float yaw() { return yaw; }

    public static Facing8 fromWire(byte value) {
        for (Facing8 facing : values()) if (facing.wire == value) return facing;
        return NORTH;
    }

    public static Facing8 fromSaved(String value) {
        String normalized = value == null ? "" : value.toLowerCase(Locale.ROOT);
        for (Facing8 facing : values()) if (facing.saved.equals(normalized)) return facing;
        return NORTH;
    }

    public static Facing8 fromMotion(double x, double z, Facing8 previous) {
        if (x == 0.0 && z == 0.0) return previous;
        if (x > 0.0 && z < 0.0) return NORTH_EAST;
        if (x < 0.0 && z < 0.0) return NORTH_WEST;
        if (x > 0.0 && z > 0.0) return SOUTH_EAST;
        if (x < 0.0 && z > 0.0) return SOUTH_WEST;
        if (x > 0.0) return EAST;
        if (x < 0.0) return WEST;
        return z < 0.0 ? NORTH : SOUTH;
    }
}
