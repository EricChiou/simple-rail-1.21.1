package com.ericchiu.simplerail.registry;

import com.ericchiu.simplerail.SimpleRail;
import com.ericchiu.simplerail.entity.LocomotiveEntity;
import com.ericchiu.simplerail.item.LocomotiveItem;

import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.MobCategory;
import net.minecraft.world.item.Item;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredRegister;

import java.util.function.Supplier;

public class ModEntityTypes {

  // 使用 NeoForge 推薦的 DeferredRegister
  public static final DeferredRegister<EntityType<?>> ENTITY_TYPES = 
    DeferredRegister.create(BuiltInRegistries.ENTITY_TYPE, SimpleRail.MODID);

  // 使用 NeoForge 的 Items 註冊器
  public static final DeferredRegister.Items ITEMS = DeferredRegister.createItems(SimpleRail.MODID);

  // 註冊火車頭 EntityType
  // 使用 MobCategory.MISC 因為它不是一般的生物 (Creature/Monster)
  public static final Supplier<EntityType<LocomotiveEntity>> LOCOMOTIVE = 
    ENTITY_TYPES.register("locomotive", 
      () -> EntityType.Builder.<LocomotiveEntity>of(LocomotiveEntity::new, MobCategory.MISC)
        .sized(0.98F, 0.7F) // 使用與原版礦車相同的碰撞箱大小
        .clientTrackingRange(8) // 客戶端追蹤距離
        .build("locomotive"));

  // 註冊火車頭物品，並設定最大堆疊數量為 1 (與原版礦車相同)
  public static final Supplier<Item> LOCOMOTIVE_ITEM = ITEMS.register("locomotive", 
    () -> new LocomotiveItem(new Item.Properties().stacksTo(1)));

  public static void register(IEventBus eventBus) {
    ENTITY_TYPES.register(eventBus);
    ITEMS.register(eventBus);
  }
}