package evidence.t008;

import java.util.function.Supplier;
import net.minecraft.core.registries.Registries;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.CreativeModeTab;
import net.minecraft.world.item.CreativeModeTabs;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.ModContainer;
import net.neoforged.fml.common.Mod;
import net.neoforged.fml.config.ModConfig;
import net.neoforged.fml.event.config.ModConfigEvent;
import net.neoforged.fml.event.lifecycle.FMLCommonSetupEvent;
import net.neoforged.neoforge.common.ModConfigSpec;
import net.neoforged.neoforge.common.NeoForge;
import net.neoforged.neoforge.event.BuildCreativeModeTabContentsEvent;
import net.neoforged.neoforge.event.server.ServerStartingEvent;
import net.neoforged.neoforge.registries.DeferredBlock;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredItem;
import net.neoforged.neoforge.registries.DeferredRegister;
import net.neoforged.neoforge.registries.RegisterEvent;

/** Compile only. Never packaged, loaded, instantiated, or used as migrated mod code. */
@Mod(T008Probe.ID)
public final class T008Probe {
    public static final String ID = "t008_probe";
    static final DeferredRegister.Blocks BLOCKS = DeferredRegister.createBlocks(ID);
    static final DeferredRegister.Items ITEMS = DeferredRegister.createItems(ID);
    static final DeferredRegister<CreativeModeTab> TABS = DeferredRegister.create(Registries.CREATIVE_MODE_TAB, ID);
    static final DeferredRegister<BlockEntityType<?>> BLOCK_ENTITIES = DeferredRegister.create(Registries.BLOCK_ENTITY_TYPE, ID);
    static final DeferredRegister<EntityType<?>> ENTITIES = DeferredRegister.create(Registries.ENTITY_TYPE, ID);
    static final DeferredBlock<Block> SAMPLE = BLOCKS.registerSimpleBlock("high_speed_rail", BlockBehaviour.Properties.of());
    static final DeferredItem<BlockItem> SAMPLE_ITEM = ITEMS.registerSimpleBlockItem("high_speed_rail", SAMPLE);
    static final DeferredItem<Item> TOOL = ITEMS.registerSimpleItem("wrench", new Item.Properties().stacksTo(1));
    static final DeferredHolder<CreativeModeTab, CreativeModeTab> TAB = TABS.register("probe_tab", () -> CreativeModeTab.builder()
            .title(Component.translatable("itemGroup.simplerail"))
            .icon(() -> SAMPLE_ITEM.get().getDefaultInstance())
            .displayItems((parameters, output) -> { output.accept(SAMPLE_ITEM.get()); output.accept(TOOL.get()); })
            .build());

    private static final ModConfigSpec.Builder BUILDER = new ModConfigSpec.Builder();
    static final ModConfigSpec.BooleanValue LOADING = BUILDER.define("cart.locomotive.disableLoadingChunk", true);
    static final ModConfigSpec.DoubleValue SPEED = BUILDER.defineInRange("rail.high_speed_rail.maxSpeed", 0.8D, 0.4D, 2.0D);
    static final ModConfigSpec.IntValue SECONDS = BUILDER.defineInRange("rail.timer_holding_rail.lv1", 5, 0, Integer.MAX_VALUE);
    static final ModConfigSpec SPEC = BUILDER.build();
    record Snapshot(boolean loading, double speed, int seconds) {}
    private static volatile Snapshot snapshot;

    // A single public constructor; injection types verified against FML 4.0.44 source.
    public T008Probe(IEventBus modBus, ModContainer container, Dist dist) {
        BLOCKS.register(modBus);
        ITEMS.register(modBus);
        BLOCK_ENTITIES.register(modBus);
        ENTITIES.register(modBus);
        TABS.register(modBus);
        modBus.addListener(this::commonSetup);
        modBus.addListener(this::rawRegister);
        modBus.addListener(this::creativeContents);
        modBus.addListener(this::loading);
        modBus.addListener(this::reloading);
        container.registerConfig(ModConfig.Type.COMMON, SPEC);
        NeoForge.EVENT_BUS.addListener(this::serverStarting);
    }

    private void commonSetup(FMLCommonSetupEvent event) {
        event.enqueueWork(() -> { ResourceLocation key = SAMPLE.getId(); });
    }
    private void rawRegister(RegisterEvent event) {
        event.register(Registries.ITEM, ResourceLocation.fromNamespaceAndPath(ID, "probe_direct"), () -> new Item(new Item.Properties()));
        event.register(Registries.ITEM, helper -> helper.register(ResourceLocation.fromNamespaceAndPath(ID, "probe_helper"), new Item(new Item.Properties())));
    }
    static DeferredHolder<BlockEntityType<?>, BlockEntityType<?>> deferType(String name, Supplier<BlockEntityType<?>> factory) {
        return BLOCK_ENTITIES.register(name, factory);
    }
    private void creativeContents(BuildCreativeModeTabContentsEvent event) {
        if (event.getTabKey().equals(CreativeModeTabs.TOOLS_AND_UTILITIES)) event.accept(TOOL);
    }
    private void loading(ModConfigEvent.Loading event) { refresh(event); }
    private void reloading(ModConfigEvent.Reloading event) { refresh(event); }
    private static void refresh(ModConfigEvent event) {
        if (event.getConfig().getSpec() != SPEC || !event.getConfig().getModId().equals(ID)) return;
        // No world mutation. Merely a compile candidate; reload policy awaits T-020.
        snapshot = new Snapshot(LOADING.getAsBoolean(), SPEED.getAsDouble(), SECONDS.getAsInt());
    }
    private void serverStarting(ServerStartingEvent event) {}
}
