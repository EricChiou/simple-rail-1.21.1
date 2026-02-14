package com.ericchiu.simplerail.datagen;

import com.ericchiu.simplerail.registry.ModBlocks;
import net.minecraft.core.HolderLookup;
import net.minecraft.data.PackOutput;
import net.minecraft.data.recipes.RecipeCategory;
import net.minecraft.data.recipes.RecipeOutput;
import net.minecraft.data.recipes.RecipeProvider;
import net.minecraft.data.recipes.ShapedRecipeBuilder;
import net.minecraft.world.item.Items;
import net.neoforged.neoforge.common.conditions.IConditionBuilder;

import java.util.concurrent.CompletableFuture;

public class ModRecipeProvider extends RecipeProvider implements IConditionBuilder {

  public ModRecipeProvider(PackOutput output, CompletableFuture<HolderLookup.Provider> lookupProvider) {
    super(output, lookupProvider);
  }

  @Override
  protected void buildRecipes(RecipeOutput recipeOutput) {
    // 建立有序合成表 (Shaped Recipe)
    ShapedRecipeBuilder.shaped(RecipeCategory.TRANSPORTATION, ModBlocks.HIGH_SPEED_RAIL.get(), 6) // 產出 6 個高速軌道
        // 第一行: 木棍 金錠 木棍
        .pattern("SGS")
        // 第二行: 木棍 鐵錠 木棍
        .pattern("SIS")
        // 第三行: 木棍 紅石 木棍
        .pattern("SRS")
        // 定義符號代表的物品
        .define('I', Items.IRON_INGOT)
        .define('G', Items.GOLD_INGOT)
        .define('S', Items.STICK)
        .define('R', Items.REDSTONE) // 使用紅石代表需要能量
        // 設定解鎖條件: 當玩家獲得金錠或紅石時，解鎖配方書
        .unlockedBy("has_gold", has(Items.GOLD_INGOT))
        .unlockedBy("has_redstone", has(Items.REDSTONE))
        // 儲存合成表
        .save(recipeOutput);

    // 如果你有熔爐配方或其他類型，也都在這裡定義
  }
}