package com.ericchiu.simplerail.entity;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import net.minecraft.core.HolderLookup;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.Tag;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.level.saveddata.SavedData;

/** NEW-only per-dimension index. Positions are observed entity positions, never TrainStops. */
public final class LocomotiveChunkData extends SavedData {
    private static final String FILE = "simplerail_locomotive_chunks";
    private static final Factory<LocomotiveChunkData> FACTORY =
            new Factory<>(LocomotiveChunkData::new, LocomotiveChunkData::load);
    public record Entry(Map<UUID, Long> positions, Set<Long> chunks) {
        public Entry { positions = Map.copyOf(positions); chunks = Set.copyOf(chunks); }
    }
    private final Map<UUID, Entry> owners = new HashMap<>();

    public static LocomotiveChunkData forLevel(ServerLevel level) {
        return level.getDataStorage().computeIfAbsent(FACTORY, FILE);
    }
    public Map<UUID, Entry> entries() { return Map.copyOf(owners); }
    public Entry get(UUID owner) { return owners.get(owner); }
    public void put(UUID owner, Map<UUID, Long> positions, Set<Long> chunks) {
        Entry next = new Entry(positions, chunks);
        if (!next.equals(owners.put(owner, next))) setDirty();
    }
    public void remove(UUID owner) { if (owners.remove(owner) != null) setDirty(); }
    public void clear() { if (!owners.isEmpty()) { owners.clear(); setDirty(); } }

    public static LocomotiveChunkData load(CompoundTag tag, HolderLookup.Provider ignored) {
        if (tag.getInt("Schema") != 1) throw new IllegalArgumentException("Unsupported locomotive chunk index schema");
        LocomotiveChunkData data = new LocomotiveChunkData();
        ListTag rows = tag.getList("Owners", Tag.TAG_COMPOUND);
        for (int i = 0; i < rows.size(); i++) {
            CompoundTag row = rows.getCompound(i);
            if (!row.hasUUID("Owner")) continue;
            UUID owner = row.getUUID("Owner");
            Map<UUID, Long> positions = new HashMap<>();
            ListTag places = row.getList("Positions", Tag.TAG_COMPOUND);
            for (int j = 0; j < places.size(); j++) {
                CompoundTag place = places.getCompound(j);
                if (place.hasUUID("Entity") && place.contains("Pos", Tag.TAG_LONG))
                    positions.put(place.getUUID("Entity"), place.getLong("Pos"));
            }
            Set<Long> chunks = new HashSet<>();
            for (long chunk : row.getLongArray("Chunks")) chunks.add(chunk);
            if (positions.containsKey(owner)) data.owners.putIfAbsent(owner, new Entry(positions, chunks));
        }
        return data;
    }

    @Override
    public CompoundTag save(CompoundTag tag, HolderLookup.Provider ignored) {
        tag.putInt("Schema", 1);
        ListTag rows = new ListTag();
        owners.forEach((owner, entry) -> {
            CompoundTag row = new CompoundTag();
            row.putUUID("Owner", owner);
            row.putLongArray("Chunks", entry.chunks().stream().mapToLong(Long::longValue).toArray());
            ListTag places = new ListTag();
            entry.positions().forEach((id, pos) -> {
                CompoundTag place = new CompoundTag();
                place.putUUID("Entity", id); place.putLong("Pos", pos); places.add(place);
            });
            row.put("Positions", places); rows.add(row);
        });
        tag.put("Owners", rows);
        return tag;
    }
}
