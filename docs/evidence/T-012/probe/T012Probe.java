package evidence.t012;

import com.mojang.serialization.MapCodec;
import java.util.function.Supplier;
import net.minecraft.core.BlockPos;
import net.minecraft.core.HolderLookup;
import net.minecraft.core.NonNullList;
import net.minecraft.core.registries.Registries;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.stats.Stats;
import net.minecraft.world.ContainerHelper;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.MenuProvider;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.inventory.AbstractContainerMenu;
import net.minecraft.world.inventory.ChestMenu;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.DispenserBlock;
import net.minecraft.world.level.block.entity.BaseContainerBlockEntity;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.BlockHitResult;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

/** Compile-only candidate. Never loaded, registered, packaged, or used to trigger trains. */
public final class T012Probe {
    private T012Probe() {}
    static final DeferredRegister<BlockEntityType<?>> TYPES = DeferredRegister.create(Registries.BLOCK_ENTITY_TYPE, "simplerail");
    static DeferredHolder<BlockEntityType<?>, BlockEntityType<TrainDispenserEntity>> type;

    /** The real train_dispenser block supplier would be passed in T-019/T-044. */
    static void registerType(Supplier<? extends Block> trainDispenserBlock) {
        type = TYPES.register("train_dispenser",
            () -> BlockEntityType.Builder.of(TrainDispenserEntity::new, trainDispenserBlock.get()).build(null));
    }

    public static final class TrainDispenserBlock extends DispenserBlock {
        static final MapCodec<DispenserBlock> CODEC = simpleCodec(TrainDispenserBlock::new);
        public TrainDispenserBlock(BlockBehaviour.Properties properties) { super(properties); }
        @Override public MapCodec<DispenserBlock> codec() { return CODEC; }
        @Override public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
            return new TrainDispenserEntity(pos, state);
        }
        @Override protected MenuProvider getMenuProvider(BlockState state, Level level, BlockPos pos) {
            BlockEntity candidate = level.getBlockEntity(pos);
            return candidate instanceof TrainDispenserEntity dispenser ? dispenser : null;
        }
        @Override protected InteractionResult useWithoutItem(BlockState state, Level level, BlockPos pos,
                Player player, BlockHitResult hit) {
            if (level.isClientSide) return InteractionResult.SUCCESS;
            if (player instanceof ServerPlayer server
                    && level.getBlockEntity(pos) instanceof TrainDispenserEntity dispenser) {
                server.openMenu(dispenser);
                server.awardStat(Stats.OPEN_CHEST);
            }
            return InteractionResult.CONSUME;
        }
        /** Prevent vanilla DispenserBlock from reading its own 9-slot BE; T-045 supplies train behavior. */
        @Override protected void dispenseFrom(ServerLevel level, BlockState state, BlockPos pos) {
            // Compile-only boundary. No game logic in T-012.
        }
    }

    public static final class TrainDispenserEntity extends BaseContainerBlockEntity {
        static final int SLOT_COUNT = 27;
        private NonNullList<ItemStack> items = NonNullList.withSize(SLOT_COUNT, ItemStack.EMPTY);
        public TrainDispenserEntity(BlockPos pos, BlockState state) { super(type.get(), pos, state); }
        @Override public int getContainerSize() { return SLOT_COUNT; }
        @Override protected Component getDefaultName() { return Component.translatable("container.chest"); }
        @Override protected NonNullList<ItemStack> getItems() { return items; }
        @Override protected void setItems(NonNullList<ItemStack> replacement) { items = replacement; }
        @Override protected AbstractContainerMenu createMenu(int id, Inventory inventory) {
            return ChestMenu.threeRows(id, inventory, this);
        }
        @Override protected void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) {
            super.loadAdditional(tag, registries);
            items = NonNullList.withSize(SLOT_COUNT, ItemStack.EMPTY);
            ContainerHelper.loadAllItems(tag, items, registries);
        }
        @Override protected void saveAdditional(CompoundTag tag, HolderLookup.Provider registries) {
            super.saveAdditional(tag, registries);
            ContainerHelper.saveAllItems(tag, items, registries);
        }
        @Override public void clearContent() {
            super.clearContent();
            setChanged();
        }
        /** Generation code must inspect copies and must not shrink the saved template. */
        public ItemStack templateCopy(int slot) { return getItem(slot).copy(); }
    }
}
