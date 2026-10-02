import com.ericchiu.simplerail.block.JunctionRoute;
import static com.ericchiu.simplerail.block.JunctionRoute.Cardinal.*;

/** Explicit 32-case table, rotated from the user's fixed T diagram. No Minecraft. */
public final class TCrossRouteTest {
    public static void main(String[] args) {
        var facings = new JunctionRoute.Cardinal[] { NORTH, EAST, SOUTH, WEST };
        var incoming = new JunctionRoute.Cardinal[] { NORTH, EAST, SOUTH, WEST };
        // Per facing: off then on; columns are travel N,E,S,W (not entrance positions).
        var exits = new JunctionRoute.Cardinal[][] {
            {EAST,EAST,SOUTH,SOUTH}, {WEST,SOUTH,SOUTH,WEST},
            {WEST,SOUTH,SOUTH,WEST}, {NORTH,NORTH,WEST,WEST},
            {NORTH,NORTH,WEST,WEST}, {NORTH,EAST,EAST,NORTH},
            {NORTH,EAST,EAST,NORTH}, {EAST,EAST,SOUTH,SOUTH}
        };
        int checks = 0;
        for (int f=0; f<4; f++) for (int p=0; p<2; p++) for (int i=0; i<4; i++) {
            var expected = exits[f*2+p][i];
            var actual = JunctionRoute.destination(JunctionRoute.Kind.T, incoming[i], facings[f], p==1);
            if (actual != expected) throw new AssertionError("T facing="+facings[f]+" power="+p
                    +" incoming="+incoming[i]+" expected="+expected+" actual="+actual);
            checks++;
            if (JunctionRoute.destination(JunctionRoute.Kind.CROSS, incoming[i], facings[f], p==1) != incoming[i])
                throw new AssertionError("Cross regression");
            checks++;
        }
        System.out.println("PASS "+checks+" assertions: 32 fixed-T routes + 32 straight-cross regressions; no Minecraft");
    }
}
