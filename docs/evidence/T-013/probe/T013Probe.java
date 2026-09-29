package evidence.t013;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Supplier;
import net.minecraft.core.BlockPos;
import net.minecraft.core.component.DataComponents;
import net.minecraft.core.registries.Registries;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.StringTag;
import net.minecraft.nbt.Tag;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.tags.BlockTags;
import net.minecraft.tags.TagKey;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.damagesource.DamageSource;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.MobCategory;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.entity.vehicle.MinecartFurnace;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.item.context.UseOnContext;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.BaseRailBlock;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.RailShape;
import net.minecraft.world.phys.Vec3;

/** Signature and data-boundary probe only; never part of the product sourceSet. */
public final class T013Probe {
    private T013Probe() {}

    static final TagKey<net.minecraft.world.level.block.Block> RAILS =
        TagKey.create(Registries.BLOCK, ResourceLocation.fromNamespaceAndPath("simplerail", "rails"));

    static EntityType<Locomotive> candidateType() {
        return EntityType.Builder.<Locomotive>of(Locomotive::new, MobCategory.MISC)
            .sized(0.98F, 0.7F).clientTrackingRange(8).build("simplerail:locomotive_cart");
    }

    enum Facing8 {
        EAST, WEST, NORTH, SOUTH, NORTH_EAST, NORTH_WEST, SOUTH_EAST, SOUTH_WEST;

        static Facing8 parse(String name) {
            try { return valueOf(name.toUpperCase(java.util.Locale.ROOT)); }
            catch (IllegalArgumentException exception) { return NORTH; }
        }

        String saved() { return name().toLowerCase(java.util.Locale.ROOT); }
    }

    static final class Locomotive extends MinecartFurnace {
        // Authoritative ordered IDs persist in the locomotive. Cache is never authoritative.
        private final List<UUID> trainIds = new ArrayList<>();
        private final Map<UUID, BlockPos> stopPositions = new LinkedHashMap<>();
        private BlockPos previousPosition;
        private Facing8 facing = Facing8.NORTH;

        Locomotive(EntityType<? extends MinecartFurnace> type, Level level) {
            super(type, level);
        }

        @Override
        public AbstractMinecart.Type getMinecartType() { return AbstractMinecart.Type.FURNACE; }

        @Override
        public boolean isPoweredCart() { return false; }

        @Override
        protected Item getDropItem() { return Items.MINECART; } // Placeholder for mod item in T-048.

        @Override
        public ItemStack getPickResult() { return new ItemStack(Items.MINECART); } // Placeholder.

        @Override
        protected void destroy(DamageSource source) {
            super.destroy(source); // Vanilla VehicleEntity owns one drop and custom name.
            // Permanent unlink policy is T-048/T-053; never clear on chunk unload.
        }

        @Override
        public void push(Entity entity) {
            if (entity instanceof Player) super.push(entity);
        }

        @Override
        public boolean canCollideWith(Entity entity) {
            if (entity instanceof Player) return false;
            return super.canCollideWith(entity);
        }

        @Override
        public void tick() {
            super.tick();
            if (this.level() instanceof ServerLevel serverLevel) {
                resolveLoadedOnly(serverLevel);
                this.previousPosition = this.blockPosition();
            }
        }

        private void resolveLoadedOnly(ServerLevel level) {
            for (UUID id : this.trainIds) {
                Entity found = level.getEntity(id);
                if (found instanceof AbstractMinecart cart && cart != this) {
                    BlockPos stop = this.stopPositions.get(id);
                    if (stop != null) {
                        // Candidate movement API only; T-053 defines actual timing and ownership.
                        cart.moveTo(stop.getX() + 0.5D, stop.getY(), stop.getZ() + 0.5D);
                        cart.setDeltaMovement(Vec3.ZERO);
                    }
                }
                // null means unresolved, never removed here.
            }
        }

        @Override
        protected void addAdditionalSaveData(CompoundTag tag) {
            super.addAdditionalSaveData(tag);
            ListTag ids = new ListTag();
            for (UUID id : this.trainIds) ids.add(StringTag.valueOf(id.toString()));
            tag.put("Train", ids);
            tag.putString("Facing", this.facing.saved());
            if (this.previousPosition != null) tag.putLong("PrevPos", this.previousPosition.asLong());
            ListTag stops = new ListTag();
            for (Map.Entry<UUID, BlockPos> entry : this.stopPositions.entrySet()) {
                CompoundTag row = new CompoundTag();
                row.putUUID("Cart", entry.getKey());
                row.putLong("Pos", entry.getValue().asLong());
                stops.add(row);
            }
            tag.put("TrainStops", stops);
        }

        @Override
        protected void readAdditionalSaveData(CompoundTag tag) {
            super.readAdditionalSaveData(tag);
            this.trainIds.clear();
            this.stopPositions.clear();
            ListTag ids = tag.getList("Train", Tag.TAG_STRING);
            for (int i = 0; i < ids.size(); i++) {
                try { this.trainIds.add(UUID.fromString(ids.getString(i))); }
                catch (IllegalArgumentException exception) { /* Defined invalid-entry policy in T-053. */ }
            }
            this.facing = tag.contains("Facing", Tag.TAG_STRING)
                ? Facing8.parse(tag.getString("Facing")) : Facing8.NORTH;
            this.previousPosition = tag.contains("PrevPos", Tag.TAG_LONG)
                ? BlockPos.of(tag.getLong("PrevPos")) : null;
            ListTag stops = tag.getList("TrainStops", Tag.TAG_COMPOUND);
            for (int i = 0; i < stops.size(); i++) {
                CompoundTag row = stops.getCompound(i);
                if (row.hasUUID("Cart") && row.contains("Pos", Tag.TAG_LONG)) {
                    UUID id = row.getUUID("Cart");
                    if (this.trainIds.contains(id)) this.stopPositions.put(id, BlockPos.of(row.getLong("Pos")));
                }
            }
        }
    }

    static final class LocomotiveItem extends Item {
        private final Supplier<EntityType<Locomotive>> type;
        LocomotiveItem(Properties properties, Supplier<EntityType<Locomotive>> type) {
            super(properties);
            this.type = type;
        }

        @Override
        public InteractionResult useOn(UseOnContext context) {
            Level level = context.getLevel();
            BlockPos pos = context.getClickedPos();
            BlockState state = level.getBlockState(pos);
            if (!state.is(BlockTags.RAILS) && !state.is(RAILS)) return InteractionResult.FAIL;
            ItemStack stack = context.getItemInHand();
            var nameBeforeConsumption = stack.get(DataComponents.CUSTOM_NAME);
            if (level instanceof ServerLevel serverLevel) {
                RailShape shape = state.getBlock() instanceof BaseRailBlock rail
                    ? rail.getRailDirection(state, level, pos, null) : RailShape.NORTH_SOUTH;
                double y = pos.getY() + 0.0625D + (shape.isAscending() ? 0.5D : 0.0D);
                Locomotive locomotive = new Locomotive(this.type.get(), level);
                locomotive.setPos(pos.getX() + 0.5D, y, pos.getZ() + 0.5D);
                if (nameBeforeConsumption != null) locomotive.setCustomName(nameBeforeConsumption);
                serverLevel.addFreshEntity(locomotive);
            }
            // Item consumption and duplicate client/server behavior belong to T-051.
            return InteractionResult.sidedSuccess(level.isClientSide());
        }
    }
}
