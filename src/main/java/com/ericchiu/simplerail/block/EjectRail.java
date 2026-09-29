package com.ericchiu.simplerail.block;

import com.ericchiu.simplerail.block.base.BasePoweredRail;
import com.ericchiu.simplerail.config.CommonConfig;
import com.mojang.serialization.MapCodec;
import java.util.List;
import net.minecraft.core.BlockPos;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.PoweredRailBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.level.block.state.properties.RailShape;
import net.minecraft.world.phys.Vec3;

/** OLD side-of-rail coordinates, with the server player's position packet API. */
public final class EjectRail extends BasePoweredRail {
    public static final MapCodec<PoweredRailBlock> CODEC = simpleCodec(EjectRail::new);
    public static final BooleanProperty REVERSE = BooleanProperty.create("reverse");
    public static final BooleanProperty NEED_POWER = BooleanProperty.create("need_power");

    public EjectRail(BlockBehaviour.Properties properties) {
        super(properties);
        // Registry construction precedes config loading; placement projects loaded values.
        registerDefaultState(defaultBlockState().setValue(REVERSE, false).setValue(NEED_POWER, true));
    }

    @Override
    public MapCodec<PoweredRailBlock> codec() {
        return CODEC;
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        super.createBlockStateDefinition(builder);
        builder.add(REVERSE, NEED_POWER);
    }

    @Override
    public void onMinecartPass(BlockState state, Level level, BlockPos pos, AbstractMinecart cart) {
        if (level.isClientSide) {
            return;
        }
        CommonConfig.Snapshot config = CommonConfig.current();
        if (config.ejectNeedPower() && !state.getValue(POWERED)) {
            return;
        }
        List<Entity> passengers = List.copyOf(cart.getPassengers());
        if (passengers.isEmpty()) {
            return;
        }

        double offset = state.getValue(REVERSE)
                ? config.ejectTransportDistance() + 0.5D : -config.ejectTransportDistance() - 0.5D;
        boolean northSouth = state.getValue(SHAPE) == RailShape.NORTH_SOUTH;
        double x = pos.getX() + (northSouth ? offset : 0.5D);
        double z = pos.getZ() + (northSouth ? 0.5D : offset);
        cart.ejectPassengers();
        for (Entity passenger : passengers) {
            passenger.setDeltaMovement(Vec3.ZERO);
            if (passenger instanceof ServerPlayer player) {
                // ServerPlayer.moveTo only resets server tracking; teleportTo also sends the position.
                player.teleportTo(x, pos.getY(), z);
            } else {
                passenger.moveTo(x, pos.getY(), z);
            }
        }
    }

    @Override
    protected void onPlace(BlockState state, Level level, BlockPos pos, BlockState oldState, boolean moving) {
        if (!level.isClientSide && !oldState.is(this)) {
            state = state.setValue(NEED_POWER, CommonConfig.current().ejectNeedPower());
        }
        super.onPlace(state, level, pos, oldState, moving);
    }
}
