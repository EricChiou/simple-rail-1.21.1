import com.ericchiu.simplerail.block.JunctionRoute;
import static com.ericchiu.simplerail.block.JunctionRoute.Cardinal.*;

/** Explicit geometric expectations, independent of production turning helpers. No Minecraft startup. */
public final class TCrossRouteTest {
    private static int checks;

    public static void main(String[] args) {
        // facing, right exit, left exit, stem exit
        var geometry = new JunctionRoute.Cardinal[][] {
            {NORTH, EAST, WEST, SOUTH}, {EAST, SOUTH, NORTH, WEST},
            {SOUTH, WEST, EAST, NORTH}, {WEST, NORTH, SOUTH, EAST}
        };
        for (var row : geometry) {
            for (var incoming : JunctionRoute.Cardinal.values()) {
                for (boolean powered : new boolean[] {false, true}) {
                    var expected = incoming == row[0] ? (powered ? row[2] : row[1]) : row[3];
                    check(JunctionRoute.Kind.T, incoming, row[0], powered, expected);
                    check(JunctionRoute.Kind.CROSS, incoming, row[0], powered, incoming);
                }
            }
        }
        System.out.println("PASS " + checks + " route assertions: 32 T-junction cases and 32 cross regressions; no Minecraft runtime");
    }

    private static void check(JunctionRoute.Kind kind, JunctionRoute.Cardinal incoming,
            JunctionRoute.Cardinal facing, boolean powered, JunctionRoute.Cardinal expected) {
        var actual = JunctionRoute.destination(kind, incoming, facing, powered);
        if (actual != expected) throw new AssertionError(kind + " incoming=" + incoming + " facing=" + facing
                + " powered=" + powered + " expected=" + expected + " actual=" + actual);
        checks++;
    }
}
