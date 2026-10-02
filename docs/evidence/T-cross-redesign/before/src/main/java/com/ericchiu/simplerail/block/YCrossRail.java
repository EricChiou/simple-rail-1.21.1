package com.ericchiu.simplerail.block;

import com.mojang.serialization.MapCodec;
import net.minecraft.world.level.block.RailBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;

public final class YCrossRail extends AbstractYCrossRail {
    public static final MapCodec<RailBlock> CODEC = simpleCodec(YCrossRail::new);

    public YCrossRail(BlockBehaviour.Properties properties) {
        super(properties);
    }

    @Override
    public MapCodec<RailBlock> codec() {
        return CODEC;
    }

    @Override
    protected JunctionRoute.Kind kind() {
        return JunctionRoute.Kind.LEFT;
    }
}
