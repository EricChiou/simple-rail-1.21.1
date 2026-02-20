package com.ericchiu.simplerail.item;

import com.ericchiu.simplerail.entity.LocomotiveEntity;
import com.ericchiu.simplerail.registry.ModEntityTypes;
import net.minecraft.core.BlockPos;
import net.minecraft.core.component.DataComponents;
import net.minecraft.tags.BlockTags;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.context.UseOnContext;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.BaseRailBlock;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.RailShape;
import net.minecraft.world.level.gameevent.GameEvent;

public class LocomotiveItem extends Item {

  public LocomotiveItem(Item.Properties properties) {
    super(properties);
  }

  // 覆寫「對著方塊使用物品」的邏輯
  @Override
  public InteractionResult useOn(UseOnContext context) {
    Level level = context.getLevel();
    BlockPos blockpos = context.getClickedPos();
    BlockState blockstate = level.getBlockState(blockpos);

    // 檢查點擊的方塊是否有 "rails" 標籤 (包含所有種類的鐵軌)
    if (!blockstate.is(BlockTags.RAILS)) {
      return InteractionResult.FAIL;
    } else {
      ItemStack itemstack = context.getItemInHand();
      
      // 實體生成邏輯只能在伺服器端執行
      if (!level.isClientSide) {
        // 取得鐵軌的形狀，判斷是否為斜坡，用來微調生成高度
        RailShape railshape = blockstate.getBlock() instanceof BaseRailBlock 
            ? ((BaseRailBlock) blockstate.getBlock()).getRailDirection(blockstate, level, blockpos, null) 
            : RailShape.NORTH_SOUTH;
            
        double heightOffset = railshape.isAscending() ? 0.5D : 0.0D;

        // 建立我們的火車頭實體
        LocomotiveEntity locomotive = new LocomotiveEntity(ModEntityTypes.LOCOMOTIVE.get(), level);
        // 設定生成座標 (X置中, Y加上鐵軌高度與斜坡微調, Z置中)
        locomotive.setPos((double) blockpos.getX() + 0.5D, (double) blockpos.getY() + 0.0625D + heightOffset, (double) blockpos.getZ() + 0.5D);

        // 1.21.1 最佳實踐：使用 DataComponents 檢查物品是否有自定義名稱 (例如用鐵砧改過名)
        if (itemstack.has(DataComponents.CUSTOM_NAME)) {
          locomotive.setCustomName(itemstack.get(DataComponents.CUSTOM_NAME));
        }

        // 將實體加入世界，並觸發「放置實體」的遊戲事件 (給伏苓/史萊克感測器偵測用)
        level.addFreshEntity(locomotive);
        level.gameEvent(GameEvent.ENTITY_PLACE, blockpos, GameEvent.Context.of(context.getPlayer(), level.getBlockState(blockpos)));
      }

      // 消耗一個物品
      itemstack.shrink(1);
      return InteractionResult.sidedSuccess(level.isClientSide);
    }
  }
}