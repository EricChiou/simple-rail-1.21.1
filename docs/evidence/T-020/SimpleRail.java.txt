package com.ericchiu.simplerail;

import com.ericchiu.simplerail.config.CommonConfig;
import com.ericchiu.simplerail.registry.ModBlocks;
import com.ericchiu.simplerail.registry.ModCreativeTabs;
import com.ericchiu.simplerail.registry.ModItems;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.ModContainer;
import net.neoforged.fml.common.Mod;

@Mod(SimpleRail.MODID)
public final class SimpleRail {
    public static final String MODID = "simplerail";

    public SimpleRail(IEventBus modEventBus, ModContainer modContainer) {
        CommonConfig.register(modEventBus, modContainer);
        ModBlocks.register(modEventBus);
        ModItems.register(modEventBus);
        ModCreativeTabs.register(modEventBus);
    }
}
