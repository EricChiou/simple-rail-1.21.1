import com.ericchiu.simplerail.entity.TrainTrail;
import java.util.List;

public final class TrainSpacingR2Test {
    private static int assertions;

    public static void main(String[] args) {
        check(TrainTrail.SPACING == 1.5D, "fixed requested interval");

        TrainTrail straight = new TrainTrail();
        straight.record(p(0, 0, 0), 3);
        straight.seedTail(p(-1, 0, 0), 1);
        straight.seedTail(p(-2, 0, 0), 2);
        straight.seedTail(p(-3, 0, 0), 3);
        check(!straight.readyFor(3), "do not move a partial consist before full route exists");
        straight.record(p(1, 0, 0), 3);
        check(!straight.readyFor(3), "whole consist still waits with route shorter than 4.5");
        straight.record(p(1.5, 0, 0), 3);
        check(straight.readyFor(3), "all three route targets exist");
        near(straight.target(0), p(0, 0, 0), "first target 1.5 behind head");
        near(straight.target(1), p(-1.5, 0, 0), "second target 3.0 behind head");
        near(straight.target(2), p(-3, 0, 0), "third target 4.5 behind head");
        nearDistance(straight.target(0), straight.target(1), 1.5, "first-to-second gap");
        nearDistance(straight.target(1), straight.target(2), 1.5, "second-to-third gap");

        TrainTrail restored = new TrainTrail();
        restored.load(straight.points(), 3);
        near(restored.target(2), straight.target(2), "saved route preserves 4.5 target");
        restored.record(p(1.5, 0, 0), 3);
        near(restored.target(1), straight.target(1), "stationary route remains stable");

        TrainTrail corner = new TrainTrail();
        corner.load(List.of(p(0, 0, 0), p(-1, 0, 0), p(-1, 0, -1),
                p(-1, 0, -2), p(-1, 0, -3), p(-1, 0, -4)), 3);
        near(corner.target(0), p(-1, 0, -0.5), "first cart takes curved route at 1.5");
        near(corner.target(1), p(-1, 0, -2), "second cart takes curved route at 3.0");
        near(corner.target(2), p(-1, 0, -3.5), "third cart takes curved route at 4.5");

        corner.record(p(20, 0, 0), 3);
        check(!corner.readyFor(3), "long teleport resets obsolete route");
        System.out.println("TrainSpacingR2Test assertions=" + assertions + " PASS");
    }

    private static TrainTrail.Point p(double x, double y, double z) {
        return new TrainTrail.Point(x, y, z);
    }

    private static void near(TrainTrail.Point actual, TrainTrail.Point expected, String label) {
        check(actual != null && actual.distanceTo(expected) < 1.0E-9, label);
    }

    private static void nearDistance(TrainTrail.Point first, TrainTrail.Point second, double expected, String label) {
        check(first != null && second != null && Math.abs(first.distanceTo(second) - expected) < 1.0E-9, label);
    }

    private static void check(boolean condition, String label) {
        assertions++;
        if (!condition) throw new AssertionError(label);
    }
}
