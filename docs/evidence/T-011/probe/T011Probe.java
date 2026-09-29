package evidence.t011;

import com.mojang.serialization.MapCodec;
import java.util.UUID;
import java.util.function.Supplier;
import net.minecraft.core.BlockPos;
import net.minecraft.core.HolderLookup;
import net.minecraft.core.registries.Registries;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.Tag;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.util.RandomSource;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.EntityBlock;
import net.minecraft.world.level.block.PoweredRailBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.entity.BlockEntityTicker;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.ticks.TickPriority;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

/** Compile-only signatures and data boundary sketch; never loaded or registered in the mod. */
public final class T011Probe {
    private T011Probe() {}
    static final DeferredRegister<BlockEntityType<?>> TYPES = DeferredRegister.create(Registries.BLOCK_ENTITY_TYPE, "simplerail");
    static DeferredHolder<BlockEntityType<?>, BlockEntityType<TimerEntity>> timerType;
    static DeferredHolder<BlockEntityType<?>, BlockEntityType<SignalEntity>> signalType;

    /** Call only with the real deferred block suppliers during future registration; not called in this probe. */
    static void registerTypes(Supplier<? extends Block> timerRail, Supplier<? extends Block> signalBlock) {
        timerType = TYPES.register("timer_holding_rail", () -> BlockEntityType.Builder.of(TimerEntity::new, timerRail.get()).build(null));
        signalType = TYPES.register("signal_timer", () -> BlockEntityType.Builder.of(SignalEntity::new, signalBlock.get()).build(null));
    }

    public static final class TimerRail extends PoweredRailBlock implements EntityBlock {
        static final MapCodec<PoweredRailBlock> CODEC = simpleCodec(TimerRail::new);
        public TimerRail(BlockBehaviour.Properties properties) { super(properties, true); }
        @Override public MapCodec<PoweredRailBlock> codec() { return CODEC; }
        @Override public BlockEntity newBlockEntity(BlockPos pos, BlockState state) { return new TimerEntity(pos, state); }
        @Override public <T extends BlockEntity> BlockEntityTicker<T> getTicker(Level level, BlockState state, BlockEntityType<T> type) {
            if (level.isClientSide || type != timerType.get()) return null;
            return (l, p, s, entity) -> ((TimerEntity) entity).serverTick();
        }
    }

    public static final class TimerEntity extends BlockEntity {
        private UUID cartUuid;
        private long remainingMillis;
        private long lastTickNanos;

        public TimerEntity(BlockPos pos, BlockState state) { super(timerType.get(), pos, state); }

        void start(UUID cart, long durationMillis) {
            cartUuid = cart;
            remainingMillis = Math.max(0L, durationMillis);
            lastTickNanos = System.nanoTime();
            setChanged();
        }

        void serverTick() {
            if (cartUuid == null || remainingMillis == 0L) return;
            long now = System.nanoTime();
            if (lastTickNanos != 0L) {
                long elapsedMillis = Math.max(0L, (now - lastTickNanos) / 1_000_000L);
                remainingMillis = Math.max(0L, remainingMillis - elapsedMillis);
                if (elapsedMillis != 0L) setChanged();
            }
            lastTickNanos = now;
        }

        @Override protected void saveAdditional(CompoundTag tag, HolderLookup.Provider registries) {
            super.saveAdditional(tag, registries);
            if (cartUuid != null && remainingMillis > 0L) {
                tag.putUUID("cart_uuid", cartUuid);
                tag.putLong("remaining_ms", remainingMillis);
            }
        }

        @Override protected void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) {
            super.loadAdditional(tag, registries);
            cartUuid = tag.hasUUID("cart_uuid") && tag.contains("remaining_ms", Tag.TAG_LONG)
                && tag.getLong("remaining_ms") > 0L ? tag.getUUID("cart_uuid") : null;
            remainingMillis = cartUuid == null ? 0L : tag.getLong("remaining_ms");
            lastTickNanos = 0L; // A new process/chunk must never subtract unloaded time.
        }
    }

    public static final class SignalBlock extends Block implements EntityBlock {
        static final MapCodec<SignalBlock> CODEC = simpleCodec(SignalBlock::new);
        public SignalBlock(BlockBehaviour.Properties properties) { super(properties); }
        @Override public MapCodec<SignalBlock> codec() { return CODEC; }
        @Override public BlockEntity newBlockEntity(BlockPos pos, BlockState state) { return new SignalEntity(pos, state); }
        @Override public <T extends BlockEntity> BlockEntityTicker<T> getTicker(Level level, BlockState state, BlockEntityType<T> type) {
            if (level.isClientSide || type != signalType.get()) return null;
            return (l, p, s, entity) -> ((SignalEntity) entity).serverTick(l, p, s);
        }
        @Override protected void tick(BlockState state, ServerLevel level, BlockPos pos, RandomSource random) {
            level.scheduleTick(pos, this, 10, TickPriority.VERY_HIGH);
        }
    }

    public static final class SignalEntity extends BlockEntity {
        public SignalEntity(BlockPos pos, BlockState state) { super(signalType.get(), pos, state); }
        void serverTick(Level level, BlockPos pos, BlockState state) {
            if (!level.getBlockTicks().hasScheduledTick(pos, state.getBlock())) {
                level.scheduleTick(pos, state.getBlock(), 20, TickPriority.VERY_HIGH);
            }
        }
    }
}
