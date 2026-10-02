package com.ericchiu.simplerail.block;

/** The 1.16.5 junction branches, kept independent of world and block storage. */
public final class JunctionRoute {
    public enum Kind { CROSS, LEFT, RIGHT }
    public enum Cardinal { EAST, WEST, NORTH, SOUTH }

    // Rows: incoming EAST, WEST, NORTH, SOUTH. Columns: block direction EAST, WEST, NORTH, SOUTH.
    private static final String[] UNPOWERED = {"EESS", "WWSS", "EENN", "EESS"};
    private static final String[] LEFT_POWERED = {"NESE", "WSWN", "NEWN", "WSSE"};
    private static final String[] RIGHT_POWERED = {"SEEN", "WNSW", "WNEN", "SESW"};

    private JunctionRoute() {}

    public static Cardinal destination(Kind kind, Cardinal incoming, Cardinal facing, boolean powered) {
        if (kind == Kind.CROSS) return incoming;
        int row = incoming.ordinal();
        int column = facing.ordinal();
        String encoded = powered
                ? (kind == Kind.LEFT ? LEFT_POWERED[row] : RIGHT_POWERED[row])
                : UNPOWERED[row];
        return switch (encoded.charAt(column)) {
            case 'E' -> Cardinal.EAST;
            case 'W' -> Cardinal.WEST;
            case 'N' -> Cardinal.NORTH;
            case 'S' -> Cardinal.SOUTH;
            default -> throw new IllegalStateException("Invalid junction route table");
        };
    }
}
