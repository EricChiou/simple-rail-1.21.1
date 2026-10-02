package com.ericchiu.simplerail.block;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.level.block.state.properties.EnumProperty;

/** Shared state management; left and right use separate source-verified route tables. */
public abstract class AbstractYCrossRail extends JunctionRail {
    public static final BooleanProperty POWERED = BooleanProperty.create("powered");
    public static final EnumProperty<Direction> DIRECTION = EnumProperty.create("direction", Direction.class);

    protected AbstractYCrossRail(BlockBehaviour.Properties properties) {
        super(properties);
        registerDefaultState(defaultBlockState().setValue(POWERED, false).setValue(DIRECTION, Direction.NORTH));
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        super.createBlockStateDefinition(builder);
        builder.add(POWERED, DIRECTION);
    }

    @Override
    protected JunctionRoute.Cardinal route(BlockState state, JunctionRoute.Cardinal incoming) {
        JunctionRoute.Cardinal facing = cardinal(state.getValue(DIRECTION));
        // OLD's out-of-range DIRECTION branches fall back to the incoming direction.
        return facing == null ? incoming
                : JunctionRoute.destination(kind(), incoming, facing, state.getValue(POWERED));
    }

    @Override
    protected void onPlace(BlockState state, Level level, BlockPos pos, BlockState oldState, boolean moving) {
        if (!level.isClientSide && !oldState.is(this)) {
            boolean powered = level.hasNeighborSignal(pos);
            if (state.getValue(POWERED) != powered) {
                state = state.setValue(POWERED, powered);
                level.setBlock(pos, state, Block.UPDATE_ALL);
            }
        }
        super.onPlace(state, level, pos, oldState, moving);
    }

    @Override
    protected void updateState(BlockState state, Level level, BlockPos pos, Block neighbor) {
        if (!level.isClientSide) {
            boolean powered = level.hasNeighborSignal(pos);
            if (state.getValue(POWERED) != powered) {
                state = state.setValue(POWERED, powered);
                level.setBlock(pos, state, Block.UPDATE_ALL);
            }
        }
        super.updateState(state, level, pos, neighbor);
    }
}
