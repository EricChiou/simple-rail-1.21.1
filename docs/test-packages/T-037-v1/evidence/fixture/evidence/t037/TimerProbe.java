package evidence.t037;

import com.ericchiu.simplerail.block.base.BasePoweredRail;
import com.ericchiu.simplerail.registry.ModBlocks;
import com.mojang.brigadier.arguments.BoolArgumentType;
import com.mojang.brigadier.arguments.IntegerArgumentType;
import com.mojang.brigadier.context.CommandContext;
import com.mojang.brigadier.exceptions.CommandSyntaxException;
import com.mojang.serialization.MapCodec;
import com.mojang.logging.LogUtils;
import java.util.UUID;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.commands.arguments.coordinates.BlockPosArgument;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.HolderLookup;
import net.minecraft.core.registries.Registries;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.Tag;
import net.minecraft.network.chat.Component;
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
import net.minecraft.world.level.chunk.LevelChunk;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.common.NeoForge;
import net.neoforged.neoforge.event.RegisterCommandsEvent;
import net.neoforged.neoforge.event.level.ChunkDataEvent;
import net.neoforged.neoforge.event.level.ChunkEvent;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;
import org.slf4j.Logger;

/** Evidence-only lifecycle fixture. Commands control a synthetic timer; no cart gameplay is implemented. */
public final class TimerProbe {
    private static final Logger LOG = LogUtils.getLogger();
    private static final DeferredRegister<BlockEntityType<?>> TYPES = DeferredRegister.create(Registries.BLOCK_ENTITY_TYPE,"simplerail");
    private static final DeferredHolder<BlockEntityType<?>,BlockEntityType<ProbeEntity>> TYPE = TYPES.register(
            "timer_holding_rail", () -> BlockEntityType.Builder.of(ProbeEntity::new,ModBlocks.TIMER_HOLDING_RAIL.get()).build(null));

    public static void install(IEventBus bus) {
        TYPES.register(bus);
        NeoForge.EVENT_BUS.addListener(TimerProbe::commands);
        NeoForge.EVENT_BUS.addListener(TimerProbe::unload);
        NeoForge.EVENT_BUS.addListener(TimerProbe::saved);
        LOG.warn("[T037] DIAGNOSTIC FIXTURE ONLY: synthetic timer, not production T-038");
    }

    public static final class ProbeRail extends BasePoweredRail implements EntityBlock {
        public static final MapCodec<PoweredRailBlock> CODEC = simpleCodec(ProbeRail::new);
        private static final IntegerProperty LEVEL = IntegerProperty.create("level",0,9);
        private static final EnumProperty<Direction> DIRECTION = EnumProperty.create("direction",Direction.class);
        public ProbeRail(BlockBehaviour.Properties properties) {
            super(properties);
            registerDefaultState(defaultBlockState().setValue(LEVEL,0).setValue(DIRECTION,Direction.NORTH));
        }
        @Override public MapCodec<PoweredRailBlock> codec() { return CODEC; }
        @Override protected void createBlockStateDefinition(StateDefinition.Builder<Block,BlockState> b) {
            super.createBlockStateDefinition(b); b.add(LEVEL,DIRECTION);
        }
        @Override public BlockEntity newBlockEntity(BlockPos pos,BlockState state) { return new ProbeEntity(pos,state); }
        @Override public <T extends BlockEntity> BlockEntityTicker<T> getTicker(Level level,BlockState state,BlockEntityType<T> type) {
            if (level.isClientSide || type != TYPE.get()) return null;
            return (l,p,s,be) -> ((ProbeEntity)be).tickProbe();
        }
    }

    public static final class ProbeEntity extends BlockEntity {
        private final TimerState timer = new TimerState(System::nanoTime);
        private boolean markDirty = true;
        private boolean expiredReported;
        private long previousRemaining;
        private String arm = "none";
        private long armMillis;
        public ProbeEntity(BlockPos pos,BlockState state) { super(TYPE.get(),pos,state); }
        private void log(String event,String detail) {
            LOG.info("[T037] event={} dimension={} pos={} wall_ms={} nano={} {}",event,
                    level == null ? "not_attached" : level.dimension().location(),worldPosition,
                    System.currentTimeMillis(),System.nanoTime(),detail);
        }
        private void start(long millis,boolean dirty) {
            markDirty = dirty;
            timer.start(UUID.randomUUID(),millis);
            previousRemaining = timer.remaining(); expiredReported = false; arm = "none";
            if (markDirty) setChanged();
            log("START","requested_ms="+millis+" markDirty="+markDirty);
        }
        private void tickProbe() {
            if (timer.paused()) { log("FIRST_TICK","stored_remaining_ms="+timer.remaining()); timer.resume(); }
            long remaining = timer.remaining();
            if (remaining != previousRemaining && markDirty) setChanged();
            if (previousRemaining > 0 && remaining == 0 && !expiredReported) {
                log("EXPIRED","synthetic_timer_only=true"); expiredReported = true;
            }
            previousRemaining = remaining;
        }
        private void arm(String trigger,long millis) {
            start(60000,true); arm = trigger; armMillis = millis;
            log("ARM","trigger="+arm+" snapshot_target_ms="+armMillis);
        }
        private void fireArm(String trigger) {
            if (arm.equals(trigger)) {
                arm = "none"; timer.start(UUID.randomUUID(),armMillis);
                previousRemaining = timer.remaining(); expiredReported = false;
                log("ARM_FIRED","trigger="+trigger+" requested_ms="+armMillis);
            }
        }
        @Override protected void saveAdditional(CompoundTag tag,HolderLookup.Provider registries) {
            super.saveAdditional(tag,registries);
            fireArm("save"); // Controlled snapshot boundary experiment, never production policy.
            long remaining = timer.remaining();
            CompoundTag data = TimerRecordCodec.encode(timer.cart(),remaining);
            data.putBoolean("mark_dirty",markDirty);
            tag.put("t037_data",data);
            log("SERIALIZE","remaining_ms="+remaining+" payload="+data+" (not_proof_of_disk_write)");
        }
        @Override protected void loadAdditional(CompoundTag tag,HolderLookup.Provider registries) {
            super.loadAdditional(tag,registries);
            CompoundTag data = tag.getCompound("t037_data");
            TimerRecordCodec.Record record = TimerRecordCodec.decode(data);
            timer.restore(record.cart(),record.remaining());
            markDirty = !data.contains("mark_dirty") || data.getBoolean("mark_dirty");
            previousRemaining = record.remaining(); expiredReported = false; arm = "none";
            log("LOAD","status="+record.status()+" stored_remaining_ms="+record.remaining());
        }
        @Override public void onLoad() { super.onLoad(); if (level != null && !level.isClientSide) log("ON_LOAD","remaining_ms="+timer.remaining()); }
        @Override public void onChunkUnloaded() { log("BE_UNLOADED","remaining_ms="+timer.remaining()+" (after_save_path)"); }
        private String status() {
            return "remaining_ms="+timer.remaining()+" paused="+timer.paused()+" markDirty="+markDirty
                    +" chunkUnsaved="+level.getChunkAt(worldPosition).isUnsaved()+" arm="+arm;
        }
    }

