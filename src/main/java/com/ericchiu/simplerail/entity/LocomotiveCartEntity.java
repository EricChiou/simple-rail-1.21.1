package com.ericchiu.simplerail.entity;

import com.ericchiu.simplerail.registry.ModItems;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import net.minecraft.core.BlockPos;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.LongTag;
import net.minecraft.nbt.StringTag;
import net.minecraft.nbt.Tag;
import net.minecraft.network.syncher.EntityDataAccessor;
import net.minecraft.network.syncher.EntityDataSerializers;
import net.minecraft.network.syncher.SynchedEntityData;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.entity.vehicle.Minecart;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.phys.Vec3;

/** Ordinary minecart movement with a locomotive body, no passengers, and owned train state. */
public final class LocomotiveCartEntity extends Minecart {
    private static final EntityDataAccessor<Byte> FACING =
            SynchedEntityData.defineId(LocomotiveCartEntity.class, EntityDataSerializers.BYTE);
    private static final EntityDataAccessor<Boolean> LINKABLE =
            SynchedEntityData.defineId(LocomotiveCartEntity.class, EntityDataSerializers.BOOLEAN);
    private static final double DETECT_RANGE = 0.2D;

    private final TrainFormation formation = new TrainFormation();
    private final TrainBlockRoute blockRoute = new TrainBlockRoute();
    private BlockPos previousBlock;
    private boolean ownershipReconciled;

    public LocomotiveCartEntity(EntityType<?> type, Level level) {
        super(type, level);
    }

    @Override
    protected void defineSynchedData(SynchedEntityData.Builder builder) {
        super.defineSynchedData(builder);
        builder.define(FACING, Facing8.NORTH.wire());
        // Retained from OLD for data compatibility within the new protocol. It is not a link policy.
        builder.define(LINKABLE, true);
    }

    public Facing8 facing() {
        return Facing8.fromWire(getEntityData().get(FACING));
    }

    public boolean isLinkable() {
        return getEntityData().get(LINKABLE);
    }

    public void setFacingFromServer(Facing8 facing) {
        if (!level().isClientSide() && facing != null) {
            getEntityData().set(FACING, facing.wire());
        }
    }

    public List<UUID> trainIds() {
        return formation.carts();
    }

    /** Remove this head and its ordered cars, including cars currently outside loaded chunks. */
    public void discardTrain(ServerLevel server) {
        if (level() != server || isRemoved()) return;
        TrainOwnershipData owners = TrainOwnershipData.forLevel(server);
        List<UUID> ids = List.copyOf(formation.carts());
        List<AbstractMinecart> loaded = new ArrayList<>();
        for (UUID id : ids) {
            UUID owner = owners.ownerOf(id);
            if (owner != null && !owner.equals(getUUID())) continue;
            Entity found = server.getEntity(id);
            if (found instanceof AbstractMinecart cart && cart != this && !cart.isRemoved()) {
                loaded.add(cart);
            } else if (found == null) {
                // An unloaded carriage must be removed when it next joins this level.
                owners.markPendingRemoval(id);
            }
        }
        // Drop claims before removal callbacks, so they cannot cut the tail halfway through deletion.
        owners.releaseTrain(getUUID());
        for (AbstractMinecart cart : loaded) cart.discard();
        discard();
    }

    public boolean linkNewCart(ServerLevel level, AbstractMinecart cart) {
        if (this.level() != level || cart.level() != level || cart == this || cart.isRemoved()
                || !isLinkable()) return false;
        UUID id = cart.getUUID();
        if (formation.carts().contains(id)) return false;
        TrainOwnershipData owners = TrainOwnershipData.forLevel(level);
        if (!owners.claim(id, getUUID())) return false;
        BlockPos at = cart.blockPosition();
        if (!formation.add(id, cell(at))) {
            owners.release(id, getUUID());
            return false;
        }
        blockRoute.seedTail(cell(at), formation.carts().size());
        return true;
    }

