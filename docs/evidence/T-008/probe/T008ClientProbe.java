package evidence.t008;

import net.minecraft.client.Minecraft;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.ModContainer;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.fml.common.Mod;
import net.neoforged.fml.event.lifecycle.FMLClientSetupEvent;

/** Compile-only physical-client boundary, separate from the common class. */
@Mod(value = T008Probe.ID, dist = Dist.CLIENT)
@EventBusSubscriber(modid = T008Probe.ID, value = Dist.CLIENT)
public final class T008ClientProbe {
    public T008ClientProbe(ModContainer container) {}
    @SubscribeEvent
    static void clientSetup(FMLClientSetupEvent event) {
        event.enqueueWork(() -> { String name = Minecraft.getInstance().getUser().getName(); });
    }
}
