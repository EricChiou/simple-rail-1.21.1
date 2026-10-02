package com.ericchiu.simplerail.registry;

import com.ericchiu.simplerail.SimpleRail;
import com.ericchiu.simplerail.block.DestoryRail;
import com.ericchiu.simplerail.block.EjectRail;
import com.ericchiu.simplerail.block.HighSpeedRail;
import com.ericchiu.simplerail.block.HoldingRail;
import com.ericchiu.simplerail.block.OnewayRail;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.SoundType;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredBlock;
import net.neoforged.neoforge.registries.DeferredRegister;

/** Stable IDs. Five ordinary rails are implemented; other blocks remain placeholders. */
public final class ModBlocks {
    private static final DeferredRegister.Blocks BLOCKS = DeferredRegister.createBlocks(SimpleRail.MODID);

    public static final DeferredBlock<HighSpeedRail> HIGH_SPEED_RAIL = BLOCKS.registerBlock("high_speed_rail", HighSpeedRail::new, railProperties());
    public static final DeferredBlock<HoldingRail> HOLDING_RAIL = BLOCKS.registerBlock("holding_rail", HoldingRail::new, railProperties());
    public static final DeferredBlock<OnewayRail> ONEWAY_RAIL = BLOCKS.registerBlock("oneway_rail", OnewayRail::new, railProperties());
    public static final DeferredBlock<EjectRail> EJECT_RAIL = BLOCKS.registerBlock("eject_rail", EjectRail::new, railProperties());
    // The historical spelling is part of the public ID contract (D2).
    public static final DeferredBlock<DestoryRail> DESTORY_RAIL = BLOCKS.registerBlock("destory_rail", DestoryRail::new, railProperties());
    public static final DeferredBlock<evidence.t037.TimerProbe.ProbeRail> TIMER_HOLDING_RAIL = BLOCKS.registerBlock("timer_holding_rail", evidence.t037.TimerProbe.ProbeRail::new, railProperties());
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
