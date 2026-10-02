package com.ericchiu.simplerail.block;

import com.ericchiu.simplerail.blockentity.TrainDispenserBlockEntity;
import com.ericchiu.simplerail.entity.Facing8;
import com.ericchiu.simplerail.entity.LocomotiveCartEntity;
import com.ericchiu.simplerail.registry.ModEntities;
import com.ericchiu.simplerail.registry.ModItems;
import com.mojang.serialization.MapCodec;
import java.util.ArrayList;
import java.util.List;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.stats.Stats;
import net.minecraft.util.RandomSource;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.MenuProvider;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.item.MinecartItem;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.BaseRailBlock;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.DispenserBlock;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.RailShape;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.BlockHitResult;

/** A non-consuming, 27-slot train template. */
public final class TrainDispenserBlock extends DispenserBlock {
    public static final MapCodec<TrainDispenserBlock> CODEC = simpleCodec(TrainDispenserBlock::new);

    public TrainDispenserBlock(BlockBehaviour.Properties properties) {
        super(properties);
    }

    @Override
    public MapCodec<? extends DispenserBlock> codec() {
        return CODEC;
    }

    @Override
    public BlockState getStateForPlacement(BlockPlaceContext context) {
        return defaultBlockState().setValue(FACING, context.getHorizontalDirection().getOpposite());
    }

    @Override
    protected void onPlace(BlockState state, Level level, BlockPos pos, BlockState oldState, boolean isMoving) {
        super.onPlace(state, level, pos, oldState, isMoving);
        if (!state.getValue(FACING).getAxis().isHorizontal()) {
            level.setBlock(pos, state.setValue(FACING, Direction.NORTH), 3);
        }
    }

    @Override
    public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return new TrainDispenserBlockEntity(pos, state);
    }

    @Override
    protected MenuProvider getMenuProvider(BlockState state, Level level, BlockPos pos) {
        BlockEntity entity = level.getBlockEntity(pos);
        return entity instanceof TrainDispenserBlockEntity dispenser ? dispenser : null;
    }

    @Override
    protected InteractionResult useWithoutItem(BlockState state, Level level, BlockPos pos,
            Player player, BlockHitResult hit) {
        if (level.isClientSide) {
            return InteractionResult.SUCCESS;
        }
        if (player instanceof ServerPlayer server
                && level.getBlockEntity(pos) instanceof TrainDispenserBlockEntity dispenser) {
            server.openMenu(dispenser);
            server.awardStat(Stats.OPEN_CHEST);
        }
        return InteractionResult.CONSUME;
    }

    @Override
    protected void neighborChanged(BlockState state, Level level, BlockPos pos, Block neighbor,
            BlockPos fromPos, boolean isMoving) {
        // OLD scans on every powered neighbor update, without the vanilla
        // TRIGGERED edge latch or its four-tick delay.
        if (level instanceof ServerLevel server && server.hasNeighborSignal(pos)) {
            spawnTemplate(server, state, pos);
        }
    }

    @Override
    protected void tick(BlockState state, ServerLevel level, BlockPos pos, RandomSource random) {
        // Do not run a pending vanilla dispenser tick from an earlier state.
    }

    @Override
    protected void dispenseFrom(ServerLevel level, BlockState state, BlockPos pos) {
        // Never call vanilla's nine-slot, consuming dispenser behavior.
    }

    private static void spawnTemplate(ServerLevel level, BlockState state, BlockPos pos) {
        if (!(level.getBlockEntity(pos) instanceof TrainDispenserBlockEntity dispenser)) {
            return;
        }

        TrainDispenserScan.Facing facing = switch (state.getValue(FACING)) {
            case NORTH -> TrainDispenserScan.Facing.NORTH;
            case SOUTH -> TrainDispenserScan.Facing.SOUTH;
            case EAST -> TrainDispenserScan.Facing.EAST;
            case WEST -> TrainDispenserScan.Facing.WEST;
            default -> throw new IllegalStateException("Train dispenser must face horizontally");
        };
        LocomotiveCartEntity[] head = new LocomotiveCartEntity[1];
        List<AbstractMinecart> cars = new ArrayList<>();
        TrainDispenserScan.scan(facing, pos.getX(), pos.getY(), pos.getZ(),
                TrainDispenserBlockEntity.SLOT_COUNT,
                place -> !level.getEntitiesOfClass(AbstractMinecart.class,
                        new AABB(BlockPos.containing(place.x(), place.y(), place.z()))).isEmpty(),
                (slot, place) -> {
                    ItemStack template = dispenser.getItem(slot);
                    if (template.is(ModItems.LOCOMOTIVE_CART.get())) {
                        LocomotiveCartEntity cart = ModEntities.LOCOMOTIVE_CART.get().create(level);
                        if (cart != null) {
                            cart.moveTo(place.x(), place.y(), place.z());
                            BlockPos railPos = BlockPos.containing(place.x(), place.y(), place.z());
                            BlockState railState = level.getBlockState(railPos);
                            RailShape shape = railState.getBlock() instanceof BaseRailBlock rail
                                    ? rail.getRailDirection(railState, level, railPos, cart)
                                    : RailShape.NORTH_SOUTH;
                            cart.setFacingFromServer(switch (shape) {
                                case EAST_WEST, ASCENDING_EAST, ASCENDING_WEST -> Facing8.EAST;
                                default -> Facing8.NORTH;
                            });
                            if (level.addFreshEntity(cart) && slot == 0) head[0] = cart;
                        }
                        return;
                    }
                    if (template.isEmpty() || !(template.getItem() instanceof MinecartItem)) {
                        return;
                    }

                    AbstractMinecart.Type type = cartType(template);
                    // OLD created a fresh cart from the item kind, without applying
                    // sample stack components. The stored template is only read.
                    AbstractMinecart cart = AbstractMinecart.createMinecart(level, place.x(), place.y(), place.z(),
                            type, ItemStack.EMPTY, null);
                    if (level.addFreshEntity(cart)) cars.add(cart);
                });
        // OLD links all spawned vanilla carts after the scan, but only to a head in slot 0.
        if (head[0] != null) {
            for (AbstractMinecart cart : cars) head[0].linkNewCart(level, cart);
        }
    }

    private static AbstractMinecart.Type cartType(ItemStack template) {
        if (template.is(Items.CHEST_MINECART)) return AbstractMinecart.Type.CHEST;
        if (template.is(Items.FURNACE_MINECART)) return AbstractMinecart.Type.FURNACE;
        if (template.is(Items.HOPPER_MINECART)) return AbstractMinecart.Type.HOPPER;
        if (template.is(Items.TNT_MINECART)) return AbstractMinecart.Type.TNT;
        // The OLD switch fell back to a rideable cart for other MinecartItems.
        return AbstractMinecart.Type.RIDEABLE;
    }
}