    private static void unload(ChunkEvent.Unload event) {
        if (event.getChunk() instanceof LevelChunk chunk && !chunk.getLevel().isClientSide) {
            for (BlockEntity be : chunk.getBlockEntities().values()) if (be instanceof ProbeEntity probe) {
                probe.log("CHUNK_UNLOAD","unsaved_before="+chunk.isUnsaved());
                if (probe.arm.equals("unload")) {
                    probe.fireArm("unload");
                    // Use the event's chunk directly; never request/reload a chunk during unloading.
                    chunk.setUnsaved(true);
                }
            }
        }
    }
    private static void saved(ChunkDataEvent.Save event) {
        ListTag entries = event.getData().getList("block_entities",Tag.TAG_COMPOUND);
        for (int i=0;i<entries.size();i++) {
            CompoundTag data = entries.getCompound(i);
            if (data.getString("id").equals("simplerail:timer_holding_rail")) {
                LOG.info("[T037] event=CHUNK_DATA_SAVE chunk={} wall_ms={} payload={} (serialized_not_IO_ack)",
                        event.getChunk().getPos(),System.currentTimeMillis(),data);
            }
        }
    }
    private static ProbeEntity entity(CommandContext<CommandSourceStack> ctx) throws CommandSyntaxException {
        BlockPos pos = BlockPosArgument.getLoadedBlockPos(ctx,"pos");
        BlockEntity be = ctx.getSource().getLevel().getBlockEntity(pos);
        return be instanceof ProbeEntity probe ? probe : null;
    }
    private static int operate(CommandContext<CommandSourceStack> ctx,String action) throws CommandSyntaxException {
        ProbeEntity probe = entity(ctx);
        if (probe == null) { ctx.getSource().sendFailure(Component.literal("T037: place simplerail:timer_holding_rail from this diagnostic JAR first")); return 0; }
        switch(action) {
            case "start" -> probe.start(TimerState.secondsToMillis(IntegerArgumentType.getInteger(ctx,"seconds")),BoolArgumentType.getBool(ctx,"dirty"));
            case "clear" -> probe.start(0,BoolArgumentType.getBool(ctx,"dirty"));
            case "save", "unload" -> probe.arm(action,IntegerArgumentType.getInteger(ctx,"millis"));
            default -> { }
        }
        String status = probe.status();
        ctx.getSource().sendSuccess(() -> Component.literal("T037 "+status),false);
        probe.log("STATUS",status);
        return 1;
    }
    private static void commands(RegisterCommandsEvent event) {
        var root = Commands.literal("t037").requires(s -> s.hasPermission(2));
        root.then(Commands.literal("status").then(Commands.argument("pos",BlockPosArgument.blockPos()).executes(c -> operate(c,"status"))));
        root.then(Commands.literal("start").then(Commands.argument("pos",BlockPosArgument.blockPos())
                .then(Commands.argument("seconds",IntegerArgumentType.integer(0,Integer.MAX_VALUE))
                        .then(Commands.argument("dirty",BoolArgumentType.bool()).executes(c -> operate(c,"start"))))));
        root.then(Commands.literal("clear").then(Commands.argument("pos",BlockPosArgument.blockPos())
                .then(Commands.argument("dirty",BoolArgumentType.bool()).executes(c -> operate(c,"clear")))));
        var arm = Commands.literal("arm");
        for (String trigger : new String[]{"save","unload"}) {
            arm.then(Commands.literal(trigger).then(Commands.argument("pos",BlockPosArgument.blockPos())
                    .then(Commands.argument("millis",IntegerArgumentType.integer(1,60000)).executes(c -> operate(c,trigger)))));
        }
        root.then(arm);
        root.then(Commands.literal("arithmetic").then(Commands.argument("seconds",IntegerArgumentType.integer(0,Integer.MAX_VALUE)).executes(c -> {
            int seconds = IntegerArgumentType.getInteger(c,"seconds");
            c.getSource().sendSuccess(() -> Component.literal("T037 seconds="+seconds+" legacy_int_ms="+(seconds*1000)
                    +" candidate_long_ms="+TimerState.secondsToMillis(seconds)),false); return 1;
        })));
        event.getDispatcher().register(root);
    }
}
