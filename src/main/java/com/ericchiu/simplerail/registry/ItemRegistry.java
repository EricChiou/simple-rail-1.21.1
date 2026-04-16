package com.ericchiu.simplerail.registry;

import com.ericchiu.simplerail.SimpleRail;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredRegister;

/**
 * 物品註冊表
 */
public class ItemRegistry {
  public static final DeferredRegister.Items ITEMS = DeferredRegister.createItems(SimpleRail.MODID);

  // 註冊至 Mod Event Bus
  public static void register(IEventBus modEventBus) {
    ITEMS.register(modEventBus);
  }
}
