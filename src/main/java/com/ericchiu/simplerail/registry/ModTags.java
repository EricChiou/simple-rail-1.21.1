package com.ericchiu.simplerail.registry;

import com.ericchiu.simplerail.SimpleRail;
import net.minecraft.core.registries.Registries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.tags.TagKey;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.Block;

/** Typed tag identities; membership is supplied by the data pack at reload. */
public final class ModTags {
    public static final TagKey<Block> RAILS = TagKey.create(
            Registries.BLOCK, ResourceLocation.fromNamespaceAndPath(SimpleRail.MODID, "rails"));
    public static final TagKey<Block> MACHINES = TagKey.create(
            Registries.BLOCK, ResourceLocation.fromNamespaceAndPath(SimpleRail.MODID, "machines"));
    // OLD declared this unused identity as a block tag, but its resource is an item tag.
    public static final TagKey<Item> WRENCH = TagKey.create(
            Registries.ITEM, ResourceLocation.fromNamespaceAndPath(SimpleRail.MODID, "wrench"));

    private ModTags() {}
}
