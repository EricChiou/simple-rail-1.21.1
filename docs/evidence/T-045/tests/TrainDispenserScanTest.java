package evidence.t045;

import com.ericchiu.simplerail.block.TrainDispenserScan;
import com.ericchiu.simplerail.block.TrainDispenserScan.Facing;
import com.ericchiu.simplerail.block.TrainDispenserScan.Position;
import java.util.ArrayList;
import java.util.List;

/** Plain-JVM tests of the production scan, with independent OLD-source examples. */
public final class TrainDispenserScanTest {
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

        List<Integer> visited = new ArrayList<>();
        List<Position> occupiedChecks = new ArrayList<>();
        int checked = TrainDispenserScan.scan(Facing.NORTH, 10, 64, 20, 27,
                place -> { occupiedChecks.add(place); return place.equals(new Position(12.5, 64, 19.5)); },
                (slot, place) -> visited.add(slot));
        ok(checked == 3, "stops after checking blocked slot 2");
        ok(visited.equals(List.of(0, 1)), "slot 2 is not visited after occupancy");
        ok(occupiedChecks.size() == 3, "occupancy checked at every slot, including empty slot 1");

        visited.clear();
        checked = TrainDispenserScan.scan(Facing.WEST, 10, 64, 20, 27,
                place -> false, (slot, place) -> visited.add(slot));
        ok(checked == 27 && visited.size() == 27, "all 27 slots visited without a blocker");
        ok(visited.getFirst() == 0 && visited.getLast() == 26, "slot order stays 0 to 26");

        int[] attempts = {0};
        for (int event = 0; event < 2; event++) {
            TrainDispenserScan.scan(Facing.EAST, 10, 64, 20, 27,
                    place -> false, (slot, place) -> { if (slot == 0) attempts[0]++; });
        }
        ok(attempts[0] == 2, "two calls make two slot-zero attempts without scanner latch");

        boolean rejected = false;
        try {
            TrainDispenserScan.scan(Facing.NORTH, 0, 0, 0, 9, place -> false,
                    (slot, place) -> { throw new AssertionError("visited invalid size"); });
        } catch (IllegalArgumentException expected) {
            rejected = true;
        }
        ok(rejected, "rejects vanilla nine-slot size");
        System.out.println("PASS checks=" + checks + "; production scan only; MinecraftExecuted=false");
    }

    private static void at(Facing facing, int slot, Position expected) {
        ok(TrainDispenserScan.position(facing, 10, 64, 20, slot).equals(expected),
                facing + " slot " + slot);
    }

    private static void ok(boolean condition, String description) {
        checks++;
        if (!condition) throw new AssertionError(description);
    }
}
