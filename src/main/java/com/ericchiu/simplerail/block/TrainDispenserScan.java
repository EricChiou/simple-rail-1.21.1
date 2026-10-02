package com.ericchiu.simplerail.block;

import java.util.function.BiConsumer;
import java.util.function.Predicate;

/** Source-compatible slot order and coordinates, independent of the game world. */
public final class TrainDispenserScan {
    public enum Facing { NORTH, SOUTH, EAST, WEST }
    public record Position(double x, double y, double z) {}

    private TrainDispenserScan() {}

    public static Position position(Facing facing, int x, int y, int z, int slot) {
        if (slot < 0 || slot >= 27) {
            throw new IllegalArgumentException("slot must be 0..26");
        }
        return switch (facing) {
            case EAST -> new Position(x + 1.5D, y, z + slot + 0.5D);
            case WEST -> new Position(x - 0.5D, y, z - slot + 0.5D);
            case NORTH -> new Position(x + slot + 0.5D, y, z - 0.5D);
            case SOUTH -> new Position(x - slot + 0.5D, y, z + 1.5D);
        };
    }

    /** Check occupancy before visiting the item in each slot, including empty slots. */
    public static int scan(Facing facing, int x, int y, int z, int slotCount,
            Predicate<Position> occupied, BiConsumer<Integer, Position> visit) {
        if (slotCount != 27) {
            throw new IllegalArgumentException("train dispenser requires exactly 27 slots");
        }
        int checked = 0;
        for (int slot = 0; slot < slotCount; slot++) {
            Position place = position(facing, x, y, z, slot);
            checked++;
            if (occupied.test(place)) {
                break;
            }
            visit.accept(slot, place);
        }
        return checked;
    }
}
