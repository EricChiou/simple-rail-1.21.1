package com.ericchiu.simplerail.registry;

import com.ericchiu.simplerail.SimpleRail;
import net.minecraft.core.registries.Registries;
import net.minecraft.network.chat.Component;
import net.minecraft.world.item.CreativeModeTab;
import net.minecraft.world.item.ItemStack;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

public class ModCreativeModeTabs {
  // 建立創造模式頁籤的 DeferredRegister
  public static final DeferredRegister<CreativeModeTab> CREATIVE_MODE_TABS = 
    DeferredRegister.create(Registries.CREATIVE_MODE_TAB, SimpleRail.MODID);

  // 註冊我們的自訂頁籤
  public static final DeferredHolder<CreativeModeTab, CreativeModeTab> SIMPLE_RAIL_TAB = 
    CREATIVE_MODE_TABS.register("simple_rail_tab", () -> CreativeModeTab.builder()
      // 設定頁籤標題 (需在 Lang 檔中翻譯)
      .title(Component.translatable("creativetab.simplerail.tab"))
      // 設定頁籤圖示 (使用高速軌道方塊作為圖示)
      .icon(() -> new ItemStack(ModBlocks.HIGH_SPEED_RAIL.get()))
      // 定義頁籤內要顯示的物品
      .displayItems((parameters, output) -> {
        // 將高速軌道方塊加入頁籤
        output.accept(ModBlocks.HIGH_SPEED_RAIL.get());
        
        // 如果未來有更多物品，都在這裡加入 output.accept(...)
      }).build());

  // 註冊方法，供主程式呼叫
  public static void register(IEventBus eventBus) {
    CREATIVE_MODE_TABS.register(eventBus);
  }
}