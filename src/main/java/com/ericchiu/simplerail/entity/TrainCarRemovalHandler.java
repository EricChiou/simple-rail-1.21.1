package com.ericchiu.simplerail.entity;

import java.util.UUID;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.neoforged.neoforge.common.NeoForge;
import net.neoforged.neoforge.event.entity.EntityLeaveLevelEvent;
import net.neoforged.neoforge.event.entity.EntityJoinLevelEvent;

/** Disconnect only on permanent destruction; chunk unload must retain the ordered train. */
public final class TrainCarRemovalHandler {
    private TrainCarRemovalHandler() {}

    public static void register() {
        NeoForge.EVENT_BUS.addListener(TrainCarRemovalHandler::onEntityLeave);
        NeoForge.EVENT_BUS.addListener(TrainCarRemovalHandler::onEntityJoin);
    }

    private static void onEntityJoin(EntityJoinLevelEvent event) {
        if (!(event.getLevel() instanceof ServerLevel level)
                || !(event.getEntity() instanceof AbstractMinecart cart)
                || cart instanceof LocomotiveCartEntity) return;
        // This event precedes entity insertion. Canceling keeps a deleted, previously
        // unloaded carriage out of the live section and the next chunk save.
        if (TrainOwnershipData.forLevel(level).takePendingRemoval(cart.getUUID())) event.setCanceled(true);
    }

    private static void onEntityLeave(EntityLeaveLevelEvent event) {
        Entity entity = event.getEntity();
        if (!(entity instanceof AbstractMinecart) || entity instanceof LocomotiveCartEntity
                || !(event.getLevel() instanceof ServerLevel level)) return;
        Entity.RemovalReason reason = entity.getRemovalReason();
        if (reason == null || !reason.shouldDestroy()) return;

        TrainOwnershipData owners = TrainOwnershipData.forLevel(level);
        UUID owner = owners.ownerOf(entity.getUUID());
        if (owner == null) return;
        Entity found = level.getEntity(owner);
        if (found instanceof LocomotiveCartEntity head && !head.isRemoved()) {
            head.disconnectFrom(level, entity.getUUID());
        } else {
            owners.markPendingCut(owner, entity.getUUID());
        }
    }
}
