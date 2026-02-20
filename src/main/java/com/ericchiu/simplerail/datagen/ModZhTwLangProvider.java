package com.ericchiu.simplerail.datagen;

import com.ericchiu.simplerail.SimpleRail;
import com.ericchiu.simplerail.registry.ModBlocks;
import com.ericchiu.simplerail.registry.ModEntityTypes;

import net.minecraft.data.PackOutput;
import net.neoforged.neoforge.common.data.LanguageProvider;

public class ModZhTwLangProvider extends LanguageProvider {
  public ModZhTwLangProvider(PackOutput output) {
    // 建構子中指定 modid 與 locale 為 "zh_tw"
    super(output, SimpleRail.MODID, "zh_tw");
  }

  @Override
  protected void addTranslations() {
    // 方塊名稱翻譯
    add(ModBlocks.HIGH_SPEED_RAIL.get(), "高速軌道");

    add(ModEntityTypes.LOCOMOTIVE.get(), "火車頭");
    add(ModEntityTypes.LOCOMOTIVE_ITEM.get(), "火車頭");

    // 創造模式頁籤翻譯 (對應 ModCreativeModeTabs 定義的 key)
    add("creativetab.simplerail.tab", "Simple Rail");

    add("message.simplerail.train_selected", "已選擇火車！請保持 Shift 並連續右鍵點擊要連結的礦車");
    add("message.simplerail.train_not_found", "找不到火車頭，可能已被摧毀或距離過遠 (區塊未載入)");
    add("message.simplerail.distance_too_far", "距離太遠，請推近一點 (目前: %s，需小於 2.0)");
    add("message.simplerail.link_success", "連結成功");
    add("message.simplerail.link_failed", "連結失敗");
  }
}