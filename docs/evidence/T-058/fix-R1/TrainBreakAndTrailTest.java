import com.ericchiu.simplerail.entity.TrainFormation;
import com.ericchiu.simplerail.entity.TrainTrail;
import java.util.List;
import java.util.UUID;

public final class TrainBreakAndTrailTest {
    private static int assertions;

    public static void main(String[] args) {
        UUID a = UUID.fromString("00000000-0000-0000-0000-000000000001");
        UUID b = UUID.fromString("00000000-0000-0000-0000-000000000002");
        UUID c = UUID.fromString("00000000-0000-0000-0000-000000000003");
        UUID d = UUID.fromString("00000000-0000-0000-0000-000000000004");
        TrainFormation train = new TrainFormation();
        train.add(a, new TrainFormation.Cell(-1, 64, 0));
        train.add(b, new TrainFormation.Cell(-2, 64, 0));
        train.add(c, new TrainFormation.Cell(-3, 64, 0));
        train.add(d, new TrainFormation.Cell(-4, 64, 0));
        check(train.disconnectFrom(b).equals(List.of(b, c, d)), "middle removal detaches entire tail");
        check(train.carts().equals(List.of(a)), "front carriage remains linked");
        check(train.stop(b) == null && train.stop(c) == null && train.stop(d) == null,
                "detached stops removed");
        check(train.disconnectFrom(b).isEmpty(), "repeat removal cannot cut again");
        check(train.disconnectFrom(a).equals(List.of(a)) && train.carts().isEmpty(),
                "first carriage removal detaches entire train");

        TrainTrail trail = new TrainTrail();
        trail.record(p(0, 0, 0), 2);
        trail.seedTail(p(-1, 0, 0), 1);
        trail.seedTail(p(-2, 0, 0), 2);
        check(!trail.readyFor(2), "insufficient route holds the whole consist together");
        trail.record(p(0.2, 0, 0), 2);
        check(!trail.readyFor(2), "first target alone cannot move into a stationary tail");
        trail.record(p(0.4, 0, 0), 2);
        check(trail.readyFor(2), "all carriages get path targets after departure");
        near(trail.target(0), p(-0.8, 0, 0), "first carriage follows actual head path");
        near(trail.target(1), p(-2, 0, 0), "second carriage follows at 2.4 blocks");
        check(Math.abs(trail.target(0).distanceTo(trail.target(1)) - 1.2) < 1.0E-9,
                "straight carriages keep 1.2-block center spacing");

        TrainTrail restored = new TrainTrail();
        restored.load(trail.points(), 2);
        near(restored.target(0), trail.target(0), "saved route restores first target");
        near(restored.target(1), trail.target(1), "saved route restores second target");
        restored.record(p(0.4, 0, 0), 2);
        near(restored.target(0), trail.target(0), "stationary head preserves route");

        TrainTrail corner = new TrainTrail();
        corner.load(List.of(p(0, 0, 0), p(-1, 0, 0), p(-1, 0, -1), p(-1, 0, -2)), 2);
        near(corner.target(0), p(-1, 0, -0.2), "first carriage stays on route through corner");
        near(corner.target(1), p(-1, 0, -1.4), "second carriage follows corner rather than cutting it");

        corner.record(p(20, 0, 0), 2);
        check(corner.target(0) == null && corner.points().size() == 1,
                "teleport resets stale path without dragging carriages across the world");
        System.out.println("TrainBreakAndTrailTest assertions=" + assertions + " PASS");
    }

    private static TrainTrail.Point p(double x, double y, double z) {
        return new TrainTrail.Point(x, y, z);
    }

    private static void near(TrainTrail.Point actual, TrainTrail.Point expected, String label) {
        check(actual != null && actual.distanceTo(expected) < 1.0E-9, label);
    }

    private static void check(boolean ok, String label) {
        assertions++;
        if (!ok) throw new AssertionError(label);
    }
}
