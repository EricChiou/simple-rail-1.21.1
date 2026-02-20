package com.ericchiu.simplerail.client;

import com.ericchiu.simplerail.SimpleRail;
import net.minecraft.client.model.geom.ModelLayerLocation;
import net.minecraft.resources.ResourceLocation;

public class ModModelLayers {

  // 定義火車頭模型的層位置 ID
  // "main" 表示這是這個實體的主模型層
  public static final ModelLayerLocation LOCOMOTIVE_LAYER = new ModelLayerLocation(
    ResourceLocation.fromNamespaceAndPath(SimpleRail.MODID, "locomotive"), "main");

}