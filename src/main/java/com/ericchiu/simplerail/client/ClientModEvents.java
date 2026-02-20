package com.ericchiu.simplerail.client;

import com.ericchiu.simplerail.client.model.LocomotiveModel;
import com.ericchiu.simplerail.client.renderer.LocomotiveRenderer;
import com.ericchiu.simplerail.registry.ModEntityTypes;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.neoforge.client.event.EntityRenderersEvent;

// 限定此事件監聽器只能在客戶端 (Client) 的 Mod Event Bus 觸發
public class ClientModEvents {

  /**
   * 註冊實體渲染器 (Renderer)
   * 將我們的 LocomotiveEntity 綁定到剛剛寫好的 LocomotiveRenderer
   */
  @SubscribeEvent
  public static void registerRenderers(EntityRenderersEvent.RegisterRenderers event) {
    event.registerEntityRenderer(ModEntityTypes.LOCOMOTIVE.get(), LocomotiveRenderer::new);
  }

  /**
   * 註冊模型層定義 (Layer Definition)
   * 告訴遊戲 ModModelLayers.LOCOMOTIVE_LAYER 這個 ID 對應什麼形狀。
   * 這裡我們直接借用原版礦車的形狀 (MinecartModel::createBodyLayer)
   */
  @SubscribeEvent
  public static void registerLayerDefinitions(EntityRenderersEvent.RegisterLayerDefinitions event) {
    event.registerLayerDefinition(ModModelLayers.LOCOMOTIVE_LAYER, LocomotiveModel::createBodyLayer);
  }
}