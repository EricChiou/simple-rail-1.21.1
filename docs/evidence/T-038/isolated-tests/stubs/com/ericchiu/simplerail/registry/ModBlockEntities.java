package com.ericchiu.simplerail.registry;
import com.ericchiu.simplerail.blockentity.TimerHoldingRailBlockEntity;
import net.minecraft.world.level.block.entity.BlockEntityType;
/** Registry binding double; real DeferredRegister is verified by NEW build and source audit. */
public final class ModBlockEntities {
    public static final Holder TIMER_HOLDING_RAIL=new Holder();
    public static final class Holder {
        private final BlockEntityType<TimerHoldingRailBlockEntity> type=new BlockEntityType<>();
        public BlockEntityType<TimerHoldingRailBlockEntity> get(){return type;}
    }
}
