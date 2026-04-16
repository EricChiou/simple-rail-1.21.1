package com.ericchiu.simplerail.client;

import com.ericchiu.simplerail.SimpleRail;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.fml.event.lifecycle.FMLClientSetupEvent;

/**
 * 客戶端專屬邏輯
 * 依據 GEMINI.md 規範：客戶端事件必須透過 @EventBusSubscriber(modid = MODID, value = Dist.CLIENT) 進行安全註冊
 */
@EventBusSubscriber(modid = SimpleRail.MODID, value = Dist.CLIENT)
public class SimpleRailClient {
  
  @SubscribeEvent
  static void onClientSetup(FMLClientSetupEvent event) {
    SimpleRail.LOGGER.info("Simple Rail: Client Setup 啟動中...");
  }
}
