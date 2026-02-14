package com.ericchiu.simplerail.datagen;

import com.ericchiu.simplerail.SimpleRail;
import com.ericchiu.simplerail.registry.ModBlocks;

import net.minecraft.core.HolderLookup;
import net.minecraft.data.PackOutput;
import net.minecraft.tags.BlockTags;
import net.neoforged.neoforge.common.data.BlockTagsProvider;
import net.neoforged.neoforge.common.data.ExistingFileHelper;
import org.jetbrains.annotations.Nullable;

import java.util.concurrent.CompletableFuture;

public class ModBlockTagProvider extends BlockTagsProvider {
  public ModBlockTagProvider(PackOutput output, CompletableFuture<HolderLookup.Provider> lookupProvider, @Nullable ExistingFileHelper existingFileHelper) {
    super(output, lookupProvider, SimpleRail.MODID, existingFileHelper);
  }

  @Override
  protected void addTags(HolderLookup.Provider provider) {
    // 關鍵：將我們的高速軌道加入 Rails 標籤
    tag(BlockTags.RAILS).add(ModBlocks.HIGH_SPEED_RAIL.get());
    
    // 設定需要鎬子挖掘
    tag(BlockTags.MINEABLE_WITH_PICKAXE).add(ModBlocks.HIGH_SPEED_RAIL.get());
  }    
}