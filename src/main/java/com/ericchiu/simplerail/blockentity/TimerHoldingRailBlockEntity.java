package com.ericchiu.simplerail.blockentity;

import com.ericchiu.simplerail.registry.ModBlockEntities;
import java.util.UUID;
import java.util.function.LongSupplier;
import net.minecraft.core.BlockPos;
import net.minecraft.core.HolderLookup;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockState;

public final class TimerHoldingRailBlockEntity extends BlockEntity {
    private final HoldingTimer timer;
    private long lastRemaining;

    public TimerHoldingRailBlockEntity(BlockPos pos, BlockState state) {
        this(pos, state, System::nanoTime);
    }

    TimerHoldingRailBlockEntity(BlockPos pos, BlockState state, LongSupplier clock) {
        super(ModBlockEntities.TIMER_HOLDING_RAIL.get(), pos, state);
        timer = new HoldingTimer(clock);
    }

    public boolean ownsCart(UUID cart) {
        return cart.equals(timer.cartUuid());
    }

    public void startWait(UUID cart, int seconds) {
        timer.start(cart, seconds);
        lastRemaining = timer.remainingMillis();
        setChanged();
    }

    public boolean readyToRelease() {
        timer.resume();
        return timer.remainingMillis() == 0;
    }

    public static void serverTick(Level level, BlockPos pos, BlockState state,
            TimerHoldingRailBlockEntity entity) {
        if (level.isClientSide) {
            return;
        }
        entity.timer.resume();
        long remaining = entity.timer.remainingMillis();
        if (remaining != entity.lastRemaining) {
            // Persistence only; unlike setChanged(), this does not notify neighbours each tick.
            level.blockEntityChanged(pos);
            entity.lastRemaining = remaining;
        }
    }

    /** Called before ChunkMap's unload save; caller marks the event's chunk directly. */
    public boolean pauseForUnload() {
        timer.pause();
        lastRemaining = timer.remainingMillis();
        return timer.cartUuid() != null;
    }

    @Override
    protected void saveAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.saveAdditional(tag, registries);
        // Snapshot at serialization, without restarting or pausing the still-loaded timer.
        tag.put(HoldingTimerData.KEY, HoldingTimerData.encode(timer.cartUuid(), timer.remainingMillis()));
    }

    @Override
    protected void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.loadAdditional(tag, registries);
        HoldingTimerData.Snapshot data = HoldingTimerData.decode(tag.getCompound(HoldingTimerData.KEY));
        timer.restore(data.cart(), data.remainingMillis());
        lastRemaining = data.remainingMillis();
    }
}
