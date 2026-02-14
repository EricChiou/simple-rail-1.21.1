package com.ericchiu.simplerail.datagen;

import net.minecraft.core.HolderLookup;
import net.minecraft.data.DataGenerator;
import net.minecraft.data.PackOutput;
import net.minecraft.data.loot.LootTableProvider;
import net.minecraft.world.level.storage.loot.parameters.LootContextParamSets;
import net.neoforged.neoforge.data.event.GatherDataEvent;

import java.util.Collections;
import java.util.List;
import java.util.concurrent.CompletableFuture;

public class DataGenerators {

  public static void gatherData(GatherDataEvent event) {
    DataGenerator generator = event.getGenerator();
    PackOutput packOutput = generator.getPackOutput();
    CompletableFuture<HolderLookup.Provider> lookupProvider = event.getLookupProvider();

    // Block States
    generator.addProvider(event.includeClient(), new ModBlockStateProvider(packOutput, event.getExistingFileHelper()));
    // Item Models
    generator.addProvider(event.includeClient(), new ModItemModelProvider(packOutput, event.getExistingFileHelper()));
    // Block Tags
    generator.addProvider(event.includeServer(), new ModBlockTagProvider(packOutput, lookupProvider, event.getExistingFileHelper()));
    // Loot Tables
    generator.addProvider(event.includeServer(), new LootTableProvider(
        packOutput,
        Collections.emptySet(),
        List.of(new LootTableProvider.SubProviderEntry(ModBlockLootTableProvider::new, LootContextParamSets.BLOCK)),
        lookupProvider
    ));
    // 新增: 合成表 (Recipes)
    generator.addProvider(event.includeServer(), new ModRecipeProvider(packOutput, lookupProvider));
    // 英文語言檔
    generator.addProvider(event.includeClient(), new ModEnLangProvider(packOutput));
    // 繁體中文語言檔
    generator.addProvider(event.includeClient(), new ModZhTwLangProvider(packOutput));
  }
}