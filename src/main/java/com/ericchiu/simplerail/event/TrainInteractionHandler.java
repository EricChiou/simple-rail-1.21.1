package com.ericchiu.simplerail.event;

import com.ericchiu.simplerail.entity.LocomotiveEntity;

import net.minecraft.ChatFormatting;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.neoforge.event.entity.player.PlayerInteractEvent;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

public class TrainInteractionHandler {

  // 暫存玩家目前選擇的火車頭 UUID
  // 格式: <玩家 UUID, 火車頭 UUID>
  private static final Map<UUID, UUID> PLAYER_SELECTED_TRAIN = new HashMap<>();

  @SubscribeEvent
  public static void onEntityInteract(PlayerInteractEvent.EntityInteract event) {
    Player player = event.getEntity();
    Entity target = event.getTarget();

    // 只處理伺服器端邏輯
    if (player.level().isClientSide) return;
    // 只處理玩家對礦車的互動，且必須是蹲下狀態
    if (!player.isCrouching() || !(target instanceof AbstractMinecart needLinkedCart)) return;

    // 取消原版互動行為，改由我們的邏輯處理
    event.setCanceled(true);
    event.setCancellationResult(InteractionResult.SUCCESS);

    UUID playerUUID = player.getUUID();
    UUID locomotiveUUID = getOwnerLocomotiveUuid(needLinkedCart);

    // 步驟 1: 如果玩家選擇的礦車屬於某列火車，就直接選擇那台火車頭 (如果有選擇過火車頭則直接覆蓋)
    if (locomotiveUUID != null) {
      PLAYER_SELECTED_TRAIN.put(playerUUID, locomotiveUUID);
      player.sendSystemMessage(Component.translatable("message.simplerail.train_selected").withStyle(ChatFormatting.AQUA));
      return;
    }

    // 步驟 2: 如果玩家沒有選擇過火車頭，維持原版互動，不做任何處理
    locomotiveUUID = PLAYER_SELECTED_TRAIN.get(playerUUID);
    if (locomotiveUUID == null) return;
    
    // 步驟 3: 如果找不到火車頭實體，代表可能已經被摧毀了，清除玩家的選擇並提示錯誤訊息
    Entity entityInWorld = ((ServerLevel) player.level()).getEntity(locomotiveUUID);
    if (!(entityInWorld instanceof LocomotiveEntity locomotiveEntity)) {
      PLAYER_SELECTED_TRAIN.remove(playerUUID);
      player.sendSystemMessage(Component.translatable("message.simplerail.train_not_found").withStyle(ChatFormatting.RED));
      return;
    }

    // 步驟 4: 嘗試將這台礦車連結到玩家選擇的火車頭上，判斷火車最後一節車廂與要連結的礦車距離
    AbstractMinecart lastCart = locomotiveEntity.getLastCart();
    double distance = lastCart.distanceTo(needLinkedCart);

    // 如果礦車距離火車太遠，就拒絕連結並提示玩家
    if (distance >= 2.0D) {
      String formattedDistance = String.format("%.1f", distance);
      player.sendSystemMessage(Component.translatable("message.simplerail.distance_too_far", formattedDistance).withStyle(ChatFormatting.RED));
      return;
    }

    if (locomotiveEntity.linkNewCart(needLinkedCart)) {
      player.sendSystemMessage(Component.translatable("message.simplerail.link_success").withStyle(ChatFormatting.GREEN));
      return;
    }

    player.sendSystemMessage(Component.translatable("message.simplerail.link_failed").withStyle(ChatFormatting.RED));
  }

  // 檢查這台礦車是否已經屬於某列火車了，如果是就回傳火車頭的 UUID；如果不是就回傳 null
  private static UUID getOwnerLocomotiveUuid(AbstractMinecart cart) {
    // 如果點擊的就是火車頭，直接回傳
    if (cart instanceof LocomotiveEntity locomotive) return locomotive.getUUID();

    // 掃描礦車身上的 Tag，提取火車頭 UUID
    for (String tag : cart.getTags()) {
      UUID locomotiveUuid = LocomotiveEntity.getLocotiveUuid(tag);
      if (locomotiveUuid == null) continue; // 不是火車標籤，繼續找下一個
      return locomotiveUuid; // 找到火車標籤，回傳火車頭 UUID
    }
    
    // 找不到標籤，代表這是一台野生礦車
    return null;
  }
}