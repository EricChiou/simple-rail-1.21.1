package com.ericchiu.simplerail.registry;

import com.ericchiu.simplerail.SimpleRail;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.SoundType;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredBlock;
import net.neoforged.neoforge.registries.DeferredRegister;

/** T-019 ID skeleton. Plain Blocks intentionally have no rail, redstone or BE behavior yet. */
public final class ModBlocks {
    private static final DeferredRegister.Blocks BLOCKS = DeferredRegister.createBlocks(SimpleRail.MODID);

    public static final DeferredBlock<Block> HIGH_SPEED_RAIL = BLOCKS.registerSimpleBlock("high_speed_rail", railProperties());
    public static final DeferredBlock<Block> HOLDING_RAIL = BLOCKS.registerSimpleBlock("holding_rail", railProperties());
    public static final DeferredBlock<Block> ONEWAY_RAIL = BLOCKS.registerSimpleBlock("oneway_rail", railProperties());
    public static final DeferredBlock<Block> EJECT_RAIL = BLOCKS.registerSimpleBlock("eject_rail", railProperties());
    // The historical spelling is part of the public ID contract (D2).
    public static final DeferredBlock<Block> DESTORY_RAIL = BLOCKS.registerSimpleBlock("destory_rail", railProperties());
    public static final DeferredBlock<Block> TIMER_HOLDING_RAIL = BLOCKS.registerSimpleBlock("timer_holding_rail", railProperties());
    public static final DeferredBlock<Block> CROSS_RAIL = BLOCKS.registerSimpleBlock("cross_rail", railProperties());
    public static final DeferredBlock<Block> Y_CROSS_RAIL = BLOCKS.registerSimpleBlock("y_cross_rail", railProperties());
    public static final DeferredBlock<Block> Y_CROSS_RIGHT_RAIL = BLOCKS.registerSimpleBlock("y_cross_right_rail", railProperties());
    public static final DeferredBlock<Block> TRAIN_DISPENSER = BLOCKS.registerSimpleBlock("train_dispenser", machineProperties());
    public static final DeferredBlock<Block> SIGNAL_TIMER = BLOCKS.registerSimpleBlock("signal_timer", machineProperties());

    private ModBlocks() {}

    private static BlockBehaviour.Properties railProperties() {
        return BlockBehaviour.Properties.of().noCollission().strength(0.7F).sound(SoundType.METAL);
    }

    private static BlockBehaviour.Properties machineProperties() {
        return BlockBehaviour.Properties.of().strength(5.0F, 6.0F).sound(SoundType.METAL);
    }

    public static void register(IEventBus modEventBus) {
        BLOCKS.register(modEventBus);
    }
}
