package com.ericchiu.simplerail.config;

import com.ericchiu.simplerail.SimpleRail;
import java.util.ArrayList;
import java.util.List;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.ModContainer;
import net.neoforged.fml.config.ModConfig;
import net.neoforged.fml.event.config.ModConfigEvent;
import net.neoforged.neoforge.common.ModConfigSpec;

/** COMMON is local to each process, not synced. Gameplay consumers must use the logical server. */
public final class CommonConfig {
    public static final String FILE_NAME = "simplerail-common.toml";
    public static final int SIGNAL_TICKS_PER_SECOND = 20;
    public static final int SIGNAL_PULSE_TICKS = 10;

    private static final ModConfigSpec.Builder BUILDER = new ModConfigSpec.Builder();
    // Keep the historical name; true means enabled, despite "disable" in the key (D3).
    private static final ModConfigSpec.BooleanValue CHUNK_LOADING = BUILDER
            .comment("Keep locomotive chunk loading enabled when true (historical key name; default true).")
            .define("cart.locomotive.disableLoadingChunk", true);
    private static final ModConfigSpec.DoubleValue MAX_SPEED = BUILDER
            .comment("Shared rail speed limit; actual cart speed also depends on cart limits and movement.")
            .defineInRange("rail.high_speed_rail.maxSpeed", 0.8D, 0.4D, 2.0D);
    private static final ModConfigSpec.BooleanValue ONEWAY_NEED_POWER = BUILDER
            .comment("Whether oneway rails require power; also projected to need_power on placement.")
            .define("rail.oneway_rail.needPower", true);
    private static final ModConfigSpec.BooleanValue ONEWAY_USE_POWER = BUILDER
            .comment("Oneway power mode; also projected to use_power on placement. Reload does not rewrite blocks.")
            .define("rail.oneway_rail.usePowerChangeDirection", false);
    private static final ModConfigSpec.IntValue EJECT_DISTANCE = BUILDER
            .comment("Passenger transport distance for eject rails.")
            .defineInRange("rail.eject_rail.transportDistance", 3, 1, 100);
    private static final ModConfigSpec.BooleanValue EJECT_NEED_POWER = BUILDER
            .comment("Whether eject rails require power; also projected to need_power on placement.")
            .define("rail.eject_rail.needPower", true);
    private static final ModConfigSpec.BooleanValue DESTORY_NEED_POWER = BUILDER
            .comment("Whether destory rail requires power; keep the historical spelling.")
            .define("rail.destory_rail.needPower", false);
    private static final List<ModConfigSpec.IntValue> HOLDING_SECONDS = defineLevels("rail.timer_holding_rail",
            "Real elapsed seconds for a new holding wait; unloaded/offline time is paused (D5).");
    private static final List<ModConfigSpec.IntValue> SIGNAL_SECONDS = defineLevels("rail.signal_timer_block",
            "Signal interval in seconds, converted by the signal scheduler using 20 ticks per second.");

    public static final ModConfigSpec SPEC = BUILDER.build();
    // Never read ConfigValue.get() while constructing registries or initializing static fields.
    private static volatile Snapshot active;

    private CommonConfig() {}

    private static List<ModConfigSpec.IntValue> defineLevels(String group, String comment) {
        int[] defaults = {5, 10, 15, 20, 25, 30, 40, 50, 60};
        List<ModConfigSpec.IntValue> values = new ArrayList<>(defaults.length);
        for (int index = 0; index < defaults.length; index++) {
            values.add(BUILDER.comment(comment)
                    .defineInRange(group + ".lv" + (index + 1), defaults[index], 0, Integer.MAX_VALUE));
        }
        return List.copyOf(values);
    }

    public static void register(IEventBus modEventBus, ModContainer modContainer) {
        modEventBus.addListener(CommonConfig::onLoading);
        modEventBus.addListener(CommonConfig::onReloading);
        modEventBus.addListener(CommonConfig::onUnloading);
        modContainer.registerConfig(ModConfig.Type.COMMON, SPEC, FILE_NAME);
    }

    private static boolean owns(ModConfigEvent event) {
        return event.getConfig().getSpec() == SPEC
                && event.getConfig().getType() == ModConfig.Type.COMMON
                && event.getConfig().getModId().equals(SimpleRail.MODID);
    }

    private static void onLoading(ModConfigEvent.Loading event) {
        if (owns(event)) {
            publishLoadedValues();
        }
    }

    private static void onReloading(ModConfigEvent.Reloading event) {
        if (owns(event)) {
            publishLoadedValues();
        }
    }

    private static void onUnloading(ModConfigEvent.Unloading event) {
        if (owns(event)) {
            clearLoadedValues();
        }
    }

    /** Get one immutable snapshot per operation. Calling before Loading/after Unloading is an error. */
    public static Snapshot current() {
        Snapshot snapshot = active;
        if (snapshot == null) {
            throw new IllegalStateException("Simple Rail COMMON config has not been loaded.");
        }
        return snapshot;
    }

    // Package access lets non-game tests exercise the same publication path as the lifecycle handlers.
    static void publishLoadedValues() {
        if (!SPEC.isLoaded()) {
            throw new IllegalStateException("Cannot publish Simple Rail config before the spec is loaded.");
        }
        active = new Snapshot(CHUNK_LOADING.getAsBoolean(), MAX_SPEED.getAsDouble(),
                ONEWAY_NEED_POWER.getAsBoolean(), ONEWAY_USE_POWER.getAsBoolean(),
                EJECT_DISTANCE.getAsInt(), EJECT_NEED_POWER.getAsBoolean(), DESTORY_NEED_POWER.getAsBoolean(),
                readSeconds(HOLDING_SECONDS), readSeconds(SIGNAL_SECONDS));
    }

    static void clearLoadedValues() {
        active = null;
    }

    private static List<Integer> readSeconds(List<ModConfigSpec.IntValue> values) {
        return values.stream().map(ModConfigSpec.IntValue::getAsInt).toList();
    }

    public record Snapshot(boolean locomotiveChunkLoadingEnabled, double railMaxSpeed,
            boolean onewayNeedPower, boolean onewayUsePowerChangeDirection,
            int ejectTransportDistance, boolean ejectNeedPower, boolean destoryNeedPower,
            List<Integer> holdingWaitSecondsByLevel, List<Integer> signalIntervalSecondsByLevel) {
        public Snapshot {
            holdingWaitSecondsByLevel = List.copyOf(holdingWaitSecondsByLevel);
            signalIntervalSecondsByLevel = List.copyOf(signalIntervalSecondsByLevel);
            if (holdingWaitSecondsByLevel.size() != 9 || signalIntervalSecondsByLevel.size() != 9) {
                throw new IllegalArgumentException("Timer settings require levels 1 through 9.");
            }
        }

        public int holdingWaitSeconds(int level) {
            return holdingWaitSecondsByLevel.get(levelIndex(level));
        }

        public int signalIntervalSeconds(int level) {
            return signalIntervalSecondsByLevel.get(levelIndex(level));
        }

        private static int levelIndex(int level) {
            if (level < 1 || level > 9) {
                throw new IllegalArgumentException("Config timer level must be 1 through 9; level 0 is handled by the feature.");
            }
            return level - 1;
        }
    }
}
