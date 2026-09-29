package evidence.t016;

import net.minecraft.core.BlockPos;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.vehicle.MinecartFurnace;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.common.NeoForge;
import net.neoforged.neoforge.common.world.chunk.RegisterTicketControllersEvent;
import net.neoforged.neoforge.common.world.chunk.TicketController;
import net.neoforged.neoforge.event.entity.EntityEvent;

// Evidence-only stand-in: MinecartFurnace replaces the not-yet-migrated locomotive type.
public final class T016Probe {
    private static final TicketController CONTROLLER = new TicketController(
        ResourceLocation.fromNamespaceAndPath("simplerail", "locomotive"));

    private T016Probe() {}

    public static void connect(IEventBus modBus) {
        modBus.addListener(T016Probe::registerController);
        NeoForge.EVENT_BUS.addListener(T016Probe::onEnteringSection);
    }

    private static void registerController(RegisterTicketControllersEvent event) {
        event.register(CONTROLLER);
    }

    private static void onEnteringSection(EntityEvent.EnteringSection event) {
        // Placeholder for OLD config value true. Actual config wiring belongs to T-020/T-076.
        boolean oldConfigEnabled = true;
        if (!oldConfigEnabled || !event.didChunkChange()) return;
        Entity entity = event.getEntity();
        if (!(entity instanceof MinecartFurnace) || !(entity.level() instanceof ServerLevel level)) return;

        BlockPos position = entity.blockPosition();
        int chunkX = position.getX() >> 4;
        int chunkZ = position.getZ() >> 4;
        int oldRadius = 2;
        for (int x = chunkX - oldRadius; x <= chunkX + oldRadius; x++) {
            for (int z = chunkZ - oldRadius; z <= chunkZ + oldRadius; z++) {
                // Deliberately use the OLD center x/z, not loop x/z. No release policy is added.
                boolean changed = CONTROLLER.forceChunk(level, entity, chunkX, chunkZ, true, true);
                if (changed) recordFirstNewTicket(level, entity, chunkX, chunkZ);
            }
        }
    }

    private static void recordFirstNewTicket(ServerLevel level, Entity owner, int chunkX, int chunkZ) {
        // Static observability signature only; the formal implementation will log evidence.
        level.getChunkSource().hasChunk(chunkX, chunkZ);
        owner.getUUID();
        level.dimension();
    }
}
