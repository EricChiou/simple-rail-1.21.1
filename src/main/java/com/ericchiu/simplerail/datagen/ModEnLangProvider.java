package com.ericchiu.simplerail.datagen;

import com.ericchiu.simplerail.SimpleRail;
import com.ericchiu.simplerail.registry.ModBlocks;
import com.ericchiu.simplerail.registry.ModEntityTypes;

import net.minecraft.data.PackOutput;
import net.neoforged.neoforge.common.data.LanguageProvider;

public class ModEnLangProvider extends LanguageProvider {
  public ModEnLangProvider(PackOutput output) {
    super(output, SimpleRail.MODID, "en_us");
  }

  @Override
  protected void addTranslations() {
    // 方塊名稱翻譯
    add(ModBlocks.HIGH_SPEED_RAIL.get(), "High Speed Rail");
    
    // 翻譯實體名稱 (顯示在死亡訊息、字幕或 F3 畫面)
    add(ModEntityTypes.LOCOMOTIVE.get(), "Locomotive");
    // 翻譯物品名稱 (顯示在背包裡的名字)
    add(ModEntityTypes.LOCOMOTIVE_ITEM.get(), "Locomotive");

    // 創造模式頁籤翻譯 (對應 ModCreativeModeTabs 中的 key)
    add("creativetab.simplerail.tab", "Simple Rail");

    add("message.simplerail.train_selected", "Train selected! Keep holding Shift and right-click minecarts to link them.");
    add("message.simplerail.train_not_found", "Locomotive not found. It may be destroyed or in an unloaded chunk.");
    add("message.simplerail.distance_too_far", "Too far away, please push it closer (Current: %s, needs to be < 2.0).");
    add("message.simplerail.link_success", "Linked successfully");
    add("message.simplerail.link_failed", "Link failed");
  }
}