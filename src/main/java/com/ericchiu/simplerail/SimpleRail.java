package com.ericchiu.simplerail;

import org.slf4j.Logger;
import com.mojang.logging.LogUtils;
import com.ericchiu.simplerail.config.Config;
import com.ericchiu.simplerail.registry.BlockRegistry;
import com.ericchiu.simplerail.registry.ItemRegistry;
import com.ericchiu.simplerail.registry.CreativeTabRegistry;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.common.Mod;
import net.neoforged.fml.ModContainer;
import net.neoforged.fml.config.ModConfig;
import net.neoforged.fml.event.lifecycle.FMLCommonSetupEvent;

/**
 * Simple Rail 模組主類別
 * 依據 GEMINI.md 規範：
 * 1. 取得 Mod Event Bus 透過建構子注入
 * 2. 註冊表分散至 registry 套件
 */
@Mod(SimpleRail.MODID)
public class SimpleRail {
  public static final String MODID = "simplerail";
  public static final Logger LOGGER = LogUtils.getLogger();

  public SimpleRail(IEventBus modEventBus, ModContainer modContainer) {
    // 註冊註冊表
    BlockRegistry.register(modEventBus);
    ItemRegistry.register(modEventBus);
    CreativeTabRegistry.register(modEventBus);

    // 註冊 Common Setup
    modEventBus.addListener(this::commonSetup);

    // 註冊設定檔
    modContainer.registerConfig(ModConfig.Type.COMMON, Config.SPEC);
  }

  private void commonSetup(FMLCommonSetupEvent event) {
    LOGGER.info("Simple Rail: Common Setup 啟動中...");
  }
}
