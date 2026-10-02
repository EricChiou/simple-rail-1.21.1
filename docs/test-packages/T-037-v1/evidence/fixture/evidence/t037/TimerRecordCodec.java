package evidence.t037;

import java.util.UUID;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.Tag;

/** In-memory NEW probe records only. The eventual production schema remains T-038 work. */
public final class TimerRecordCodec {
    public record Record(UUID cart, long remaining, String status) {}
    private TimerRecordCodec() {}
    public static Record decode(CompoundTag data) {
        if (!data.contains("cart_uuid") && !data.contains("remaining_ms")) return new Record(null,0,"idle");
        if (!data.hasUUID("cart_uuid") || !data.contains("remaining_ms",Tag.TAG_LONG)) {
            return new Record(null,0,"invalid_keys_or_types");
        }
        long remaining = data.getLong("remaining_ms");
        if (remaining <= 0 || remaining > TimerState.MAX_MILLIS) return new Record(null,0,"invalid_range");
        return new Record(data.getUUID("cart_uuid"),remaining,"active");
    }
    public static CompoundTag encode(UUID cart, long remaining) {
        CompoundTag data = new CompoundTag();
        if (cart != null && remaining > 0 && remaining <= TimerState.MAX_MILLIS) {
            data.putUUID("cart_uuid",cart);
            data.putLong("remaining_ms",remaining);
        }
        return data;
    }
}
