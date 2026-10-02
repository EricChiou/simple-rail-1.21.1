package com.ericchiu.simplerail.entity;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import net.minecraft.core.HolderLookup;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.Tag;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.level.saveddata.SavedData;

/** Per-dimension ownership index; the locomotive's ordered list remains authoritative. */
public final class TrainOwnershipData extends SavedData {
    private static final String FILE_ID = "simplerail_train_owners";
    private static final SavedData.Factory<TrainOwnershipData> FACTORY =
            new SavedData.Factory<>(TrainOwnershipData::new, TrainOwnershipData::load);
    private final Map<UUID, UUID> cartOwners = new HashMap<>();
    private final Map<UUID, Set<UUID>> pendingCuts = new HashMap<>();
    private final Set<UUID> pendingRemovals = new HashSet<>();

    public static TrainOwnershipData forLevel(ServerLevel level) {
        return level.getDataStorage().computeIfAbsent(FACTORY, FILE_ID);
    }

    private static TrainOwnershipData load(CompoundTag tag, HolderLookup.Provider ignored) {
        TrainOwnershipData data = new TrainOwnershipData();
        ListTag rows = tag.getList("Owners", Tag.TAG_COMPOUND);
        for (int i = 0; i < rows.size(); i++) {
            CompoundTag row = rows.getCompound(i);
            if (row.hasUUID("Cart") && row.hasUUID("Owner")) {
                data.cartOwners.putIfAbsent(row.getUUID("Cart"), row.getUUID("Owner"));
            }
        }
        ListTag cuts = tag.getList("Cuts", Tag.TAG_COMPOUND);
        for (int i = 0; i < cuts.size(); i++) {
            CompoundTag row = cuts.getCompound(i);
            if (row.hasUUID("Owner") && row.hasUUID("Cart")) {
                data.pendingCuts.computeIfAbsent(row.getUUID("Owner"), ignoredOwner -> new HashSet<>())
                        .add(row.getUUID("Cart"));
            }
        }
        ListTag removals = tag.getList("PendingRemovals", Tag.TAG_COMPOUND);
        for (int i = 0; i < removals.size(); i++) {
            CompoundTag row = removals.getCompound(i);
            if (row.hasUUID("Cart")) data.pendingRemovals.add(row.getUUID("Cart"));
        }
        return data;
    }

    @Override
    public CompoundTag save(CompoundTag tag, HolderLookup.Provider ignored) {
        ListTag rows = new ListTag();
        for (Map.Entry<UUID, UUID> entry : cartOwners.entrySet()) {
            CompoundTag row = new CompoundTag();
            row.putUUID("Cart", entry.getKey());
            row.putUUID("Owner", entry.getValue());
            rows.add(row);
        }
        tag.put("Owners", rows);
        ListTag cuts = new ListTag();
        for (Map.Entry<UUID, Set<UUID>> entry : pendingCuts.entrySet()) {
            for (UUID cart : entry.getValue()) {
                CompoundTag row = new CompoundTag();
                row.putUUID("Owner", entry.getKey());
                row.putUUID("Cart", cart);
                cuts.add(row);
            }
        }
        tag.put("Cuts", cuts);
        ListTag removals = new ListTag();
        for (UUID id : pendingRemovals) {
            CompoundTag row = new CompoundTag();
            row.putUUID("Cart", id);
            removals.add(row);
        }
        tag.put("PendingRemovals", removals);
        return tag;
    }

    public boolean claim(UUID cart, UUID owner) {
        UUID current = cartOwners.putIfAbsent(cart, owner);
        if (current == null) setDirty();
        return current == null || current.equals(owner);
    }

    public void release(UUID cart, UUID owner) {
        if (cartOwners.remove(cart, owner)) setDirty();
    }

    public void releaseTrain(UUID owner) {
        boolean changed = false;
        for (Iterator<Map.Entry<UUID, UUID>> it = cartOwners.entrySet().iterator(); it.hasNext();) {
            if (it.next().getValue().equals(owner)) {
                it.remove();
                changed = true;
            }
        }
        if (changed) setDirty();
        if (pendingCuts.remove(owner) != null) setDirty();
    }

    /** The head may be unloaded when a carriage is permanently removed. */
    public void markPendingCut(UUID owner, UUID cart) {
        if (pendingCuts.computeIfAbsent(owner, ignored -> new HashSet<>()).add(cart)) setDirty();
    }

    public List<UUID> takePendingCuts(UUID owner) {
        Set<UUID> cuts = pendingCuts.remove(owner);
        if (cuts == null) return List.of();
        setDirty();
        return List.copyOf(cuts);
    }

    public UUID ownerOf(UUID cart) {
        return cartOwners.get(cart);
    }

    public void markPendingRemoval(UUID cart) {
        if (pendingRemovals.add(cart)) setDirty();
    }

    public boolean takePendingRemoval(UUID cart) {
        if (!pendingRemovals.remove(cart)) return false;
        setDirty();
        return true;
    }
}
