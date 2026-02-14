package com.ericchiu.simplerail.registry;

import com.ericchiu.simplerail.SimpleRail;
import com.ericchiu.simplerail.block.HighSpeedRailBlock;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.SoundType;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredBlock;
import net.neoforged.neoforge.registries.DeferredRegister;

import java.util.function.Supplier;

public class ModBlocks {
  // 創建一個針對 BLOCKS 註冊表的 DeferredRegister
  public static final DeferredRegister.Blocks BLOCKS = DeferredRegister.createBlocks(SimpleRail.MODID);
  public static final DeferredRegister.Items ITEMS = DeferredRegister.createItems(SimpleRail.MODID);

  // 註冊高速軌道方塊
  // 使用 ofFullCopy 複製原版動力軌道的屬性 (硬度、抗爆性、發光度等)
  public static final DeferredBlock<HighSpeedRailBlock> HIGH_SPEED_RAIL = registerBlock("high_speed_rail",
    () -> new HighSpeedRailBlock(BlockBehaviour.Properties.ofFullCopy(Blocks.POWERED_RAIL)
      .strength(0.7F) // 設定硬度
      .sound(SoundType.METAL) // 設定音效
      .noCollission())); // 軌道通常無碰撞      

  // 同時註冊方塊與對應的方塊物品 (BlockItem)
  private static <T extends Block> DeferredBlock<T> registerBlock(String name, Supplier<T> block) {
    DeferredBlock<T> toReturn = BLOCKS.register(name, block);
    registerBlockItem(name, toReturn);
    return toReturn;
  }

  // 註冊對應的物品，這樣玩家才能在背包中持有它
  private static <T extends Block> void registerBlockItem(String name, DeferredBlock<T> block) {
    ITEMS.register(name, () -> new BlockItem(block.get(), new Item.Properties()));
  }

  public static void register(IEventBus eventBus) {
    BLOCKS.register(eventBus);
    ITEMS.register(eventBus);
  }
}
