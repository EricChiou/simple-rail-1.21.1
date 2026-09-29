package com.ericchiu.simplerail.block;

/** Geometry bound for entering an ascent before the next tick lifts the cart. */
final class RailAscentMovementLimit {
    private static final double CLEARANCE = 1.0E-6;

    private RailAscentMovementLimit() {}

    static float limit(float configured, double distanceToSupport, double halfExtent) {
        double bound = Math.max(0.0, Math.min(configured, distanceToSupport - halfExtent - CLEARANCE));
        float result = (float) bound;
        // The hook returns float; rounding upward could reintroduce a collision.
        return result > bound ? Math.nextDown(result) : result;
    }
}
