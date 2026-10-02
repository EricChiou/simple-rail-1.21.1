package com.ericchiu.simplerail.block;

/** Junction routing independent of world storage; T replaces the two legacy Y junctions. */
public final class JunctionRoute {
    public enum Kind { CROSS, T }
    public enum Cardinal { EAST, WEST, NORTH, SOUTH }

    private JunctionRoute() {}

    public static Cardinal destination(Kind kind, Cardinal incoming, Cardinal facing, boolean powered) {
        if (kind == Kind.CROSS) return incoming;
        // Facing is travel from the stem into the junction. Branches return to the stem.
        // Entry from the closed fourth side continues toward the stem, without reversing.
        if (incoming != facing) return opposite(facing);
        return powered ? left(facing) : right(facing);
    }

    private static Cardinal right(Cardinal direction) {
        return switch (direction) {
            case NORTH -> Cardinal.EAST;
            case EAST -> Cardinal.SOUTH;
            case SOUTH -> Cardinal.WEST;
            case WEST -> Cardinal.NORTH;
        };
    }

    private static Cardinal left(Cardinal direction) {
        return opposite(right(direction));
    }

    private static Cardinal opposite(Cardinal direction) {
        return switch (direction) {
            case NORTH -> Cardinal.SOUTH;
            case SOUTH -> Cardinal.NORTH;
            case EAST -> Cardinal.WEST;
            case WEST -> Cardinal.EAST;
        };
    }
}
