package com.ericchiu.simplerail.registry;

import com.ericchiu.simplerail.SimpleRail;
import com.ericchiu.simplerail.blockentity.TimerHoldingRailBlockEntity;
import net.minecraft.core.registries.Registries;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.chunk.LevelChunk;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.common.NeoForge;
import net.neoforged.neoforge.event.level.ChunkEvent;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

public final class ModBlockEntities {
    private static final DeferredRegister<BlockEntityType<?>> TYPES =
            DeferredRegister.create(Registries.BLOCK_ENTITY_TYPE, SimpleRail.MODID);

    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<TimerHoldingRailBlockEntity>>
            TIMER_HOLDING_RAIL = TYPES.register("timer_holding_rail", () -> BlockEntityType.Builder.of(
                    TimerHoldingRailBlockEntity::new, ModBlocks.TIMER_HOLDING_RAIL.get()).build(null));

    private ModBlockEntities() {}

    public static void register(IEventBus modEventBus) {
        TYPES.register(modEventBus);
        NeoForge.EVENT_BUS.addListener(ModBlockEntities::onChunkUnload);
    }

    private static void onChunkUnload(ChunkEvent.Unload event) {
        if (event.getChunk() instanceof LevelChunk chunk && !chunk.getLevel().isClientSide) {
            boolean changed = false;
            for (BlockEntity entity : chunk.getBlockEntities().values()) {
                if (entity instanceof TimerHoldingRailBlockEntity timer) {
                    changed |= timer.pauseForUnload();
                }
            }
            if (changed) {
                // Do not request/reload a chunk or change any ticket policy during unloading.
                chunk.setUnsaved(true);
            }
        }
    }
}
