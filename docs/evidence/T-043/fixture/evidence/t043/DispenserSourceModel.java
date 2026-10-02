package evidence.t043;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.function.IntFunction;
import java.util.function.Predicate;

/** Executable NEW-side model of the OLD source loop, not production dispenser code. */
public final class DispenserSourceModel {
    public static final int SLOTS = 27;

    public enum Facing { EAST, WEST, NORTH, SOUTH }
    public enum Kind { EMPTY, OTHER, LOCOMOTIVE, RIDEABLE, CHEST, FURNACE, HOPPER, TNT }
    public enum Action { SKIP, SPAWN, BLOCKED }
    public record Position(double x, double y, double z) {}
    public record Step(int slot, Kind kind, Position position, Action action, UUID entityId) {}
    public record Result(List<Step> steps, UUID headAtSlotZero, List<UUID> linkedCars, int stoppedAt) {
        public Result {
            steps = List.copyOf(steps);
            linkedCars = List.copyOf(linkedCars);
        }
    }

    @FunctionalInterface
    public interface Spawner {
        UUID spawn(int slot, Kind kind, Position position);
    }

    private DispenserSourceModel() {}

    public static Position position(Facing facing, int x, int y, int z, int slot) {
        if (slot < 0 || slot >= SLOTS) throw new IllegalArgumentException("slot must be 0..26");
        return switch (facing) {
            case EAST -> new Position(x + 1.5, y, z + slot + 0.5);
            case WEST -> new Position(x - 0.5, y, z - slot + 0.5);
            case NORTH -> new Position(x + slot + 0.5, y, z - 0.5);
            case SOUTH -> new Position(x - slot + 0.5, y, z + 1.5);
        };
    }

    public static Result run(Facing facing, int x, int y, int z, IntFunction<Kind> slotKinds,
            Predicate<Position> occupied, Spawner spawner) {
        List<Step> steps = new ArrayList<>();
        List<UUID> ordinaryCars = new ArrayList<>();
        UUID head = null;
        int stoppedAt = -1;
        for (int slot = 0; slot < SLOTS; slot++) {
            Kind kind = slotKinds.apply(slot);
            Position position = position(facing, x, y, z, slot);
            // OLD checks for a cart before deciding whether the template slot is empty.
            if (occupied.test(position)) {
                steps.add(new Step(slot, kind, position, Action.BLOCKED, null));
                stoppedAt = slot;
                break;
            }
            if (kind == Kind.EMPTY || kind == Kind.OTHER) {
                steps.add(new Step(slot, kind, position, Action.SKIP, null));
                continue;
            }
            UUID id = spawner.spawn(slot, kind, position);
            steps.add(new Step(slot, kind, position, Action.SPAWN, id));
            if (kind == Kind.LOCOMOTIVE && slot == 0) head = id;
            else if (kind != Kind.LOCOMOTIVE) ordinaryCars.add(id);
        }
        return new Result(steps, head, head == null ? List.of() : ordinaryCars, stoppedAt);
    }
}
