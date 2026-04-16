package com.ericchiu.simplerail.registry;

import com.ericchiu.simplerail.SimpleRail;
import net.minecraft.core.registries.Registries;
import net.minecraft.world.item.CreativeModeTab;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredRegister;

/**
 * 創造模式分頁註冊表
 */
public class CreativeTabRegistry {
  public static final DeferredRegister<CreativeModeTab> CREATIVE_MODE_TABS = DeferredRegister.create(Registries.CREATIVE_MODE_TAB, SimpleRail.MODID);

  // 註冊至 Mod Event Bus
  public static void register(IEventBus modEventBus) {
    CREATIVE_MODE_TABS.register(modEventBus);
  }
}