    /** Only a confirmed explicit unlink changes the authoritative ordered list. */
    public boolean unlinkCart(ServerLevel level, UUID cartId) {
        if (this.level() != level || !formation.remove(cartId)) return false;
        TrainOwnershipData.forLevel(level).release(cartId, getUUID());
        return true;
    }

    /** Permanent removal of a middle carriage uncouples it and the whole tail. */
    public void disconnectFrom(ServerLevel level, UUID cartId) {
        if (this.level() != level) return;
        TrainOwnershipData owners = TrainOwnershipData.forLevel(level);
        for (UUID id : formation.disconnectFrom(cartId)) {
            owners.release(id, getUUID());
        }
    }

    @Override
    public InteractionResult interact(Player player, InteractionHand hand) {
        // Minecart.interact starts riding; locomotives must never do that.
        return InteractionResult.PASS;
    }

    @Override
    protected boolean canAddPassenger(Entity passenger) {
        return false;
    }

    @Override
    protected Item getDropItem() {
        return ModItems.LOCOMOTIVE_CART.get();
    }

    @Override
    public ItemStack getPickResult() {
        return new ItemStack(ModItems.LOCOMOTIVE_CART.get());
    }

    @Override
    public void push(Entity entity) {
        if (entity instanceof Player) super.push(entity);
    }

    @Override
    public boolean canCollideWith(Entity entity) {
        if (entity instanceof Player) return false;
        if (entity instanceof LocomotiveCartEntity) return super.canCollideWith(entity);
        if (entity instanceof AbstractMinecart cart) {
            if (!level().isClientSide()) cart.setDeltaMovement(getDeltaMovement());
            return false;
        }
        if (entity.isAlive()) {
            if (!level().isClientSide() && !getDeltaMovement().equals(Vec3.ZERO)) entity.kill();
            return false;
        }
        return super.canCollideWith(entity);
    }

    @Override
    public void tick() {
        super.tick();
        if (!(level() instanceof ServerLevel server)) return;
        TrainOwnershipData owners = TrainOwnershipData.forLevel(server);
        for (UUID cut : owners.takePendingCuts(getUUID())) disconnectFrom(server, cut);
        if (!ownershipReconciled) {
            for (UUID id : formation.carts()) owners.claim(id, getUUID());
            ownershipReconciled = true;
        }
        Vec3 motion = getDeltaMovement();
        setFacingFromServer(Facing8.fromMotion(motion.x, motion.z, facing()));
        BlockPos current = blockPosition();
        if (previousBlock == null) {
            previousBlock = current;
        } else if (!previousBlock.equals(current)) {
            blockRoute.record(cell(previousBlock), cell(current), formation.carts().size());
            formation.advance(cell(previousBlock));
            previousBlock = current;
        }
        if (motion.equals(Vec3.ZERO) || isNearBlockCenter()) moveLoadedCarts(server);
    }

    private boolean isNearBlockCenter() {
        BlockPos pos = blockPosition();
        return getX() >= pos.getX() + DETECT_RANGE && getX() <= pos.getX() + 1.0D - DETECT_RANGE
                && getZ() >= pos.getZ() + DETECT_RANGE && getZ() <= pos.getZ() + 1.0D - DETECT_RANGE;
    }

    private void moveLoadedCarts(ServerLevel server) {
        List<UUID> carts = formation.carts();
        TrainBlockRoute.Point head = new TrainBlockRoute.Point(getX(), getY(), getZ());
        boolean routeReady = blockRoute.readyFor(head, carts.size());
        for (int i = 0; i < carts.size(); i++) {
            UUID id = carts.get(i);
            Entity found = server.getEntity(id);
            TrainFormation.Cell stop = formation.stop(id);
            if (found instanceof AbstractMinecart cart && cart != this && !cart.isRemoved()
                    && cart.level() == server) {
                TrainBlockRoute.Point target = routeReady ? blockRoute.target(head, i + 1) : null;
                if (target != null) {
                    cart.moveTo(target.x(), target.y(), target.z());
                    cart.setDeltaMovement(Vec3.ZERO);
                } else if (stop != null) {
                    // Until the full route is known, retain the previous block-stop behavior.
                    cart.moveTo(stop.x() + 0.5D, stop.y(), stop.z() + 0.5D);
                    cart.setDeltaMovement(Vec3.ZERO);
                }
            }
            // A missing entity is unresolved, not proof of permanent deletion.
        }
    }

