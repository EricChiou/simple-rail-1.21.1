import com.ericchiu.simplerail.entity.Facing8;
import com.ericchiu.simplerail.entity.TrainFormation;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public final class TrainFormationTest {
    private static int assertions;

    public static void main(String[] args) {
        UUID a = UUID.fromString("00000000-0000-0000-0000-000000000001");
        UUID b = UUID.fromString("00000000-0000-0000-0000-000000000002");
        UUID c = UUID.fromString("00000000-0000-0000-0000-000000000003");
        TrainFormation formation = new TrainFormation();
        check(formation.add(a, new TrainFormation.Cell(0, 64, 0)), "first link");
        check(formation.add(b, new TrainFormation.Cell(-1, 64, 0)), "second link");
        check(formation.add(c, new TrainFormation.Cell(-2, 64, 0)), "third link");
        check(!formation.add(b, new TrainFormation.Cell(50, 64, 0)), "duplicate refused");
        check(formation.carts().equals(List.of(a, b, c)), "ordered IDs");
        formation.advance(new TrainFormation.Cell(1, 64, 0));
        check(formation.stop(a).equals(new TrainFormation.Cell(1, 64, 0)), "head previous position");
        check(formation.stop(b).equals(new TrainFormation.Cell(0, 64, 0)), "second follows first old stop");
        check(formation.stop(c).equals(new TrainFormation.Cell(-1, 64, 0)), "third follows second old stop");

        Map<UUID, TrainFormation.Cell> saved = new HashMap<>();
        saved.put(a, formation.stop(a));
        saved.put(c, formation.stop(c));
        TrainFormation restored = new TrainFormation();
        restored.load(List.of(a, b, c, b), saved);
        check(restored.carts().equals(List.of(a, b, c)), "late-loaded B and duplicate input retain unique order");
        check(restored.stop(b) == null, "unresolved B kept without invented stop");
        restored.advance(new TrainFormation.Cell(2, 64, 0));
        check(restored.carts().equals(List.of(a, b, c)), "unresolved cart does not truncate train");
        check(restored.remove(b), "explicit unlink succeeds");
        check(restored.carts().equals(List.of(a, c)), "explicit unlink only removes B");

        boolean[] wires = new boolean[8];
        for (Facing8 facing : Facing8.values()) {
            check(Facing8.fromWire(facing.wire()) == facing, "wire roundtrip " + facing);
            check(Facing8.fromSaved(facing.saved()) == facing, "saved roundtrip " + facing);
            check(!wires[facing.wire()], "unique wire " + facing);
            wires[facing.wire()] = true;
        }
        check(Facing8.fromWire((byte) 100) == Facing8.NORTH, "invalid wire fallback");
        check(Facing8.fromSaved("invalid") == Facing8.NORTH, "invalid saved fallback");
        check(Facing8.fromMotion(1, -1, Facing8.SOUTH) == Facing8.NORTH_EAST, "diagonal motion");
        check(Facing8.fromMotion(0, 0, Facing8.WEST) == Facing8.WEST, "stationary direction retained");
        System.out.println("TrainFormationTest assertions=" + assertions + " PASS");
    }

    private static void check(boolean condition, String label) {
        assertions++;
        if (!condition) throw new AssertionError(label);
    }
}
