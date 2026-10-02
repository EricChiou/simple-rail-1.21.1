package com.ericchiu.simplerail.registry;

import com.ericchiu.simplerail.SimpleRail;
import net.minecraft.core.registries.Registries;
import net.minecraft.network.chat.Component;
import net.minecraft.world.item.CreativeModeTab;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

public final class ModCreativeTabs {
    private static final DeferredRegister<CreativeModeTab> TABS =
            DeferredRegister.create(Registries.CREATIVE_MODE_TAB, SimpleRail.MODID);

    // New registry key for the old ItemGroup label "simplerail.tab"; translation key stays unchanged.
    public static final DeferredHolder<CreativeModeTab, CreativeModeTab> RAIL = TABS.register("tab", () -> CreativeModeTab.builder()
            .title(Component.translatable("itemGroup.simplerail.tab"))
            .icon(() -> ModItems.HIGH_SPEED_RAIL.get().getDefaultInstance())
            .displayItems((parameters, output) -> {
                output.accept(ModItems.WRENCH.get());
                output.accept(ModItems.LOCOMOTIVE_CART.get());
                output.accept(ModItems.HIGH_SPEED_RAIL.get());
                output.accept(ModItems.HOLDING_RAIL.get());
                output.accept(ModItems.ONEWAY_RAIL.get());
                output.accept(ModItems.EJECT_RAIL.get());
                output.accept(ModItems.DESTORY_RAIL.get());
                output.accept(ModItems.TIMER_HOLDING_RAIL.get());
                output.accept(ModItems.CROSS_RAIL.get());
                output.accept(ModItems.Y_CROSS_RAIL.get());
                output.accept(ModItems.Y_CROSS_RIGHT_RAIL.get());
                output.accept(ModItems.TRAIN_DISPENSER.get());
                output.accept(ModItems.SIGNAL_TIMER.get());
            })
            .build());

    private ModCreativeTabs() {}

    public static void register(IEventBus modEventBus) {
        TABS.register(modEventBus);
    }
}
