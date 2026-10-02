package com.ericchiu.simplerail.block;

import com.ericchiu.simplerail.blockentity.SignalTimerBlockEntity;
import com.ericchiu.simplerail.blockentity.SignalTimerTiming;
import com.ericchiu.simplerail.config.CommonConfig;
import com.ericchiu.simplerail.registry.ModBlockEntities;
import com.mojang.serialization.MapCodec;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.util.RandomSource;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.EntityBlock;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.entity.BlockEntityTicker;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.level.block.state.properties.IntegerProperty;
import net.minecraft.world.ticks.TickPriority;

/** A ten-tick redstone pulse followed by the configured idle interval. */
public final class SignalTimerBlock extends Block implements EntityBlock {
    public static final MapCodec<SignalTimerBlock> CODEC = simpleCodec(SignalTimerBlock::new);
    public static final IntegerProperty LEVEL = IntegerProperty.create("level", 0, 9);
    public static final BooleanProperty POWERED = BlockStateProperties.POWERED;

    public SignalTimerBlock(BlockBehaviour.Properties properties) {
        super(properties);
        registerDefaultState(defaultBlockState().setValue(LEVEL, 0).setValue(POWERED, false));
    }

    @Override
    protected MapCodec<SignalTimerBlock> codec() {
        return CODEC;
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        super.createBlockStateDefinition(builder);
        builder.add(LEVEL, POWERED);
    }

    @Override
    protected boolean isSignalSource(BlockState state) {
        return true;
    }

    @Override
    protected int getSignal(BlockState state, BlockGetter level, BlockPos pos, Direction direction) {
        return state.getValue(LEVEL) > 0 && state.getValue(POWERED) ? 15 : 0;
    }

    @Override
    protected void tick(BlockState state, ServerLevel level, BlockPos pos, RandomSource random) {
        int settingLevel = state.getValue(LEVEL);
        if (settingLevel == 0) {
            if (state.getValue(POWERED)) {
                level.setBlock(pos, state.setValue(POWERED, false), Block.UPDATE_ALL);
            }
            return;
        }

        boolean powered = state.getValue(POWERED);
        level.setBlock(pos, state.setValue(POWERED, !powered), Block.UPDATE_ALL);
        // The next delay is selected when the edge occurs, so a config reload takes
        // effect at the next edge rather than rewriting an already queued tick.
        int delay = powered ? SignalTimerTiming.offTicks(CommonConfig.current().signalIntervalSeconds(settingLevel))
                : CommonConfig.SIGNAL_PULSE_TICKS;
        level.scheduleTick(pos, this, delay, TickPriority.VERY_HIGH);
    }

    @Override
    public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return new SignalTimerBlockEntity(pos, state);
    }

    @Override
    public <T extends BlockEntity> BlockEntityTicker<T> getTicker(Level level, BlockState state,
            BlockEntityType<T> type) {
        if (level.isClientSide || type != ModBlockEntities.SIGNAL_TIMER.get()) {
            return null;
        }
        return (world, pos, blockState, entity) -> SignalTimerBlockEntity.serverTick(
                world, pos, blockState, (SignalTimerBlockEntity) entity);
    }
}
