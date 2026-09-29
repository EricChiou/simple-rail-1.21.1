package com.ericchiu.simplerail.block;

import com.ericchiu.simplerail.block.base.BasePoweredRail;
import com.mojang.serialization.MapCodec;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.PoweredRailBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.EnumProperty;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.Vec3;

/** Stops unpowered carts and releases them in the direction stored in block state. */
public final class HoldingRail extends BasePoweredRail {
    public static final MapCodec<PoweredRailBlock> CODEC = simpleCodec(HoldingRail::new);
    // Keep the OLD name and full six-direction domain; normal carts supply horizontal directions.
    public static final EnumProperty<Direction> DIRECTION = EnumProperty.create("direction", Direction.class);

    public HoldingRail(BlockBehaviour.Properties properties) {
        super(properties);
        registerDefaultState(defaultBlockState().setValue(DIRECTION, Direction.NORTH));
    }

    @Override
    public MapCodec<PoweredRailBlock> codec() {
        return CODEC;
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        super.createBlockStateDefinition(builder);
        builder.add(DIRECTION);
    }

    @Override
    public void onMinecartPass(BlockState state, Level level, BlockPos pos, AbstractMinecart cart) {
        if (level.isClientSide || state.getValue(POWERED)) {
            return;
        }
        if (!cart.getDeltaMovement().equals(Vec3.ZERO)) {
            level.setBlock(pos, state.setValue(DIRECTION, cart.getMotionDirection()), Block.UPDATE_ALL);
        }
        cart.setDeltaMovement(Vec3.ZERO);
        cart.moveTo(pos, cart.getYRot(), cart.getXRot());
    }

    @Override
    protected void updateState(BlockState state, Level level, BlockPos pos, Block neighborBlock) {
        if (level.isClientSide) {
            return;
        }
        boolean wasPowered = state.getValue(POWERED);
        super.updateState(state, level, pos, neighborBlock);
        BlockState updated = level.getBlockState(pos);
        // The parent writes POWERED during updateState; the incoming state is the old value.
        if (updated.is(this) && !wasPowered && updated.getValue(POWERED)) {
            Direction direction = updated.getValue(DIRECTION);
            for (AbstractMinecart cart : level.getEntitiesOfClass(AbstractMinecart.class, new AABB(pos))) {
                cart.setDeltaMovement(direction.getStepX() * 0.4D,
                        direction.getStepY() * 0.4D, direction.getStepZ() * 0.4D);
            }
        }
    }
}
