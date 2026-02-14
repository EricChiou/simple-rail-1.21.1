package com.ericchiu.simplerail;

import org.slf4j.Logger;

import com.ericchiu.simplerail.config.RailConfig;
import com.ericchiu.simplerail.datagen.DataGenerators;
import com.ericchiu.simplerail.registry.ModBlocks;
import com.ericchiu.simplerail.registry.ModCreativeModeTabs;
import com.mojang.logging.LogUtils;

import net.neoforged.bus.api.IEventBus;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.Mod;
import net.neoforged.fml.config.ModConfig;
import net.neoforged.fml.ModContainer;
import net.neoforged.neoforge.common.NeoForge;
import net.neoforged.neoforge.event.server.ServerStartingEvent;

// 此值應與 META-INF/neoforge.mods.toml 檔案中的項目相匹配
@Mod(SimpleRail.MODID)
public class SimpleRail {
  // 在一個通用位置定義 mod id，以供所有程式參考
  public static final String MODID = "simplerail";
  // 直接參考 slf4j logger
  public static final Logger LOGGER = LogUtils.getLogger();

  // mod 類別的建構子是載入 mod 時執行的第一段程式碼。
  // FML 會識別某些參數類型（例如 IEventBus 或 ModContainer）並自動傳入。
  public SimpleRail(IEventBus modEventBus, ModContainer modContainer) {
    // 為 Server 和我們感興趣的其他遊戲事件註冊自己。
    // 注意：只有當我們希望此類別 (SimpleRail) 直接回應事件時才需要此操作。
    // 如果此類別中沒有 @SubscribeEvent 註釋的函式（例如下方的 onServerStarting()），請勿新增此行。
    NeoForge.EVENT_BUS.register(this);

    // 註冊 DataGen 事件
    // DataGen 屬於 Mod Lifecycle 的一部分，所以掛載在 modEventBus
    modEventBus.addListener(DataGenerators::gatherData);

    // 註冊我們的 mod ModConfigSpec，以便 FML 為我們建立和載入設定檔
    modContainer.registerConfig(ModConfig.Type.SERVER, RailConfig.SERVER_SPEC);

    // 註冊 Blocks
    ModBlocks.register(modEventBus);

    // 註冊創造模式頁籤
    ModCreativeModeTabs.register(modEventBus);
  }

  // 可以使用 SubscribeEvent 並讓 Event Bus 發現要呼叫的方法
  @SubscribeEvent
  public void onServerStarting(ServerStartingEvent event) {
    // 在 server 啟動時執行某些操作
    LOGGER.info("Server starting");
  }
}
