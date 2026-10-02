package com.ericchiu.simplerail.entity;

import java.util.ArrayList;
import java.util.List;

/** Block-center history for spacing carriages along the route the locomotive took. */
public final class TrainBlockRoute {
    public static final double SPACING = 1.35D;
    private static final double MAX_SEGMENT = 2.5D;

    public record Point(double x, double y, double z) {
        public double distanceTo(Point other) {
            double dx = x - other.x;
            double dy = y - other.y;
            double dz = z - other.z;
            return Math.sqrt(dx * dx + dy * dy + dz * dz);
        }
    }

    private final List<TrainFormation.Cell> cells = new ArrayList<>(); // newest first

    public List<TrainFormation.Cell> cells() { return List.copyOf(cells); }

    /** Seed only a contiguous tail; initial stops are useful before a train has traveled. */
    public void seedTail(TrainFormation.Cell stop, int carriageCount) {
        if (stop == null || (!cells.isEmpty() && cells.getLast().equals(stop))) return;
        if (cells.isEmpty() || adjacent(cells.getLast(), stop)) {
            cells.add(stop);
            trim(carriageCount);
        }
    }

    /** Called once when the head crosses a block boundary, as in the OLD stop logic. */
    public void record(TrainFormation.Cell previous, TrainFormation.Cell current, int carriageCount) {
        if (previous == null || current == null) return;
        if (!adjacent(previous, current)) cells.clear(); // teleport or discontinuity
        if (!cells.isEmpty() && cells.getFirst().equals(current)) cells.clear(); // seeded cart was ahead
        if (cells.isEmpty() || !cells.getFirst().equals(previous)) {
            if (!cells.isEmpty() && !adjacent(previous, cells.getFirst())) cells.clear();
            cells.addFirst(previous);
        }
        trim(carriageCount);
    }

    public void load(List<TrainFormation.Cell> saved, int carriageCount) {
        cells.clear();
        if (saved == null) return;
        for (TrainFormation.Cell cell : saved) {
            if (cell == null || (!cells.isEmpty() && !adjacent(cells.getLast(), cell))) {
                cells.clear();
                return;
            }
            cells.add(cell);
        }
        trim(carriageCount);
    }

    public boolean readyFor(Point head, int carriageCount) {
        return carriageCount > 0 && target(head, carriageCount) != null;
    }

    /** Interpolate SPACING * ordinal blocks behind the actual head along block centers. */
    public Point target(Point head, int ordinal) {
        if (head == null || ordinal < 1) return null;
        double remaining = SPACING * ordinal;
        Point ahead = head;
        for (TrainFormation.Cell cell : cells) {
            Point behind = new Point(cell.x() + 0.5D, cell.y(), cell.z() + 0.5D);
            double segment = ahead.distanceTo(behind);
            if (segment > MAX_SEGMENT) return null;
            if (segment > 0.0D) {
                if (remaining <= segment) {
                    double part = remaining / segment;
                    return new Point(ahead.x() + (behind.x() - ahead.x()) * part,
                            ahead.y() + (behind.y() - ahead.y()) * part,
                            ahead.z() + (behind.z() - ahead.z()) * part);
                }
                remaining -= segment;
            }
            ahead = behind;
        }
        return null;
    }

    private static boolean adjacent(TrainFormation.Cell first, TrainFormation.Cell second) {
        return Math.abs(first.x() - second.x()) <= 1
                && Math.abs(first.y() - second.y()) <= 1
                && Math.abs(first.z() - second.z()) <= 1
                && !first.equals(second);
    }

    private void trim(int carriageCount) {
        int limit = (int) Math.min(8192L, Math.max(16L, carriageCount * 2L + 16L));
        while (cells.size() > limit) cells.removeLast();
    }
}
