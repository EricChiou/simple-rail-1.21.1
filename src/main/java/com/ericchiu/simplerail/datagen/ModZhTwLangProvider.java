package com.ericchiu.simplerail.datagen;

import com.ericchiu.simplerail.SimpleRail;
import com.ericchiu.simplerail.registry.ModBlocks;
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

    // 創造模式頁籤翻譯 (對應 ModCreativeModeTabs 定義的 key)
    add("creativetab.simplerail.tab", "Simple Rail");

    // 如果你有其他物品或訊息，都在這裡新增
    // 例如: add("message.simplerail.too_fast", "速度太快了！");
  }
}