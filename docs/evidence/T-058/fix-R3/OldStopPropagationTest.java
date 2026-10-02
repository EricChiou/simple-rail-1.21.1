import com.ericchiu.simplerail.entity.TrainFormation;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Pure JVM check of the OLD block-stop propagation retained in NEW. */
public final class OldStopPropagationTest {
    private static int assertions;

    private static void check(boolean value, String name) {
        assertions++;
        if (!value) throw new AssertionError(name);
    }

    public static void main(String[] args) {
        UUID a = UUID.randomUUID();
        UUID b = UUID.randomUUID();
        UUID c = UUID.randomUUID();
        TrainFormation train = new TrainFormation();
        TrainFormation.Cell cell0 = new TrainFormation.Cell(0, 64, 0);
        TrainFormation.Cell cell1 = new TrainFormation.Cell(-1, 64, 0);
        TrainFormation.Cell cell2 = new TrainFormation.Cell(-2, 64, 0);
        check(train.add(a, cell0), "add A");
        check(train.add(b, cell1), "add B");
        check(train.add(c, cell2), "add C");

        train.advance(new TrainFormation.Cell(1, 64, 0));
        check(train.stop(a).equals(new TrainFormation.Cell(1, 64, 0)), "A follows prior head block");
        check(train.stop(b).equals(cell0), "B inherits A's prior stop");
        check(train.stop(c).equals(cell1), "C inherits B's prior stop");

        train.advance(new TrainFormation.Cell(2, 64, 0));
        check(train.stop(a).equals(new TrainFormation.Cell(2, 64, 0)), "A advances again");
        check(train.stop(b).equals(new TrainFormation.Cell(1, 64, 0)), "B advances again");
        check(train.stop(c).equals(cell0), "C advances again");

        train.advance(new TrainFormation.Cell(3, 64, 0));
        train.advance(new TrainFormation.Cell(3, 64, 1));
        check(train.stop(a).equals(new TrainFormation.Cell(3, 64, 1)), "turn A");
        check(train.stop(b).equals(new TrainFormation.Cell(3, 64, 0)), "turn B");
        check(train.stop(c).equals(new TrainFormation.Cell(2, 64, 0)), "turn C");

        check(train.disconnectFrom(b).equals(List.of(b, c)), "destroyed middle detaches tail");
        check(train.carts().equals(List.of(a)), "front remains attached");
        check(train.stop(b) == null && train.stop(c) == null, "detached stops removed");

        train.load(List.of(a, b), Map.of(a, cell0));
        check(train.carts().equals(List.of(a, b)), "unloaded cart UUID retained");
        check(train.stop(b) == null, "missing stop does not erase UUID");
        train.advance(new TrainFormation.Cell(4, 64, 0));
        check(train.stop(b).equals(cell0), "missing stop repaired on next advance");
        System.out.println("PASS: " + assertions + " assertions");
    }
}
