package evidence.t014;

import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.Tag;
import net.minecraft.network.protocol.Packet;
import net.minecraft.network.protocol.game.ClientGamePacketListener;
import net.minecraft.network.syncher.EntityDataAccessor;
import net.minecraft.network.syncher.EntityDataSerializers;
import net.minecraft.network.syncher.SynchedEntityData;
import net.minecraft.server.level.ServerEntity;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.MobCategory;
import net.minecraft.world.entity.vehicle.MinecartFurnace;
import net.minecraft.world.level.Level;
import net.minecraft.world.phys.Vec3;

/** Source-compatible network boundary only. Not packaged, loaded or executed. */
public final class T014Probe {
    private T014Probe() {}

    static EntityType<Locomotive> candidateType() {
        return EntityType.Builder.<Locomotive>of(Locomotive::new, MobCategory.MISC)
            .sized(0.98F, 0.7F).clientTrackingRange(8).build("simplerail:locomotive_cart");
    }

    enum Facing8 {
        EAST(0, "east"), WEST(1, "west"), NORTH(2, "north"), SOUTH(3, "south"),
        NORTH_EAST(4, "north_east"), NORTH_WEST(5, "north_west"),
        SOUTH_EAST(6, "south_east"), SOUTH_WEST(7, "south_west");

        private final byte wire;
        private final String saved;

        Facing8(int wire, String saved) {
            this.wire = (byte)wire;
            this.saved = saved;
        }

        static Facing8 fromWire(byte value) {
            for (Facing8 direction : values()) if (direction.wire == value) return direction;
            return NORTH; // Invalid input policy remains for T-049.
        }

        static Facing8 fromSaved(String value) {
            for (Facing8 direction : values()) if (direction.saved.equals(value)) return direction;
            return NORTH; // Missing/invalid NEW-world data policy remains for T-049.
        }
    }

    static final class Locomotive extends MinecartFurnace {
        // Built-in serializers avoid registering an otherwise unused mod serializer.
        private static final EntityDataAccessor<Byte> FACING =
            SynchedEntityData.defineId(Locomotive.class, EntityDataSerializers.BYTE);
        private static final EntityDataAccessor<Boolean> LINKABLE =
            SynchedEntityData.defineId(Locomotive.class, EntityDataSerializers.BOOLEAN);

        Locomotive(EntityType<? extends MinecartFurnace> type, Level level) {
            super(type, level);
        }

        @Override
        protected void defineSynchedData(SynchedEntityData.Builder builder) {
            super.defineSynchedData(builder);
            builder.define(FACING, Facing8.NORTH.wire);
            builder.define(LINKABLE, true); // OLD default; removal/use decision belongs to T-049.
        }

        Facing8 getFacing() {
            return Facing8.fromWire(this.getEntityData().get(FACING));
        }

        boolean getLinkableSnapshot() {
            return this.getEntityData().get(LINKABLE);
        }

        void setFacingFromServer(Facing8 direction) {
            if (this.level() instanceof ServerLevel) {
                this.getEntityData().set(FACING, direction.wire);
            }
        }

        @Override
        public void tick() {
            super.tick();
            if (this.level() instanceof ServerLevel) {
                Vec3 motion = this.getDeltaMovement();
                double x = motion.x;
                double z = motion.z;
                if (x > 0.0 && z < 0.0) setFacingFromServer(Facing8.NORTH_EAST);
                else if (x < 0.0 && z < 0.0) setFacingFromServer(Facing8.NORTH_WEST);
                else if (x > 0.0 && z > 0.0) setFacingFromServer(Facing8.SOUTH_EAST);
                else if (x < 0.0 && z > 0.0) setFacingFromServer(Facing8.SOUTH_WEST);
                else if (x > 0.0) setFacingFromServer(Facing8.EAST);
                else if (x < 0.0) setFacingFromServer(Facing8.WEST);
                else if (z < 0.0) setFacingFromServer(Facing8.NORTH);
                else if (z > 0.0) setFacingFromServer(Facing8.SOUTH);
            }
        }

        @Override
        protected void addAdditionalSaveData(CompoundTag tag) {
            super.addAdditionalSaveData(tag);
            tag.putString("Facing", getFacing().saved);
        }

        @Override
        protected void readAdditionalSaveData(CompoundTag tag) {
            super.readAdditionalSaveData(tag);
            Facing8 saved = tag.contains("Facing", Tag.TAG_STRING)
                ? Facing8.fromSaved(tag.getString("Facing")) : Facing8.NORTH;
            // Entity NBT is loaded on the authoritative server in the intended implementation.
            setFacingFromServer(saved);
        }

        // Entity#getAddEntityPacket(ServerEntity) is inherited. It carries type/UUID/position;
        // ServerEntity separately pairs the non-default synched data values.
    }

    static Packet<ClientGamePacketListener> inheritedSpawnPacket(Locomotive entity, ServerEntity tracker) {
        return entity.getAddEntityPacket(tracker);
    }
}
