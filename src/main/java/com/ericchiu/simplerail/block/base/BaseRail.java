package com.ericchiu.simplerail.block.base;

import com.ericchiu.simplerail.config.CommonConfig;
import com.mojang.serialization.MapCodec;
import net.minecraft.core.BlockPos;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.RailBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;

/** Shared OLD rail rules; vanilla retains shape, waterlogging and connection behavior. */
public class BaseRail extends RailBlock {
    public static final MapCodec<RailBlock> CODEC = simpleCodec(BaseRail::new);

    public BaseRail(BlockBehaviour.Properties properties) {
        super(properties);
    }

    @Override
    public MapCodec<RailBlock> codec() {
        return CODEC;
    }

    @Override
    public float getRailMaxSpeed(BlockState state, Level level, BlockPos pos, AbstractMinecart cart) {
        CommonConfig.Snapshot config = CommonConfig.current();
        return (float) config.railMaxSpeed();
    }

    @Override
    public boolean canMakeSlopes(BlockState state, BlockGetter level, BlockPos pos) {
        return false;
    }

    @Override
    public boolean canEntityDestroy(BlockState state, BlockGetter level, BlockPos pos, Entity entity) {
        return false;
    }
}
