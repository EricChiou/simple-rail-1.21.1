package com.ericchiu.simplerail.block;

/** Standalone numeric regression; does not load Minecraft classes or start a game. */
public final class AscentBoundaryTest {
    private static int checks;

    private static void require(boolean condition, String message) {
        checks++;
        if (!condition) throw new AssertionError(message);
    }

    public static void main(String[] args) {
        double halfWidth = (double) 0.98f / 2.0;
        // Flat [0,1), ascent [1,2), full upper support [2,3).
        double start = 0.8;
        double velocity = 0.8;
        double oldEnd = start + Math.min(velocity, 0.8f);
        require(oldEnd + halfWidth > 2.0, "Old movement must hit upper support");
        double blockedVelocity = 0.0; // Entity.move zeroes the blocked axis.
        double followingSlopeVelocity = blockedVelocity - 0.0078125;
        require(followingSlopeVelocity < 0.0, "Next ascending tick can reverse after collision");
        float limited = RailAscentMovementLimit.limit(0.8f, 2.0 - start, halfWidth);
        double end = start + Math.min(velocity, limited);
        require(end >= 1.0 && end + halfWidth < 2.0, "Must enter slope without support collision");
        double retained = velocity * 0.96 - (end - 1.0) * 0.05;
        require(retained - 0.0078125 > 0.0, "Counterexample retains forward momentum");

        // Sweep phases, speeds, cart occupancy and all four horizontal directions.
        // Signs/axes reduce to signed distance. Occupancy scales movement by 0.75.
        int oldCollisions = 0;
        for (float config : new float[] {0.4f, 0.8f, 2.0f}) {
            for (int direction = 0; direction < 4; direction++) {
                for (double occupancy : new double[] {1.0, 0.75}) {
                    for (int phase = 0; phase < 1000; phase++) {
                        double position = phase / 1000.0;
                        double incoming = Math.min(config, 1.2f); // Default NeoForge cart cap.
                        double requested = occupancy * incoming;
                        double original = Math.min(requested, config);
                        if (position + original + halfWidth > 2.0) oldCollisions++;
                        double bound = RailAscentMovementLimit.limit(config, 2.0 - position, halfWidth);
                        double actual = Math.min(requested, bound);
                        require(position + actual + halfWidth < 2.0, "Clearance violated");
                        require(actual >= 0.0 && actual <= original, "Movement sign or cap changed");
                        if (position + original >= 1.0) {
                            require(position + actual >= 1.0, "Protection stalled before slope entry");
                        }
                    }
                }
            }
        }
        require(oldCollisions > 0, "Sweep must include old collisions");
        require(RailAscentMovementLimit.limit(0.4f, 1.01, halfWidth) == 0.4f,
                "Vanilla-sized safe step must remain unchanged");
        require(RailAscentMovementLimit.limit(2.0f, 5.0, halfWidth) == 2.0f,
                "Safe configured speed must remain unchanged");
        require(RailAscentMovementLimit.limit(0.8f, 0.1, halfWidth) == 0.0f,
                "No negative movement when clearance exhausted");
        System.out.println("PASS checks=" + checks + "; oldSweepCollisions=" + oldCollisions
                + "; gameExecuted=false; geometryModelOnly=true");
    }
}
