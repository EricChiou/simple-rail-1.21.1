package com.ericchiu.simplerail.item;

import com.ericchiu.simplerail.registry.ModTags;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.context.UseOnContext;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.level.block.state.properties.EnumProperty;
import net.minecraft.world.level.block.state.properties.IntegerProperty;
import net.minecraft.world.level.block.state.properties.Property;
import net.minecraft.world.phys.AABB;
import net.neoforged.neoforge.common.ItemAbilities;
import net.neoforged.neoforge.common.ItemAbility;

/** Block-state operations only; consist linking belongs to the later linking tasks. */
public final class Wrench extends Item {
    public Wrench(Properties properties) {
        super(properties);
    }

    @Override
    public boolean canPerformAction(ItemStack stack, ItemAbility ability) {
        return ItemAbilities.DEFAULT_HOE_ACTIONS.contains(ability);
    }

    @Override
    public InteractionResult useOn(UseOnContext context) {
        Level level = context.getLevel();
        if (level.isClientSide) {
            return InteractionResult.SUCCESS;
        }
        if (!(level instanceof ServerLevel server)) {
            return InteractionResult.PASS;
        }
        BlockPos pos = context.getClickedPos();
        BlockState state = server.getBlockState(pos);
        // Keep OLD writes based on the same initial state until the U-09 intent is decided.
        if (state.is(ModTags.RAILS)
                && server.getEntitiesOfClass(AbstractMinecart.class, new AABB(pos)).isEmpty()) {
            writeChange(server, pos, state, toggleReverse(state));
            writeChange(server, pos, state, cycleLevel(state));
            writeChange(server, pos, state, rotate(state, "direction"));
        }
        if (state.is(ModTags.MACHINES)) {
            writeChange(server, pos, state, rotate(state, "facing"));
            writeChange(server, pos, state, cycleLevel(state));
        }
        return InteractionResult.CONSUME;
    }

    private static void writeChange(ServerLevel level, BlockPos pos, BlockState initial, BlockState changed) {
        if (changed != initial) {
            level.setBlock(pos, changed, Block.UPDATE_ALL);
        }
    }

    private static BlockState toggleReverse(BlockState state) {
        Property<?> property = state.getBlock().getStateDefinition().getProperty("reverse");
        if (property instanceof BooleanProperty reverse) {
            return state.setValue(reverse, !state.getValue(reverse));
        }
        return state;
    }

    private static BlockState cycleLevel(BlockState state) {
        Property<?> property = state.getBlock().getStateDefinition().getProperty("level");
        if (property instanceof IntegerProperty level && level.getPossibleValues().size() == 10
                && level.getPossibleValues().contains(0) && level.getPossibleValues().contains(9)) {
            int current = state.getValue(level);
            return state.setValue(level, current >= 9 ? 0 : current + 1);
        }
        return state;
    }

    private static BlockState rotate(BlockState state, String name) {
        Property<?> property = state.getBlock().getStateDefinition().getProperty(name);
        if (property instanceof EnumProperty<?> enumeration && enumeration.getValueClass() == Direction.class) {
            // Use the actual property instance: target StateHolder uses a reference-keyed map.
            @SuppressWarnings("unchecked")
            Property<Direction> direction = (Property<Direction>) enumeration;
            Direction current = state.getValue(direction);
            if (current.getAxis().isHorizontal()) {
                Direction next = current.getClockWise();
                if (direction.getPossibleValues().contains(next)) {
                    return state.setValue(direction, next);
                }
            }
        }
        return state;
    }
}
