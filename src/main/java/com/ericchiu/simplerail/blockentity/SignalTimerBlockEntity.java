package com.ericchiu.simplerail.blockentity;

import com.ericchiu.simplerail.block.SignalTimerBlock;
import com.ericchiu.simplerail.config.CommonConfig;
import com.ericchiu.simplerail.registry.ModBlockEntities;
import net.minecraft.core.BlockPos;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.ticks.TickPriority;

/** Bootstraps a missing scheduled tick; the block itself owns subsequent edges. */
public final class SignalTimerBlockEntity extends BlockEntity {
    public SignalTimerBlockEntity(BlockPos pos, BlockState state) {
        super(ModBlockEntities.SIGNAL_TIMER.get(), pos, state);
    }

    public static void serverTick(Level level, BlockPos pos, BlockState state, SignalTimerBlockEntity entity) {
        if (!(level instanceof ServerLevel server) || !(state.getBlock() instanceof SignalTimerBlock block)) {
            return;
        }
        int settingLevel = state.getValue(SignalTimerBlock.LEVEL);
        if (settingLevel == 0) {
            if (state.getValue(SignalTimerBlock.POWERED)) {
                server.setBlock(pos, state.setValue(SignalTimerBlock.POWERED, false), Block.UPDATE_ALL);
            }
            return;
        }
        if (!server.getBlockTicks().hasScheduledTick(pos, block)) {
            // A saved pending block tick takes precedence after chunk load. If none
            // exists, recover from the current BlockState without inventing NBT.
            int delay = state.getValue(SignalTimerBlock.POWERED)
                    ? CommonConfig.SIGNAL_PULSE_TICKS
                    : SignalTimerTiming.offTicks(CommonConfig.current().signalIntervalSeconds(settingLevel));
            server.scheduleTick(pos, block, delay, TickPriority.VERY_HIGH);
        }
    }
}
