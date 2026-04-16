package com.ericchiu.simplerail.registry;

import com.ericchiu.simplerail.SimpleRail;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredRegister;

/**
 * 方塊註冊表
 */
public class BlockRegistry {
  public static final DeferredRegister.Blocks BLOCKS = DeferredRegister.createBlocks(SimpleRail.MODID);

  // 註冊至 Mod Event Bus
  public static void register(IEventBus modEventBus) {
    BLOCKS.register(modEventBus);
  }
}
