package evidence.t043;

import com.ericchiu.simplerail.registry.ModItems;
import com.mojang.brigadier.context.CommandContext;
import com.mojang.brigadier.exceptions.CommandSyntaxException;
import com.mojang.logging.LogUtils;
import com.mojang.serialization.MapCodec;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicLong;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.commands.arguments.coordinates.BlockPosArgument;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.item.MinecartItem;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.entity.ChestBlockEntity;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.state.properties.DirectionProperty;
import net.minecraft.world.phys.AABB;
import net.minecraft.network.chat.Component;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.common.NeoForge;
import net.neoforged.neoforge.event.RegisterCommandsEvent;
import org.slf4j.Logger;

/** Evidence-only dispenser model; a vanilla chest directly above supplies 27 template slots. */
public final class DispenserProbe {
    private static final Logger LOG = LogUtils.getLogger();
    private static final AtomicLong RUNS = new AtomicLong();

    private DispenserProbe() {}

    public static void install(IEventBus bus) {
        NeoForge.EVENT_BUS.addListener(DispenserProbe::commands);
        LOG.warn("[T043] DIAGNOSTIC ONLY: train_dispenser reads chest above; not T-044/T-045 production logic");
    }

    public static final class ProbeBlock extends Block {
        public static final MapCodec<ProbeBlock> CODEC = simpleCodec(ProbeBlock::new);
        public static final DirectionProperty FACING = BlockStateProperties.HORIZONTAL_FACING;

        public ProbeBlock(BlockBehaviour.Properties properties) {
            super(properties);
            registerDefaultState(defaultBlockState().setValue(FACING, Direction.NORTH));
        }

        @Override
        protected MapCodec<ProbeBlock> codec() {
            return CODEC;
        }

        @Override
        protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
            super.createBlockStateDefinition(builder);
            builder.add(FACING);
        }

        @Override
        protected void neighborChanged(BlockState state, Level level, BlockPos pos, Block neighbor,
                BlockPos fromPos, boolean movedByPiston) {
            if (level instanceof ServerLevel server && server.hasNeighborSignal(pos)) {
                scan(server, pos, state, "powered_neighbor", fromPos);
            }
        }
    }

    private static DispenserSourceModel.Kind classify(ItemStack stack) {
        if (stack.isEmpty()) return DispenserSourceModel.Kind.EMPTY;
        if (stack.is(ModItems.LOCOMOTIVE_CART.get())) return DispenserSourceModel.Kind.LOCOMOTIVE;
        if (stack.is(Items.CHEST_MINECART)) return DispenserSourceModel.Kind.CHEST;
        if (stack.is(Items.FURNACE_MINECART)) return DispenserSourceModel.Kind.FURNACE;
        if (stack.is(Items.HOPPER_MINECART)) return DispenserSourceModel.Kind.HOPPER;
        if (stack.is(Items.TNT_MINECART)) return DispenserSourceModel.Kind.TNT;
        if (stack.getItem() instanceof MinecartItem) return DispenserSourceModel.Kind.RIDEABLE;
        return DispenserSourceModel.Kind.OTHER;
    }

    private static DispenserSourceModel.Facing facing(BlockState state) {
        return DispenserSourceModel.Facing.valueOf(state.getValue(ProbeBlock.FACING).name());
    }

    private static void scan(ServerLevel level, BlockPos pos, BlockState state, String trigger, BlockPos from) {
        long run = RUNS.incrementAndGet();
        if (!(level.getBlockEntity(pos.above()) instanceof ChestBlockEntity chest)) {
            LOG.warn("[T043] run={} trigger={} pos={} missing_single_chest_above=true", run, trigger, pos);
            return;
        }
        LOG.info("[T043] run={} START dimension={} pos={} facing={} trigger={} from={} powered={} chest_above={} game_time={}",
                run, level.dimension().location(), pos, state.getValue(ProbeBlock.FACING), trigger, from,
                level.hasNeighborSignal(pos), pos.above(), level.getGameTime());
        var result = DispenserSourceModel.run(facing(state), pos.getX(), pos.getY(), pos.getZ(),
                slot -> classify(chest.getItem(slot)),
                place -> !level.getEntitiesOfClass(AbstractMinecart.class,
                        new AABB(BlockPos.containing(place.x(), place.y(), place.z()))).isEmpty(),
                (slot, kind, place) -> {
                    AbstractMinecart.Type cartType = switch (kind) {
                        case CHEST -> AbstractMinecart.Type.CHEST;
                        case FURNACE, LOCOMOTIVE -> AbstractMinecart.Type.FURNACE;
                        case HOPPER -> AbstractMinecart.Type.HOPPER;
                        case TNT -> AbstractMinecart.Type.TNT;
                        default -> AbstractMinecart.Type.RIDEABLE;
                    };
                    // LOCOMOTIVE is intentionally a furnace-cart stand-in. No linkage
                    // or production locomotive entity exists before T-048/T-059.
                    AbstractMinecart cart = AbstractMinecart.createMinecart(level, place.x(), place.y(), place.z(),
                            cartType, ItemStack.EMPTY, null);
                    boolean added = level.addFreshEntity(cart);
                    LOG.info("[T043] run={} SPAWN slot={} kind={} stand_in={} uuid={} added={}",
                            run, slot, kind, kind == DispenserSourceModel.Kind.LOCOMOTIVE, cart.getUUID(), added);
                    return cart.getUUID();
                });
        for (var step : result.steps()) {
            ItemStack stack = chest.getItem(step.slot());
            LOG.info("[T043] run={} SLOT index={} item={} count={} kind={} place={} action={} entity={}",
                    run, step.slot(), stack.getItem(), stack.getCount(), step.kind(), step.position(),
                    step.action(), step.entityId());
        }
        LOG.info("[T043] run={} END visited={} stopped_at={} head_at_zero={} link_plan={} no_template_item_removed=true",
                run, result.steps().size(), result.stoppedAt(), result.headAtSlotZero(), result.linkedCars());
    }

    private static int fire(CommandContext<CommandSourceStack> context) throws CommandSyntaxException {
        ServerLevel level = context.getSource().getLevel();
        BlockPos pos = BlockPosArgument.getLoadedBlockPos(context, "pos");
        BlockState state = level.getBlockState(pos);
        if (!(state.getBlock() instanceof ProbeBlock)) {
            context.getSource().sendFailure(Component.literal("T043: target is not the diagnostic train_dispenser"));
            return 0;
        }
        scan(level, pos, state, "manual_command", pos);
        context.getSource().sendSuccess(() -> Component.literal("T043 scan requested; inspect server log [T043] run"), false);
        return 1;
    }

    private static void commands(RegisterCommandsEvent event) {
        event.getDispatcher().register(Commands.literal("t043")
                .requires(source -> source.hasPermission(2))
                .then(Commands.literal("scan")
                        .then(Commands.argument("pos", BlockPosArgument.blockPos())
                                .executes(DispenserProbe::fire))));
    }
}
