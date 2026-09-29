package com.ericchiu.simplerail.block;

import com.ericchiu.simplerail.block.base.BasePoweredRail;
import com.ericchiu.simplerail.config.CommonConfig;
import com.mojang.serialization.MapCodec;
import net.minecraft.core.BlockPos;
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

/** OLD oneway branches; the power-mode name does not imply a direction flip (U-07). */
public final class OnewayRail extends BasePoweredRail {
    public static final MapCodec<PoweredRailBlock> CODEC = simpleCodec(OnewayRail::new);
    public static final BooleanProperty REVERSE = BooleanProperty.create("reverse");
    public static final BooleanProperty NEED_POWER = BooleanProperty.create("need_power");
    public static final BooleanProperty USE_POWER = BooleanProperty.create("use_power");

    public OnewayRail(BlockBehaviour.Properties properties) {
        super(properties);
        // Config is not loaded during registry construction. Placement projects loaded values.
        registerDefaultState(defaultBlockState().setValue(REVERSE, false)
                .setValue(NEED_POWER, true).setValue(USE_POWER, false));
    }

    @Override
    public MapCodec<PoweredRailBlock> codec() {
        return CODEC;
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        super.createBlockStateDefinition(builder);
        builder.add(REVERSE, NEED_POWER, USE_POWER);
    }

    @Override
    public void onMinecartPass(BlockState state, Level level, BlockPos pos, AbstractMinecart cart) {
        if (level.isClientSide) {
            return;
        }
        CommonConfig.Snapshot config = CommonConfig.current();
        boolean active = config.onewayUsePowerChangeDirection()
                || state.getValue(POWERED) || !config.onewayNeedPower();
        if (active) {
            boolean reverse = state.getValue(REVERSE);
            if (state.getValue(SHAPE) == RailShape.NORTH_SOUTH) {
                cart.setDeltaMovement(0.0D, 0.0D, reverse ? 0.4D : -0.4D);
            } else {
                cart.setDeltaMovement(reverse ? -0.4D : 0.4D, 0.0D, 0.0D);
            }
        } else if (!cart.getDeltaMovement().equals(Vec3.ZERO)) {
            cart.setDeltaMovement(cart.getDeltaMovement().multiply(1.2D, 1.2D, 1.2D));
        }
    }

    @Override
    protected void onPlace(BlockState state, Level level, BlockPos pos, BlockState oldState, boolean moving) {
        if (!level.isClientSide && !oldState.is(this)) {
            CommonConfig.Snapshot config = CommonConfig.current();
            state = state.setValue(NEED_POWER, config.onewayNeedPower())
                    .setValue(USE_POWER, config.onewayUsePowerChangeDirection());
        }
        // BaseRailBlock -> updateDir -> RailState.place(alwaysPlace=true) writes this state.
        super.onPlace(state, level, pos, oldState, moving);
    }
}
