package com.ericchiu.simplerail;

import com.ericchiu.simplerail.client.LocomotiveCartModel;
import com.ericchiu.simplerail.client.LocomotiveCartRenderer;
import com.ericchiu.simplerail.registry.ModEntities;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.ModContainer;
import net.neoforged.fml.common.Mod;
import net.neoforged.neoforge.client.event.EntityRenderersEvent;

@Mod(value = SimpleRail.MODID, dist = Dist.CLIENT)
public final class SimpleRailClient {
    public SimpleRailClient(IEventBus modEventBus, ModContainer ignored) {
        modEventBus.addListener(this::registerLayers);
        modEventBus.addListener(this::registerRenderers);
    }

    private void registerLayers(EntityRenderersEvent.RegisterLayerDefinitions event) {
        event.registerLayerDefinition(LocomotiveCartRenderer.LAYER, LocomotiveCartModel::createBodyLayer);
    }

    private void registerRenderers(EntityRenderersEvent.RegisterRenderers event) {
        event.registerEntityRenderer(ModEntities.LOCOMOTIVE_CART.get(), LocomotiveCartRenderer::new);
    }
}
