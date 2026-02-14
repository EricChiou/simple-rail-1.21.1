package com.ericchiu.simplerail.datagen;

import com.ericchiu.simplerail.SimpleRail;
import net.minecraft.data.PackOutput;
import net.neoforged.neoforge.client.model.generators.ItemModelProvider;
import net.neoforged.neoforge.common.data.ExistingFileHelper;

public class ModItemModelProvider extends ItemModelProvider {
  public ModItemModelProvider(PackOutput output, ExistingFileHelper existingFileHelper) {
    super(output, SimpleRail.MODID, existingFileHelper);
  }

  @Override
  protected void registerModels() {
    // 明確指定：繼承原版的 item/generated (2D 平面模型)
    // 並將 layer0 (最底層材質) 指向我們已有的 block/high_speed_rail 圖片
    withExistingParent("high_speed_rail", mcLoc("item/generated"))
        .texture("layer0", modLoc("block/high_speed_rail"));
  }
}