package evidence.t043;

import evidence.t043.DispenserSourceModel.Action;
import evidence.t043.DispenserSourceModel.Facing;
import evidence.t043.DispenserSourceModel.Kind;
import evidence.t043.DispenserSourceModel.Position;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

/** Tests positions and loop boundaries from explicit OLD-source examples. */
public final class DispenserSourceModelTest {
    private static int checks;

    public static void main(String[] args) {
        at(Facing.EAST, 0, new Position(11.5, 64, 20.5));
        at(Facing.EAST, 26, new Position(11.5, 64, 46.5));
        at(Facing.WEST, 0, new Position(9.5, 64, 20.5));
        at(Facing.WEST, 26, new Position(9.5, 64, -5.5));
        at(Facing.NORTH, 0, new Position(10.5, 64, 19.5));
        at(Facing.NORTH, 26, new Position(36.5, 64, 19.5));
        at(Facing.SOUTH, 0, new Position(10.5, 64, 21.5));
        at(Facing.SOUTH, 26, new Position(-15.5, 64, 21.5));

        AtomicInteger spawned = new AtomicInteger();
        var first = DispenserSourceModel.run(Facing.EAST, 10, 64, 20,
                i -> i == 0 ? Kind.LOCOMOTIVE : i == 2 ? Kind.EMPTY : Kind.CHEST,
                p -> false, (i, k, p) -> id(spawned.incrementAndGet()));
        ok(first.steps().size() == 27 && spawned.get() == 26 && first.stoppedAt() == -1,
                "empty slot skips without terminating the loop");
        ok(first.headAtSlotZero() != null && first.linkedCars().size() == 25,
                "only a head at slot zero plans links to all ordinary carts");
        ok(first.steps().get(2).action() == Action.SKIP && first.steps().get(3).action() == Action.SPAWN,
                "gap preserves later slots");

        spawned.set(0);
        var blocked = DispenserSourceModel.run(Facing.NORTH, 10, 64, 20,
                i -> i == 2 ? Kind.EMPTY : Kind.RIDEABLE,
                p -> p.equals(new Position(12.5, 64, 19.5)),
                (i, k, p) -> id(spawned.incrementAndGet()));
        ok(blocked.stoppedAt() == 2 && blocked.steps().size() == 3 && spawned.get() == 2,
                "an existing cart at even an empty template slot breaks the scan");
        ok(blocked.steps().get(2).action() == Action.BLOCKED,
                "blocked position is recorded");

        var laterHead = DispenserSourceModel.run(Facing.SOUTH, 10, 64, 20,
                i -> i == 1 ? Kind.LOCOMOTIVE : i == 0 ? Kind.RIDEABLE : Kind.EMPTY,
                p -> false, (i, k, p) -> id(i + 1));
        ok(laterHead.headAtSlotZero() == null && laterHead.linkedCars().isEmpty(),
                "head outside slot zero does not link earlier/later cars");

        spawned.set(0);
        for (int trigger = 0; trigger < 2; trigger++) {
            var result = DispenserSourceModel.run(Facing.WEST, 10, 64, 20,
                    i -> i == 0 ? Kind.TNT : Kind.EMPTY, p -> false,
                    (i, k, p) -> id(spawned.incrementAndGet()));
            ok(result.steps().get(0).action() == Action.SPAWN,
                    "powered neighbor event has no model-level edge latch");
        }
        ok(spawned.get() == 2, "two powered neighbor events can produce two attempts");
        var empty = DispenserSourceModel.run(Facing.EAST, 10, 64, 20,
                i -> Kind.EMPTY, p -> false, (i, k, p) -> { throw new AssertionError("empty slot spawned"); });
        ok(empty.steps().stream().allMatch(s -> s.action() == Action.SKIP),
                "empty template does not spawn");
        System.out.println("PASS checks=" + checks + "; model only; MinecraftExecuted=false");
    }

    private static void at(Facing direction, int slot, Position expected) {
        ok(DispenserSourceModel.position(direction, 10, 64, 20, slot).equals(expected),
                direction + " slot " + slot);
    }

    private static UUID id(int value) {
        return new UUID(0, value);
    }

    private static void ok(boolean pass, String message) {
        checks++;
        if (!pass) throw new AssertionError(message);
    }
}
