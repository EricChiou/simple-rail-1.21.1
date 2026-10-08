package com.ericchiu.simplerail.entity;

import com.ericchiu.simplerail.SimpleRail;
import com.ericchiu.simplerail.config.CommonConfig;
import com.mojang.logging.LogUtils;
import java.util.HashMap;
import java.util.HashSet;
import java.util.IdentityHashMap;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import net.minecraft.core.BlockPos;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.level.ChunkPos;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.common.NeoForge;
import net.neoforged.neoforge.common.world.chunk.RegisterTicketControllersEvent;
import net.neoforged.neoforge.common.world.chunk.TicketController;
import net.neoforged.neoforge.common.world.chunk.TicketHelper;
import net.neoforged.neoforge.event.entity.EntityJoinLevelEvent;
import net.neoforged.neoforge.event.entity.EntityLeaveLevelEvent;
import net.neoforged.neoforge.event.level.LevelEvent;
import net.neoforged.neoforge.event.tick.LevelTickEvent;
import net.neoforged.neoforge.event.tick.EntityTickEvent;

/** Approved D3 revision: whole-train rolling coverage and persistent current-set restoration. */
public final class LocomotiveChunkLoader {
    private static final TicketController CONTROLLER = new TicketController(
            ResourceLocation.fromNamespaceAndPath(SimpleRail.MODID, "locomotive"), LocomotiveChunkLoader::validate);
    private static final Map<ServerLevel, State> STATES = new IdentityHashMap<>();
    private static final class State {
        final Set<LocomotiveCartEntity> joined = new HashSet<>();
        final Map<UUID, LocomotiveCartEntity> heads = new HashMap<>();
        final Map<UUID, ChunkTicketSet> leases = new HashMap<>();
        final Set<UUID> warned = new HashSet<>();
        final Map<UUID, UUID> blockedCars = new HashMap<>();
        boolean restored;
    }
    private LocomotiveChunkLoader() {}
    private static State state(ServerLevel level) { return STATES.computeIfAbsent(level, ignored -> new State()); }

    public static void register(IEventBus modBus) {
        modBus.addListener(LocomotiveChunkLoader::registerController);
        NeoForge.EVENT_BUS.addListener(LocomotiveChunkLoader::onJoin);
        NeoForge.EVENT_BUS.addListener(LocomotiveChunkLoader::onLeave);
        NeoForge.EVENT_BUS.addListener(LocomotiveChunkLoader::onLevelTick);
        NeoForge.EVENT_BUS.addListener(LocomotiveChunkLoader::onUnload);
        NeoForge.EVENT_BUS.addListener(LocomotiveChunkLoader::onCarTick);
    }
    private static void registerController(RegisterTicketControllersEvent event) { event.register(CONTROLLER); }

    private static void validate(ServerLevel level, TicketHelper tickets) {
        // BEFORE reinstatement: remove only this controller's raw tickets. Restore our authoritative
        // R2 index on a safe level tick. R1 has no index, so this also cleans its historical tickets.
        tickets.getBlockTickets().keySet().forEach(tickets::removeAllTickets);
        tickets.getEntityTickets().keySet().forEach(tickets::removeAllTickets);
    }
    private static void onJoin(EntityJoinLevelEvent event) {
        if (event.getLevel() instanceof ServerLevel level && event.getEntity() instanceof LocomotiveCartEntity head)
            state(level).joined.add(head); // Never load chunks in Join (may precede FULL).
    }
    private static void onLeave(EntityLeaveLevelEvent event) {
        if (!(event.getLevel() instanceof ServerLevel level) || !(event.getEntity() instanceof LocomotiveCartEntity head)) return;
        Entity.RemovalReason reason = head.getRemovalReason();
        if (reason != null && (reason.shouldDestroy() || reason == Entity.RemovalReason.CHANGED_DIMENSION))
            release(level, head.getUUID());
        else if (head.isRemoved())
            state(level).heads.remove(head.getUUID()); // Unload is not permanent destruction.
    }
    private static void onLevelTick(LevelTickEvent.Pre event) {
        if (!(event.getLevel() instanceof ServerLevel level)) return;
        State state = state(level);
        LocomotiveChunkData data = LocomotiveChunkData.forLevel(level);
        for (LocomotiveCartEntity head : Set.copyOf(state.joined)) {
            state.joined.remove(head);
            if (!head.isRemoved() && head.level() == level
                    && (head.isAddedToLevel() || level.getEntity(head.getUUID()) == head)) state.heads.put(head.getUUID(), head);
        }
        if (!CommonConfig.current().locomotiveChunkLoadingEnabled()) {
            for (UUID owner : Set.copyOf(state.leases.keySet())) clearTickets(level, owner);
            data.clear(); // Includes owners not instantiated yet; no resurrection on next boot.
            state.blockedCars.clear();
            state.restored = true;
            return;
        }
        if (!state.restored) {
            data.setDirty(); // Establish R2 schema even in an empty level.
            for (var row : data.entries().entrySet()) {
                UUID owner = row.getKey();
                state.leases.computeIfAbsent(owner, ignored -> new ChunkTicketSet()).update(row.getValue().chunks(),
                        true, chunk -> ticket(level, owner, chunk, true), chunk -> ready(level, chunk),
                        chunk -> ticket(level, owner, chunk, false));
            }
            state.restored = true;
        }
        // Wait for entity IO, rather than inferring permanent deletion from getEntity(null).
        for (var row : data.entries().entrySet()) {
            if (state.heads.containsKey(row.getKey()) || row.getValue().chunks().isEmpty()) continue;
            Entity found = level.getEntity(row.getKey());
            if (found instanceof LocomotiveCartEntity head && !head.isRemoved()) {
                state.heads.put(row.getKey(), head);
            } else if (row.getValue().chunks().stream().allMatch(chunk -> ready(level, chunk))) {
                clearTickets(level, row.getKey());
                // Suspend unresolved index; don't delete entities or search the whole world.
                data.put(row.getKey(), row.getValue().positions(), Set.of());
                LogUtils.getLogger().warn("Suspended unresolved locomotive chunk owner {} in {}; load its actual location to recover",
                        row.getKey(), level.dimension().location());
            }
        }
        for (LocomotiveCartEntity head : Set.copyOf(state.heads.values())) {
            if (head.isRemoved() || head.level() != level) { state.heads.remove(head.getUUID()); continue; }
            prepare(head);
        }
    }

