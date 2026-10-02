package evidence.t054;

import com.ericchiu.simplerail.entity.LocomotiveCartEntity;
import com.ericchiu.simplerail.entity.TrainOwnershipData;
import com.mojang.logging.LogUtils;
import java.util.UUID;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.commands.arguments.EntityArgument;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.neoforged.neoforge.common.NeoForge;
import net.neoforged.neoforge.event.RegisterCommandsEvent;
import org.slf4j.Logger;

/** Diagnostic commands only; production linking UI belongs to T-057/T-059. */
public final class TrainProbe {
    private static final Logger LOG = LogUtils.getLogger();

    private TrainProbe() {}

    public static void install() {
        NeoForge.EVENT_BUS.addListener(TrainProbe::commands);
        LOG.warn("[T054] DIAGNOSTIC ONLY: /t054 links and inspects loaded carts; no release feature");
    }

    private static void commands(RegisterCommandsEvent event) {
        event.getDispatcher().register(Commands.literal("t054").requires(source -> source.hasPermission(2))
                .then(Commands.literal("link")
                        .then(Commands.argument("head", EntityArgument.entity())
                                .then(Commands.argument("cart", EntityArgument.entity())
                                        .executes(ctx -> link(ctx.getSource(),
                                                EntityArgument.getEntity(ctx, "head"),
                                                EntityArgument.getEntity(ctx, "cart"))))))
                .then(Commands.literal("inspect")
                        .then(Commands.argument("head", EntityArgument.entity())
                                .executes(ctx -> inspect(ctx.getSource(), EntityArgument.getEntity(ctx, "head"))))));
    }

    private static int link(CommandSourceStack source, Entity head, Entity cart) {
        ServerLevel level = source.getLevel();
        if (!(head instanceof LocomotiveCartEntity locomotive) || !(cart instanceof AbstractMinecart carriage)
                || head.level() != level || cart.level() != level) {
            source.sendFailure(Component.literal("[T054] select one locomotive and one cart in this dimension"));
            return 0;
        }
        boolean linked = locomotive.linkNewCart(level, carriage);
        LOG.info("[T054] LINK dimension={} head={} cart={} linked={} owner={} order={}",
                level.dimension().location(), head.getUUID(), cart.getUUID(), linked,
                TrainOwnershipData.forLevel(level).ownerOf(cart.getUUID()), locomotive.trainIds());
        source.sendSuccess(() -> Component.literal("[T054] linked=" + linked + " head=" + head.getUUID()
                + " cart=" + cart.getUUID()), false);
        return linked ? 1 : 0;
    }

    private static int inspect(CommandSourceStack source, Entity head) {
        if (!(head instanceof LocomotiveCartEntity locomotive) || head.level() != source.getLevel()) {
            source.sendFailure(Component.literal("[T054] select a locomotive in this dimension"));
            return 0;
        }
        ServerLevel level = source.getLevel();
        LOG.info("[T054] HEAD dimension={} head={} pos={} facing={} order={}",
                level.dimension().location(), head.getUUID(), head.blockPosition(),
                locomotive.facing(), locomotive.trainIds());
        int index = 0;
        for (UUID id : locomotive.trainIds()) {
            Entity found = level.getEntity(id);
            LOG.info("[T054] CART index={} uuid={} loaded={} removed={} dimension={} pos={} owner={}",
                    index++, id, found != null, found != null && found.isRemoved(),
                    found == null ? "unresolved" : found.level().dimension().location(),
                    found == null ? "unresolved" : found.blockPosition(),
                    TrainOwnershipData.forLevel(level).ownerOf(id));
        }
        source.sendSuccess(() -> Component.literal("[T054] head=" + head.getUUID()
                + " cars=" + locomotive.trainIds().size() + "; see server log"), false);
        return locomotive.trainIds().size();
    }
}
