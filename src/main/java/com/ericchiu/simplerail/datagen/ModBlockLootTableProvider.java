package com.ericchiu.simplerail.datagen;

import com.ericchiu.simplerail.registry.ModBlocks;
import net.minecraft.core.HolderLookup;
import net.minecraft.data.loot.BlockLootSubProvider;
import net.minecraft.world.flag.FeatureFlags;
import net.minecraft.world.level.block.Block;

import java.util.Set;

public class ModBlockLootTableProvider extends BlockLootSubProvider {
  public ModBlockLootTableProvider(HolderLookup.Provider provider) {
    super(Set.of(), FeatureFlags.REGISTRY.allFlags(), provider);
  }

  @Override
  protected void generate() {
    // Drop itself
    dropSelf(ModBlocks.HIGH_SPEED_RAIL.get());
  }

  @Override
  protected Iterable<Block> getKnownBlocks() {
    // Only generate loot tables for our mod's blocks
    return ModBlocks.BLOCKS.getEntries()
      .stream()
      .map(dev -> (Block) dev.get())
      ::iterator;
  }
}