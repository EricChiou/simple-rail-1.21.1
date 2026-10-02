package com.ericchiu.simplerail.block;

import com.ericchiu.simplerail.block.base.BasePoweredRail;
import com.ericchiu.simplerail.blockentity.TimerHoldingRailBlockEntity;
import com.ericchiu.simplerail.config.CommonConfig;
import com.ericchiu.simplerail.registry.ModBlockEntities;
import com.mojang.serialization.MapCodec;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.EntityBlock;
import net.minecraft.world.level.block.PoweredRailBlock;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.entity.BlockEntityTicker;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.EnumProperty;
import net.minecraft.world.level.block.state.properties.IntegerProperty;
import net.minecraft.world.phys.Vec3;

public final class TimerHoldingRail extends BasePoweredRail implements EntityBlock {
    public static final MapCodec<PoweredRailBlock> CODEC = simpleCodec(TimerHoldingRail::new);
    public static final IntegerProperty LEVEL = IntegerProperty.create("level", 0, 9);
    public static final EnumProperty<Direction> DIRECTION = EnumProperty.create("direction", Direction.class);

    public TimerHoldingRail(BlockBehaviour.Properties properties) {
        super(properties);
        // Use the NEW enum's first value, matching an any() default; a new wait records the cart direction.
        registerDefaultState(defaultBlockState().setValue(LEVEL, 0).setValue(DIRECTION, Direction.DOWN));
    }

    @Override
    public MapCodec<PoweredRailBlock> codec() {
        return CODEC;
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        super.createBlockStateDefinition(builder);
        builder.add(LEVEL, DIRECTION);
    }

    @Override
    public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return new TimerHoldingRailBlockEntity(pos, state);
    }

    @Override
    public <T extends BlockEntity> BlockEntityTicker<T> getTicker(Level level, BlockState state,
            BlockEntityType<T> type) {
        if (level.isClientSide || type != ModBlockEntities.TIMER_HOLDING_RAIL.get()) {
            return null;
        }
        return (world, pos, blockState, entity) -> TimerHoldingRailBlockEntity.serverTick(
                world, pos, blockState, (TimerHoldingRailBlockEntity) entity);
    }

    @Override
    public void onMinecartPass(BlockState state, Level level, BlockPos pos, AbstractMinecart cart) {
        if (level.isClientSide) {
            return;
        }
        int settingLevel = state.getValue(LEVEL);
        if (settingLevel == 0 || !(level.getBlockEntity(pos) instanceof TimerHoldingRailBlockEntity timer)) {
            if (!cart.getDeltaMovement().equals(Vec3.ZERO)) {
                cart.setDeltaMovement(cart.getDeltaMovement().scale(1.2D));
            }
            return;
        }
        if (timer.ownsCart(cart.getUUID())) {
            if (timer.readyToRelease()) {
                Direction direction = state.getValue(DIRECTION);
                cart.setDeltaMovement(direction.getStepX() * 0.4D,
                        direction.getStepY() * 0.4D, direction.getStepZ() * 0.4D);
            } else {
                stopCart(pos, cart);
            }
        } else {
            // Capture one loaded server config snapshot for this new wait, not static registry initialization.
            int seconds = CommonConfig.current().holdingWaitSeconds(settingLevel);
            level.setBlock(pos, state.setValue(DIRECTION, cart.getMotionDirection()), Block.UPDATE_ALL);
            stopCart(pos, cart);
            timer.startWait(cart.getUUID(), seconds);
        }
    }

    private static void stopCart(BlockPos pos, AbstractMinecart cart) {
        cart.setDeltaMovement(Vec3.ZERO);
        cart.moveTo(pos, cart.getYRot(), cart.getXRot());
    }
}
