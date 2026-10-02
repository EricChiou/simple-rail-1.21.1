package com.ericchiu.simplerail.item;

import com.ericchiu.simplerail.entity.Facing8;
import com.ericchiu.simplerail.entity.LocomotiveCartEntity;
import com.ericchiu.simplerail.registry.ModEntities;
import com.ericchiu.simplerail.registry.ModTags;
import net.minecraft.core.BlockPos;
import net.minecraft.core.component.DataComponents;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.tags.BlockTags;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.context.UseOnContext;
import net.minecraft.world.level.block.BaseRailBlock;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.RailShape;

/** Server-authoritative placement on either Simple Rail or vanilla rail tags. */
public final class LocomotiveCartItem extends Item {
    public LocomotiveCartItem(Properties properties) {
        super(properties);
    }

    @Override
    public InteractionResult useOn(UseOnContext context) {
        BlockPos pos = context.getClickedPos();
        BlockState state = context.getLevel().getBlockState(pos);
        if (!state.is(ModTags.RAILS) && !state.is(BlockTags.RAILS)) return InteractionResult.FAIL;
        ItemStack sample = context.getItemInHand();
        if (context.getLevel() instanceof ServerLevel server) {
            RailShape shape = state.getBlock() instanceof BaseRailBlock rail
                    ? rail.getRailDirection(state, server, pos, null) : RailShape.NORTH_SOUTH;
            double y = pos.getY() + 0.0625D + (shape.isAscending() ? 0.5D : 0.0D);
            LocomotiveCartEntity cart = ModEntities.LOCOMOTIVE_CART.get().create(server);
            if (cart == null) return InteractionResult.FAIL;
            cart.moveTo(pos.getX() + 0.5D, y, pos.getZ() + 0.5D);
            cart.setFacingFromServer(switch (shape) {
                case EAST_WEST, ASCENDING_EAST, ASCENDING_WEST -> Facing8.EAST;
                default -> Facing8.NORTH;
            });
            var name = sample.get(DataComponents.CUSTOM_NAME);
            if (name != null) cart.setCustomName(name);
            if (!server.addFreshEntity(cart)) return InteractionResult.FAIL;
            // OLD and vanilla minecart items consume one stack unit, including in creative.
            sample.shrink(1);
        }
        return InteractionResult.sidedSuccess(context.getLevel().isClientSide);
    }
}
