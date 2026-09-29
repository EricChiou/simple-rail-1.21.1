package com.ericchiu.simplerail.block;

import com.ericchiu.simplerail.block.base.BasePoweredRail;
import com.mojang.serialization.MapCodec;
import net.minecraft.world.level.block.PoweredRailBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;

/** The shared powered rail behavior is the entire OLD high-speed rail implementation. */
public final class HighSpeedRail extends BasePoweredRail {
    public static final MapCodec<PoweredRailBlock> CODEC = simpleCodec(HighSpeedRail::new);

    public HighSpeedRail(BlockBehaviour.Properties properties) {
        super(properties);
    }

    @Override
    public MapCodec<PoweredRailBlock> codec() {
        return CODEC;
    }
}
