package com.ericchiu.simplerail.block;

import com.mojang.serialization.MapCodec;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.RailBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.level.block.state.properties.EnumProperty;

/** One redstone-selected junction, with matching state-driven turn textures. */
public final class TCrossRail extends JunctionRail {
    public static final MapCodec<RailBlock> CODEC = simpleCodec(TCrossRail::new);
    public static final BooleanProperty POWERED = BooleanProperty.create("powered");
    public static final EnumProperty<Direction> DIRECTION = EnumProperty.create("direction", Direction.class,
            Direction.NORTH, Direction.EAST, Direction.SOUTH, Direction.WEST);

    public TCrossRail(BlockBehaviour.Properties properties) {
        super(properties);
        registerDefaultState(defaultBlockState().setValue(POWERED, false).setValue(DIRECTION, Direction.NORTH));
    }

    @Override
    public MapCodec<RailBlock> codec() {
        return CODEC;
    }

    @Override
    protected JunctionRoute.Kind kind() {
        return JunctionRoute.Kind.T;
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        super.createBlockStateDefinition(builder);
        builder.add(POWERED, DIRECTION);
    }

    @Override
    public BlockState getStateForPlacement(BlockPlaceContext context) {
        return super.getStateForPlacement(context)
                .setValue(DIRECTION, context.getHorizontalDirection())
                .setValue(POWERED, context.getLevel().hasNeighborSignal(context.getClickedPos()));
    }

    @Override
    protected JunctionRoute.Cardinal route(BlockState state, JunctionRoute.Cardinal incoming) {
        return JunctionRoute.destination(kind(), incoming, cardinal(state.getValue(DIRECTION)), state.getValue(POWERED));
    }

    @Override
    protected void onPlace(BlockState state, Level level, BlockPos pos, BlockState oldState, boolean moving) {
        if (!level.isClientSide && !oldState.is(this)) {
            state = updatePower(state, level, pos);
        }
        super.onPlace(state, level, pos, oldState, moving);
    }

    @Override
    protected void updateState(BlockState state, Level level, BlockPos pos, Block neighbor) {
        if (!level.isClientSide) {
            state = updatePower(state, level, pos);
        }
        super.updateState(state, level, pos, neighbor);
    }

    private BlockState updatePower(BlockState state, Level level, BlockPos pos) {
        boolean powered = level.hasNeighborSignal(pos);
        if (state.getValue(POWERED) != powered) {
            state = state.setValue(POWERED, powered);
            level.setBlock(pos, state, Block.UPDATE_ALL);
        }
        return state;
    }
}
