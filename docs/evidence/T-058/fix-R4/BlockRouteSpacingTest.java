import com.ericchiu.simplerail.entity.TrainBlockRoute;
import com.ericchiu.simplerail.entity.TrainFormation;
import java.util.List;

/** Pure JVM checks for block-center history plus 1.25-block arc spacing. */
public final class BlockRouteSpacingTest {
    private static int assertions;

    private static TrainFormation.Cell cell(int x, int y, int z) {
        return new TrainFormation.Cell(x, y, z);
    }

    private static TrainBlockRoute.Point point(double x, double y, double z) {
        return new TrainBlockRoute.Point(x, y, z);
    }

    private static void check(boolean ok, String label) {
        assertions++;
        if (!ok) throw new AssertionError(label);
    }

    private static void near(TrainBlockRoute.Point actual, TrainBlockRoute.Point expected, String label) {
        check(actual != null && actual.distanceTo(expected) < 1.0E-9D, label);
    }

    public static void main(String[] args) {
        check(TrainBlockRoute.SPACING == 1.25D, "requested spacing");
        TrainBlockRoute straight = new TrainBlockRoute();
        straight.seedTail(cell(-1, 64, 0), 3);
        straight.seedTail(cell(-2, 64, 0), 3);
        straight.seedTail(cell(-3, 64, 0), 3);
        check(!straight.readyFor(point(0.5, 64, 0.5), 3), "insufficient route uses block stops");
        straight.record(cell(0, 64, 0), cell(1, 64, 0), 3);
        TrainBlockRoute.Point head = point(1.5, 64, 0.5);
        check(straight.readyFor(head, 3), "full route ready after block crossing");
        near(straight.target(head, 1), point(0.25, 64, 0.5), "first 1.25 back");
        near(straight.target(head, 2), point(-1.0, 64, 0.5), "second 2.5 back");
        near(straight.target(head, 3), point(-2.25, 64, 0.5), "third 3.75 back");
        near(straight.target(point(1.75, 64, 0.5), 1), point(0.5, 64, 0.5),
                "moving head shifts target without another block crossing");
        check(straight.cells().size() == 4, "only block crossings add route points");

        TrainBlockRoute restored = new TrainBlockRoute();
        restored.load(straight.cells(), 3);
        check(restored.cells().equals(straight.cells()), "saved route order round trips");
        near(restored.target(head, 3), straight.target(head, 3), "saved target round trips");

        TrainBlockRoute corner = new TrainBlockRoute();
        corner.load(List.of(cell(1, 64, 0), cell(0, 64, 0), cell(0, 64, -1),
                cell(0, 64, -2)), 3);
        TrainBlockRoute.Point cornerHead = point(2.5, 64, 0.5);
        check(corner.readyFor(cornerHead, 3), "corner has full route");
        near(corner.target(cornerHead, 1), point(1.25, 64, 0.5), "corner first");
        near(corner.target(cornerHead, 2), point(0.5, 64, 0.0), "corner second follows bend");
        near(corner.target(cornerHead, 3), point(0.5, 64, -1.25), "corner third follows bend");

        TrainBlockRoute slope = new TrainBlockRoute();
        slope.load(List.of(cell(1, 65, 0), cell(0, 64, 0), cell(-1, 64, 0)), 2);
        TrainBlockRoute.Point slopeHead = point(2.5, 66, 0.5);
        check(slope.readyFor(slopeHead, 2), "slope has full route");
        TrainBlockRoute.Point first = slope.target(slopeHead, 1);
        check(first.y() > 65 && first.y() < 66, "slope interpolates height");
        nearDistance(slopeHead, first, 1.25, "slope first arc distance");

        corner.record(cell(10, 64, 0), cell(20, 64, 0), 3);
        check(corner.cells().equals(List.of(cell(10, 64, 0))), "teleport discards stale path");
        check(corner.target(point(20.5, 64, 0.5), 1) == null, "teleport does not drag tail");
        corner.load(List.of(cell(0, 64, 0), cell(5, 64, 0)), 3);
        check(corner.cells().isEmpty(), "discontinuous saved path rejected");

        TrainBlockRoute loop = new TrainBlockRoute();
        loop.seedTail(cell(0, 64, 0), 2);
        loop.seedTail(cell(1, 64, 0), 2);
        loop.seedTail(cell(1, 64, 1), 2);
        loop.seedTail(cell(0, 64, 1), 2);
        loop.seedTail(cell(0, 64, 0), 2);
        check(loop.cells().size() == 5, "route can revisit an older block");

        TrainBlockRoute ahead = new TrainBlockRoute();
        ahead.seedTail(cell(1, 64, 0), 1);
        ahead.record(cell(0, 64, 0), cell(1, 64, 0), 1);
        check(ahead.cells().equals(List.of(cell(0, 64, 0))),
                "initial cart ahead cannot seed a backward route through the head");
        System.out.println("PASS: " + assertions + " assertions");
    }

    private static void nearDistance(TrainBlockRoute.Point a, TrainBlockRoute.Point b,
                                     double expected, String label) {
        check(Math.abs(a.distanceTo(b) - expected) < 1.0E-9D, label);
    }
}
