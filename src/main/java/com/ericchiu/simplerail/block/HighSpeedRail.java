package com.ericchiu.simplerail.block;

import com.ericchiu.simplerail.block.base.BasePoweredRail;
import com.mojang.serialization.MapCodec;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.BaseRailBlock;
import net.minecraft.world.level.block.PoweredRailBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.RailShape;

/** Powered rail behavior with the user-approved high-speed-only slope exception. */
public final class HighSpeedRail extends BasePoweredRail {
    public static final MapCodec<PoweredRailBlock> CODEC = simpleCodec(HighSpeedRail::new);

    public HighSpeedRail(BlockBehaviour.Properties properties) {
        super(properties);
    }

    @Override
    public MapCodec<PoweredRailBlock> codec() {
        return CODEC;
    }

    @Override
    public boolean canMakeSlopes(BlockState state, BlockGetter level, BlockPos pos) {
        return true;
    }

    @Override
    public float getRailMaxSpeed(BlockState state, Level level, BlockPos pos, AbstractMinecart cart) {
        float configured = super.getRailMaxSpeed(state, level, pos, cart);
        if (cart == null) {
            return configured;
        }
        RailShape shape = getRailDirection(state, level, pos, cart);
        boolean alongX = shape == RailShape.EAST_WEST
                || shape == RailShape.ASCENDING_EAST || shape == RailShape.ASCENDING_WEST;
        double motion = alongX ? cart.getDeltaMovement().x : cart.getDeltaMovement().z;
        if (motion == 0.0) {
            return configured;
        }
        Direction direction = alongX
                ? (motion > 0.0 ? Direction.EAST : Direction.WEST)
                : (motion > 0.0 ? Direction.SOUTH : Direction.NORTH);
        RailShape ascending = switch (direction) {
            case EAST -> RailShape.ASCENDING_EAST;
            case WEST -> RailShape.ASCENDING_WEST;
            case SOUTH -> RailShape.ASCENDING_SOUTH;
            case NORTH -> RailShape.ASCENDING_NORTH;
            default -> throw new IllegalStateException("Rail movement must be horizontal");
        };
        BlockPos nextPos = pos.relative(direction);
        if (shape == ascending) {
            nextPos = nextPos.above();
        }
        BlockState next = level.getBlockState(nextPos);
        if (!BaseRailBlock.isRail(next)
                || ((BaseRailBlock) next.getBlock()).getRailDirection(next, level, nextPos, cart) != ascending
                || cart.getY() >= nextPos.getY() + 1.0) {
            return configured;
        }

        // moveAlongTrack raises the cart only for the rail that starts this tick.
        // Enter the next ascent without hitting its upper support before that lift.
        double center = alongX ? cart.getX() : cart.getZ();
        double extent = (alongX ? cart.getBoundingBox().getXsize() : cart.getBoundingBox().getZsize()) * 0.5;
        int coordinate = alongX ? nextPos.getX() : nextPos.getZ();
        double supportFace = motion > 0.0 ? coordinate + 1.0 : coordinate;
        double distance = (supportFace - center) * Math.signum(motion);
        return RailAscentMovementLimit.limit(configured, distance, extent);
    }
}
