package com.ericchiu.simplerail.blockentity;

import java.util.UUID;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.Tag;

/** NEW-world data only. There is intentionally no OLD save_time/go_time conversion. */
public final class HoldingTimerData {
    public static final String KEY = "holding_timer";
    private static final int VERSION = 1;

    private HoldingTimerData() {}

    public record Snapshot(UUID cart, long remainingMillis) {}

    public static CompoundTag encode(UUID cart, long remainingMillis) {
        CompoundTag data = new CompoundTag();
        data.putInt("version", VERSION);
        if (cart != null && remainingMillis >= 0 && remainingMillis <= HoldingTimer.MAX_MILLIS) {
            data.putUUID("cart_uuid", cart);
            data.putLong("remaining_ms", remainingMillis);
        }
        return data;
    }

    public static Snapshot decode(CompoundTag data) {
        if (!data.contains("version", Tag.TAG_INT) || data.getInt("version") != VERSION
                || !data.hasUUID("cart_uuid") || !data.contains("remaining_ms", Tag.TAG_LONG)) {
            return new Snapshot(null, 0);
        }
        long remaining = data.getLong("remaining_ms");
        if (remaining < 0 || remaining > HoldingTimer.MAX_MILLIS) {
            return new Snapshot(null, 0);
        }
        return new Snapshot(data.getUUID("cart_uuid"), remaining);
    }
}
