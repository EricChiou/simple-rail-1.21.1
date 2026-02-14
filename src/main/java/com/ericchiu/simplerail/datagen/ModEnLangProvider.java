package com.ericchiu.simplerail.datagen;

import com.ericchiu.simplerail.SimpleRail;
import com.ericchiu.simplerail.registry.ModBlocks;
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
    
    // 創造模式頁籤翻譯 (對應 ModCreativeModeTabs 中的 key)
    add("creativetab.simplerail.tab", "Simple Rail");
  }
}