    @Override
    public void remove(RemovalReason reason) {
        if (reason.shouldDestroy() && !isRemoved() && level() instanceof ServerLevel server) {
            // This also releases claims for cars in unloaded chunks.
            TrainOwnershipData.forLevel(server).releaseTrain(getUUID());
        }
        super.remove(reason);
    }

    @Override
    protected void addAdditionalSaveData(CompoundTag tag) {
        super.addAdditionalSaveData(tag);
        tag.putInt("TrainSchema", 4);
        tag.putString("Facing", facing().saved());
        if (previousBlock != null) tag.putLong("PrevPos", previousBlock.asLong());
        ListTag ids = new ListTag();
        ListTag stops = new ListTag();
        for (UUID id : formation.carts()) {
            ids.add(StringTag.valueOf(id.toString()));
            TrainFormation.Cell stop = formation.stop(id);
            if (stop != null) {
                CompoundTag row = new CompoundTag();
                row.putUUID("Cart", id);
                row.putLong("Pos", new BlockPos(stop.x(), stop.y(), stop.z()).asLong());
                stops.add(row);
            }
        }
        tag.put("Train", ids);
        tag.put("TrainStops", stops);
        ListTag route = new ListTag();
        for (TrainFormation.Cell stop : blockRoute.cells()) {
            route.add(LongTag.valueOf(new BlockPos(stop.x(), stop.y(), stop.z()).asLong()));
        }
        tag.put("TrainRoute", route);
    }

    @Override
    protected void readAdditionalSaveData(CompoundTag tag) {
        super.readAdditionalSaveData(tag);
        // This schema is only for NEW worlds; no OLD Forge NBT conversion is attempted.
        setFacingFromServer(Facing8.fromSaved(tag.getString("Facing")));
        previousBlock = tag.contains("PrevPos", Tag.TAG_LONG) ? BlockPos.of(tag.getLong("PrevPos")) : null;
        List<UUID> ids = new ArrayList<>();
        ListTag savedIds = tag.getList("Train", Tag.TAG_STRING);
        for (int i = 0; i < savedIds.size(); i++) {
            try { ids.add(UUID.fromString(savedIds.getString(i))); }
            catch (IllegalArgumentException ignored) { /* Invalid NEW data is skipped. */ }
        }
        Map<UUID, TrainFormation.Cell> stops = new HashMap<>();
        ListTag savedStops = tag.getList("TrainStops", Tag.TAG_COMPOUND);
        HashSet<UUID> wanted = new HashSet<>(ids);
        for (int i = 0; i < savedStops.size(); i++) {
            CompoundTag row = savedStops.getCompound(i);
            if (row.hasUUID("Cart") && row.contains("Pos", Tag.TAG_LONG)) {
                UUID id = row.getUUID("Cart");
                if (wanted.contains(id)) stops.putIfAbsent(id, cell(BlockPos.of(row.getLong("Pos"))));
            }
        }
        formation.load(ids, stops);
        ListTag savedRoute = tag.getList("TrainRoute", Tag.TAG_LONG);
        if (savedRoute.isEmpty()) {
            // R3 NEW saves have only block stops; seed what is known without inventing a tail.
            for (UUID id : formation.carts()) blockRoute.seedTail(formation.stop(id), ids.size());
        } else {
            List<TrainFormation.Cell> cells = new ArrayList<>();
            for (int i = 0; i < savedRoute.size(); i++) {
                cells.add(cell(BlockPos.of(((LongTag) savedRoute.get(i)).getAsLong())));
            }
            blockRoute.load(cells, ids.size());
        }
        // Older NEW R1/R2 TrainPath is ignored; this route uses block centers.
        ownershipReconciled = false;
    }

    private static TrainFormation.Cell cell(BlockPos pos) {
        return new TrainFormation.Cell(pos.getX(), pos.getY(), pos.getZ());
    }
}
