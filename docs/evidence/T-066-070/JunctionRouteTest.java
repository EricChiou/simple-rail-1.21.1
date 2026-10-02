import com.ericchiu.simplerail.block.JunctionRoute;

/** Independent expectations copied from T-003/route-reference.md, not from production constants. */
public final class JunctionRouteTest {
    private static final JunctionRoute.Cardinal[] ORDER = {
            JunctionRoute.Cardinal.EAST, JunctionRoute.Cardinal.WEST,
            JunctionRoute.Cardinal.NORTH, JunctionRoute.Cardinal.SOUTH
    };
    private static final String[] LEFT_OFF = {"EESS", "WWSS", "EENN", "EESS"};
    private static final String[] LEFT_ON = {"NESE", "WSWN", "NEWN", "WSSE"};
    private static final String[] RIGHT_OFF = {"EESS", "WWSS", "EENN", "EESS"};
    private static final String[] RIGHT_ON = {"SEEN", "WNSW", "WNEN", "SESW"};

    public static void main(String[] args) {
        int checks = 0;
        for (int incoming = 0; incoming < 4; incoming++) {
            for (int facing = 0; facing < 4; facing++) {
                for (boolean powered : new boolean[] {false, true}) {
                    check(JunctionRoute.Kind.CROSS, incoming, facing, powered, ORDER[incoming]);
                    check(JunctionRoute.Kind.LEFT, incoming, facing, powered,
                            read((powered ? LEFT_ON : LEFT_OFF)[incoming].charAt(facing)));
                    check(JunctionRoute.Kind.RIGHT, incoming, facing, powered,
                            read((powered ? RIGHT_ON : RIGHT_OFF)[incoming].charAt(facing)));
                    checks += 3;
                }
            }
        }
        System.out.println("PASS " + checks + " OLD-source route assertions (no Minecraft runtime)");
    }

    private static JunctionRoute.Cardinal read(char code) {
        return switch (code) {
            case 'E' -> JunctionRoute.Cardinal.EAST;
            case 'W' -> JunctionRoute.Cardinal.WEST;
            case 'N' -> JunctionRoute.Cardinal.NORTH;
            case 'S' -> JunctionRoute.Cardinal.SOUTH;
            default -> throw new AssertionError(code);
        };
    }

    private static void check(JunctionRoute.Kind kind, int incoming, int facing,
                              boolean powered, JunctionRoute.Cardinal expected) {
        JunctionRoute.Cardinal actual = JunctionRoute.destination(kind, ORDER[incoming], ORDER[facing], powered);
        if (actual != expected) {
            throw new AssertionError(kind + " input=" + ORDER[incoming] + " facing=" + ORDER[facing]
                    + " powered=" + powered + " expected=" + expected + " actual=" + actual);
        }
    }
}
