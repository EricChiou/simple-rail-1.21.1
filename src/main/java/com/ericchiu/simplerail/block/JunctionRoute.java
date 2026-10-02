package com.ericchiu.simplerail.block;

/** Junction routing independent of world storage; T replaces the two legacy Y junctions. */
public final class JunctionRoute {
    public enum Kind { CROSS, T }
    public enum Cardinal { EAST, WEST, NORTH, SOUTH }

    private JunctionRoute() {}

    public static Cardinal destination(Kind kind, Cardinal incoming, Cardinal facing, boolean powered) {
        if (kind == Kind.CROSS) return incoming;
        // Facing is travel from the fixed stem into the junction. Redstone selects
        // the bend, not the T's openings: unpowered stem <-> right, powered stem <-> left.
        Cardinal branch = powered ? left(facing) : right(facing);
        if (incoming == facing) return branch;
        if (incoming == opposite(branch)) return opposite(facing);
        // The other horizontal approach goes straight. The closed fourth side
        // is not a normal entrance; keep its forward direction as a fallback.
        return incoming;
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
