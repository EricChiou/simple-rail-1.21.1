package com.ericchiu.simplerail.registry;

import com.ericchiu.simplerail.SimpleRail;
import com.ericchiu.simplerail.item.Wrench;
import com.ericchiu.simplerail.item.LocomotiveCartItem;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.Rarity;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredItem;
import net.neoforged.neoforge.registries.DeferredRegister;

/** Stable item IDs, including the custom locomotive's server-authoritative placement. */
public final class ModItems {
    private static final DeferredRegister.Items ITEMS = DeferredRegister.createItems(SimpleRail.MODID);

    public static final DeferredItem<Wrench> WRENCH = ITEMS.registerItem("wrench", Wrench::new,
            new Item.Properties().stacksTo(1).rarity(Rarity.COMMON).fireResistant());
    public static final DeferredItem<LocomotiveCartItem> LOCOMOTIVE_CART = ITEMS.registerItem("locomotive_cart",
            LocomotiveCartItem::new,
            new Item.Properties().stacksTo(64).rarity(Rarity.UNCOMMON).fireResistant());

    public static final DeferredItem<BlockItem> HIGH_SPEED_RAIL = ITEMS.registerSimpleBlockItem("high_speed_rail", ModBlocks.HIGH_SPEED_RAIL);
    public static final DeferredItem<BlockItem> HOLDING_RAIL = ITEMS.registerSimpleBlockItem("holding_rail", ModBlocks.HOLDING_RAIL);
    public static final DeferredItem<BlockItem> ONEWAY_RAIL = ITEMS.registerSimpleBlockItem("oneway_rail", ModBlocks.ONEWAY_RAIL);
    public static final DeferredItem<BlockItem> EJECT_RAIL = ITEMS.registerSimpleBlockItem("eject_rail", ModBlocks.EJECT_RAIL);
    public static final DeferredItem<BlockItem> DESTORY_RAIL = ITEMS.registerSimpleBlockItem("destory_rail", ModBlocks.DESTORY_RAIL);
    public static final DeferredItem<BlockItem> TIMER_HOLDING_RAIL = ITEMS.registerSimpleBlockItem("timer_holding_rail", ModBlocks.TIMER_HOLDING_RAIL);
    public static final DeferredItem<BlockItem> CROSS_RAIL = ITEMS.registerSimpleBlockItem("cross_rail", ModBlocks.CROSS_RAIL);
    public static final DeferredItem<BlockItem> Y_CROSS_RAIL = ITEMS.registerSimpleBlockItem("y_cross_rail", ModBlocks.Y_CROSS_RAIL);
    public static final DeferredItem<BlockItem> Y_CROSS_RIGHT_RAIL = ITEMS.registerSimpleBlockItem("y_cross_right_rail", ModBlocks.Y_CROSS_RIGHT_RAIL);
    public static final DeferredItem<BlockItem> TRAIN_DISPENSER = ITEMS.registerSimpleBlockItem("train_dispenser", ModBlocks.TRAIN_DISPENSER);
    public static final DeferredItem<BlockItem> SIGNAL_TIMER = ITEMS.registerSimpleBlockItem("signal_timer", ModBlocks.SIGNAL_TIMER);

    private ModItems() {}

    public static void register(IEventBus modEventBus) {
        ITEMS.register(modEventBus);
    }
}
