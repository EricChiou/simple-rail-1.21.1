package com.ericchiu.simplerail.item;

import com.ericchiu.simplerail.block.TimerHoldingRail;
import com.ericchiu.simplerail.entity.LocomotiveCartEntity;
import com.ericchiu.simplerail.entity.TrainOwnershipData;
import com.ericchiu.simplerail.registry.ModTags;
import java.util.List;
import java.util.UUID;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
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
import net.minecraft.world.phys.Vec3;
import net.neoforged.neoforge.common.ItemAbilities;
import net.neoforged.neoforge.common.ItemAbility;

/** Rail and machine adjustments, plus adjacent minecart linking. */
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
        BlockPos neighbor = neighboringPosition(context);
        List<AbstractMinecart> first = cartsAt(server, pos);
        List<AbstractMinecart> second = neighbor.equals(pos) ? List.of() : cartsAt(server, neighbor);
        LocomotiveCartEntity locomotive = findLocomotive(server, first);
        if (locomotive == null) locomotive = findLocomotive(server, second);
        if (locomotive != null) {
            linkCarts(server, context.getClickLocation(), pos, locomotive, first);
            linkCarts(server, context.getClickLocation(), pos, locomotive, second);
        }

        BlockState state = server.getBlockState(pos);
        if (state.is(ModTags.RAILS) && first.isEmpty()) {
            if (state.getBlock() instanceof TimerHoldingRail) {
                // Its direction becomes horizontal after a cart passes. Apply both
                // edits to one state so rotation cannot restore the old level.
                writeChange(server, pos, state, rotate(cycleLevel(state), "direction"));
            } else {
                // Preserve the existing U-09 behavior for other rail types.
                writeChange(server, pos, state, toggleReverse(state));
                writeChange(server, pos, state, cycleLevel(state));
                writeChange(server, pos, state, rotate(state, "direction"));
            }
        }
        if (state.is(ModTags.MACHINES)) {
            writeChange(server, pos, state, rotate(state, "facing"));
            writeChange(server, pos, state, cycleLevel(state));
        }
        return InteractionResult.CONSUME;
    }

    /** OLD selects the neighboring cell perpendicular to the player's facing. */
    private static BlockPos neighboringPosition(UseOnContext context) {
        BlockPos pos = context.getClickedPos();
        Vec3 hit = context.getClickLocation();
        Direction facing = context.getHorizontalDirection();
        if (facing.getAxis() == Direction.Axis.X) {
            if (hit.z - pos.getZ() < 0.5D) return pos.north();
            if (hit.z - pos.getZ() > 0.5D) return pos.south();
        } else {
            if (hit.x - pos.getX() < 0.5D) return pos.west();
            if (hit.x - pos.getX() > 0.5D) return pos.east();
        }
        return pos;
    }

    private static List<AbstractMinecart> cartsAt(ServerLevel level, BlockPos pos) {
        return level.getEntitiesOfClass(AbstractMinecart.class, new AABB(pos));
    }

    private static LocomotiveCartEntity findLocomotive(ServerLevel level, List<AbstractMinecart> carts) {
        TrainOwnershipData owners = TrainOwnershipData.forLevel(level);
        for (AbstractMinecart cart : carts) {
            if (cart instanceof LocomotiveCartEntity head) return head;
            UUID owner = owners.ownerOf(cart.getUUID());
            if (owner != null && level.getEntity(owner) instanceof LocomotiveCartEntity head) return head;
        }
        return null;
    }

    private static void linkCarts(ServerLevel level, Vec3 hit, BlockPos clicked,
                                  LocomotiveCartEntity locomotive, List<AbstractMinecart> carts) {
        for (AbstractMinecart cart : carts) {
            // A second locomotive is never a carriage; linkNewCart owns the duplicate and ownership checks.
            if (cart instanceof LocomotiveCartEntity || !locomotive.linkNewCart(level, cart)) continue;
            level.sendParticles(ParticleTypes.SMOKE, hit.x, hit.y, hit.z, 1, 0.0D, 0.0D, 0.0D, 0.0D);
            level.playSound(null, clicked, SoundEvents.CHAIN_HIT, SoundSource.VOICE, 3.0F, 3.0F);
        }
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
