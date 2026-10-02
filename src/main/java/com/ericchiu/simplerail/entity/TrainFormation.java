package com.ericchiu.simplerail.entity;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Ordered, per-locomotive persistent identity; entity references are never authoritative. */
public final class TrainFormation {
    public record Cell(int x, int y, int z) {}

    private final List<UUID> carts = new ArrayList<>();
    private final Map<UUID, Cell> stops = new HashMap<>();

    public List<UUID> carts() { return List.copyOf(carts); }
    public Cell stop(UUID cart) { return stops.get(cart); }

    public boolean add(UUID cart, Cell initialStop) {
        if (cart == null || initialStop == null || carts.contains(cart)) return false;
        carts.add(cart);
        stops.put(cart, initialStop);
        return true;
    }

    public boolean remove(UUID cart) {
        stops.remove(cart);
        return carts.remove(cart);
    }

    /** A destroyed carriage breaks the coupling to it and every carriage behind it. */
    public List<UUID> disconnectFrom(UUID cart) {
        int index = carts.indexOf(cart);
        if (index < 0) return List.of();
        List<UUID> detached = List.copyOf(carts.subList(index, carts.size()));
        for (UUID id : detached) stops.remove(id);
        carts.subList(index, carts.size()).clear();
        return detached;
    }

    public void load(List<UUID> ordered, Map<UUID, Cell> savedStops) {
        carts.clear();
        stops.clear();
        HashSet<UUID> seen = new HashSet<>();
        for (UUID cart : ordered) {
            if (cart != null && seen.add(cart)) {
                carts.add(cart);
                Cell stop = savedStops.get(cart);
                if (stop != null) stops.put(cart, stop);
            }
        }
    }

    /** Shift positions backwards; missing stops stay unresolved instead of erasing IDs. */
    public void advance(Cell previousHead) {
        if (previousHead == null || carts.isEmpty()) return;
        for (int i = carts.size() - 1; i > 0; i--) {
            Cell preceding = stops.get(carts.get(i - 1));
            if (preceding != null) stops.put(carts.get(i), preceding);
        }
        stops.put(carts.getFirst(), previousHead);
    }
}
