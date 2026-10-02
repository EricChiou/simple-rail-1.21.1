package com.ericchiu.simplerail.blockentity;

import com.ericchiu.simplerail.block.JunctionRoute;
import com.ericchiu.simplerail.registry.ModBlockEntities;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import net.minecraft.core.BlockPos;
import net.minecraft.core.HolderLookup;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.Tag;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockState;

/** Pending passages belong to one placed junction and survive its chunk's save/load. */
public final class JunctionRailBlockEntity extends BlockEntity {
    public record Passage(JunctionRoute.Cardinal direction, BlockPos destination,
                          double speed, float yRot, float xRot) {}

    private final Map<UUID, Passage> pending = new HashMap<>();

    public JunctionRailBlockEntity(BlockPos pos, BlockState state) {
        super(ModBlockEntities.JUNCTION_RAIL.get(), pos, state);
    }

    public void put(UUID cart, Passage passage) {
        pending.put(cart, passage);
        setChanged();
    }

    public Passage take(UUID cart) {
        Passage passage = pending.remove(cart);
        if (passage != null) setChanged();
        return passage;
    }

    @Override
    protected void saveAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.saveAdditional(tag, registries);
        ListTag rows = new ListTag();
        for (Map.Entry<UUID, Passage> entry : pending.entrySet()) {
            Passage value = entry.getValue();
            CompoundTag row = new CompoundTag();
            row.putUUID("Cart", entry.getKey());
            row.putString("Direction", value.direction().name());
            row.putLong("Destination", value.destination().asLong());
            row.putDouble("Speed", value.speed());
            row.putFloat("YRot", value.yRot());
            row.putFloat("XRot", value.xRot());
            rows.add(row);
        }
        tag.put("PendingPassages", rows);
    }

    @Override
    protected void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.loadAdditional(tag, registries);
        pending.clear();
        ListTag rows = tag.getList("PendingPassages", Tag.TAG_COMPOUND);
        for (int i = 0; i < rows.size(); i++) {
            CompoundTag row = rows.getCompound(i);
            if (!row.hasUUID("Cart") || !row.contains("Direction", Tag.TAG_STRING)
                    || !row.contains("Destination", Tag.TAG_LONG)
                    || !row.contains("Speed", Tag.TAG_DOUBLE)
                    || !row.contains("YRot", Tag.TAG_FLOAT)
                    || !row.contains("XRot", Tag.TAG_FLOAT)) continue;
            try {
                JunctionRoute.Cardinal direction = JunctionRoute.Cardinal.valueOf(row.getString("Direction"));
                double speed = row.getDouble("Speed");
                if (!Double.isFinite(speed) || speed <= 0.0D
                        || !Float.isFinite(row.getFloat("YRot"))
                        || !Float.isFinite(row.getFloat("XRot"))) continue;
                pending.putIfAbsent(row.getUUID("Cart"), new Passage(direction,
                        BlockPos.of(row.getLong("Destination")), speed,
                        row.getFloat("YRot"), row.getFloat("XRot")));
            } catch (IllegalArgumentException ignored) {
                // Invalid NEW entries cannot resume an unknown route.
            }
        }
    }
}