    /** Gate motion until current/next chunks AND linked carriage entities are ready. */
    public static boolean prepare(LocomotiveCartEntity head) {
        if (!(head.level() instanceof ServerLevel level) || !CommonConfig.current().locomotiveChunkLoadingEnabled()) return true;
        if (head.isRemoved()) return false;
        State state = state(level);
        state.heads.put(head.getUUID(), head);
        LocomotiveChunkData data = LocomotiveChunkData.forLevel(level);
        LocomotiveChunkData.Entry saved = data.get(head.getUUID());
        Map<UUID, Long> positions = new HashMap<>(saved == null ? Map.of() : saved.positions());
        Set<UUID> members = new HashSet<>(head.trainIds());
        members.add(head.getUUID());
        positions.keySet().retainAll(members);
        positions.put(head.getUUID(), head.blockPosition().asLong());
        boolean complete = true;
        Set<Long> wanted = new HashSet<>();
        Map<UUID, BlockPos> hints = head.chunkLoadingHints();
        for (UUID id : head.trainIds()) {
            Entity entity = level.getEntity(id);
            if (entity instanceof AbstractMinecart cart && !cart.isRemoved()) positions.put(id, cart.blockPosition().asLong());
            else {
                complete = false;
                // Stops are bounded search hints only, never saved as actual positions.
                if (!positions.containsKey(id) && hints.containsKey(id)) include(wanted, hints.get(id));
            }
        }
        positions.values().forEach(pos -> include(wanted, BlockPos.of(pos)));
        head.chunkLoadingTargets().values().forEach(pos -> include(wanted, pos));
        ChunkTicketSet lease = state.leases.computeIfAbsent(head.getUUID(), ignored -> new ChunkTicketSet());
        boolean canMove = lease.update(wanted, complete, chunk -> ticket(level, head.getUUID(), chunk, true),
                chunk -> ready(level, chunk), chunk -> ticket(level, head.getUUID(), chunk, false));
        state.blockedCars.values().removeIf(owner -> owner.equals(head.getUUID()));
        if (!canMove) for (UUID id : head.trainIds()) state.blockedCars.put(id, head.getUUID());
        data.put(head.getUUID(), positions, lease.applied());
        if (!complete && state.warned.add(head.getUUID()))
            LogUtils.getLogger().warn("Locomotive {} waiting for linked carriages; load missing cars or explicitly unlink them. No IDs deleted.", head.getUUID());
        else if (complete) state.warned.remove(head.getUUID());
        return canMove;
    }
    private static void include(Set<Long> chunks, BlockPos pos) { ChunkTicketSet.includeBuffer(chunks, pos.getX(), pos.getZ()); }
    private static boolean ready(ServerLevel level, long chunk) {
        return level.areEntitiesLoaded(chunk) && level.isPositionEntityTicking(new ChunkPos(chunk).getWorldPosition());
    }
    private static void ticket(ServerLevel level, UUID owner, long chunk, boolean add) {
        ChunkPos pos = new ChunkPos(chunk);
        CONTROLLER.forceChunk(level, owner, pos.x, pos.z, add, true);
    }
    private static void clearTickets(ServerLevel level, UUID owner) {
        state(level).blockedCars.values().removeIf(id -> id.equals(owner));
        ChunkTicketSet lease = state(level).leases.remove(owner);
        if (lease != null) lease.clear(chunk -> ticket(level, owner, chunk, false));
    }
    public static void release(ServerLevel level, UUID owner) {
        clearTickets(level, owner);
        LocomotiveChunkData.forLevel(level).remove(owner);
        State state = state(level);
        state.heads.remove(owner); state.warned.remove(owner);
        state.joined.removeIf(head -> head.getUUID().equals(owner));
    }
    private static void onUnload(LevelEvent.Unload event) {
        if (event.getLevel() instanceof ServerLevel level) STATES.remove(level); // Keep index for restart.
    }

    private static void onCarTick(EntityTickEvent.Pre event) {
        Entity cart = event.getEntity();
        if (cart instanceof AbstractMinecart && !(cart instanceof LocomotiveCartEntity)
                && cart.level() instanceof ServerLevel level) {
            State state = STATES.get(level);
            if (state != null && state.blockedCars.containsKey(cart.getUUID())
                    && CommonConfig.current().locomotiveChunkLoadingEnabled()) event.setCanceled(true);
        }
    }
}
