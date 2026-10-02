package com.ericchiu.simplerail.blockentity;

import java.util.UUID;
import java.util.concurrent.atomic.AtomicLong;
import net.minecraft.nbt.CompoundTag;

/** Actual production timer/data with real NEW NBT in a plain JVM; no game bootstrap. */
public final class HoldingTimerTest {
    private static int checks;
    private static final UUID A = UUID.fromString("00000000-0000-0000-0000-000000000038");
    private static final UUID B = UUID.fromString("00000000-0000-0000-0000-000000000039");
    private static void check(boolean ok, String message) {
        checks++;
        if (!ok) throw new AssertionError(message);
    }
    private static void idle(CompoundTag data, String name) {
        var snapshot = HoldingTimerData.decode(data);
        check(snapshot.cart() == null && snapshot.remainingMillis() == 0, name);
    }
    public static void main(String[] args) {
        AtomicLong clock = new AtomicLong(1_000_000L);
        HoldingTimer timer = new HoldingTimer(clock::get);
        check(timer.cartUuid() == null && timer.remainingMillis() == 0, "unused idle");
        for (int seconds : new int[]{0, 1, 5, 10, 15, 20, 25, 30, 40, 50, 60, 2147483, 2147484, Integer.MAX_VALUE}) {
            check(HoldingTimer.secondsToMillis(seconds) == (long) seconds * 1000L, "long boundary " + seconds);
        }
        try { HoldingTimer.secondsToMillis(-1); throw new AssertionError("negative accepted"); }
        catch (IllegalArgumentException expected) { checks++; }
        timer.start(A, 10);
        clock.addAndGet(7_000_000_000L); // no tick counting
        check(timer.remainingMillis() == 3000, "seven real seconds without ticks");
        var saved = HoldingTimerData.decode(HoldingTimerData.encode(timer.cartUuid(), timer.remainingMillis()));
        check(saved.remainingMillis() == 3000 && A.equals(saved.cart()), "three-second snapshot");
        clock.addAndGet(1_000_000_000L);
        check(timer.remainingMillis() == 2000, "serialization did not restart or pause");
        timer.pause();
        saved = HoldingTimerData.decode(HoldingTimerData.encode(timer.cartUuid(), timer.remainingMillis()));
        clock.addAndGet(3_600_000_000_000L);
        check(timer.remainingMillis() == 2000, "unload frozen despite one-hour gap");
        HoldingTimer loaded = new HoldingTimer(clock::get);
        loaded.restore(saved.cart(), saved.remainingMillis());
        clock.addAndGet(20_000_000_000L);
        check(loaded.remainingMillis() == 2000, "deserialization before first activity paused");
        loaded.resume(); clock.addAndGet(1_999_000_000L);
        check(loaded.remainingMillis() == 1, "one millisecond before release");
        clock.addAndGet(1_000_000L);
        check(loaded.remainingMillis() == 0 && A.equals(loaded.cartUuid()), "expired UUID retained");
        var expired = HoldingTimerData.decode(HoldingTimerData.encode(loaded.cartUuid(), 0));
        check(A.equals(expired.cart()) && expired.remainingMillis() == 0, "expired UUID survives reload");
        loaded.restore(expired.cart(), expired.remainingMillis()); loaded.resume();
        check(A.equals(loaded.cartUuid()) && loaded.remainingMillis() == 0, "same expired cart does not wait again");
        loaded.start(B, 5);
        check(B.equals(loaded.cartUuid()) && loaded.remainingMillis() == 5000, "different cart gets new wait");
        loaded.start(A, 0);
        check(A.equals(loaded.cartUuid()) && loaded.remainingMillis() == 0, "zero-second configured wait");
        loaded.start(A, Integer.MAX_VALUE); clock.addAndGet(1_000_000_000L);
        check(loaded.remainingMillis() == HoldingTimer.MAX_MILLIS - 1000, "max duration positive after second");
        loaded.start(A, 3); long baseline = clock.get();
        for (int i=1; i<=1000; i++) {
            clock.set(baseline + i*500_000L);
            check(loaded.remainingMillis() == 3000-i/2, "fractional milliseconds " + i);
        }
        for (int i=0; i<3; i++) {
            long value = loaded.remainingMillis();
            var record = HoldingTimerData.decode(HoldingTimerData.encode(loaded.cartUuid(), value));
            clock.addAndGet(60_000_000_000L); loaded.restore(record.cart(), record.remainingMillis());
            check(loaded.remainingMillis() == value, "reload pause " + i);
            loaded.resume();
        }
        for (long value : new long[]{0, 1, 2999, 3000, 10000, HoldingTimer.MAX_MILLIS}) {
            var record = HoldingTimerData.decode(HoldingTimerData.encode(A,value));
            check(A.equals(record.cart()) && record.remainingMillis()==value,"NEW roundtrip "+value);
        }
        idle(new CompoundTag(), "missing all keys");
        idle(HoldingTimerData.encode(null,0), "unused versioned data");
        CompoundTag data = HoldingTimerData.encode(A,3000); data.remove("cart_uuid"); idle(data,"missing UUID");
        data = HoldingTimerData.encode(A,3000); data.remove("remaining_ms"); idle(data,"missing remaining");
        data = HoldingTimerData.encode(A,3000); data.remove("version"); idle(data,"missing version");
        data = HoldingTimerData.encode(A,3000); data.putString("version","1"); idle(data,"wrong version type");
        data = HoldingTimerData.encode(A,3000); data.putInt("version",2); idle(data,"unknown version");
        data = HoldingTimerData.encode(A,3000); data.putString("cart_uuid","bad"); idle(data,"wrong UUID type");
        data = HoldingTimerData.encode(A,3000); data.putIntArray("cart_uuid",new int[]{1,2,3}); idle(data,"wrong UUID length");
        data = HoldingTimerData.encode(A,3000); data.putInt("remaining_ms",3000); idle(data,"int instead of long");
        data = HoldingTimerData.encode(A,3000); data.putString("remaining_ms","3000"); idle(data,"string time");
        for (long value : new long[]{-1, HoldingTimer.MAX_MILLIS+1, Long.MAX_VALUE}) {
            data = HoldingTimerData.encode(A,3000); data.putLong("remaining_ms",value); idle(data,"invalid range "+value);
        }
        data = new CompoundTag(); data.putUUID("cart_uuid",A); data.putLong("save_time",1); data.putLong("go_time",10000);
        idle(data,"no OLD conversion");
        loaded.restore(A,-1); check(loaded.cartUuid()==null && loaded.remainingMillis()==0,"invalid restore");
        // A fresh three-second snapshot and first activity after offline time are independently checked.
        timer.start(A,10);clock.addAndGet(7_000_000_000L);timer.pause();
        data=HoldingTimerData.encode(timer.cartUuid(),timer.remainingMillis());clock.addAndGet(90_000_000_000L);
        var record=HoldingTimerData.decode(data);loaded.restore(record.cart(),record.remainingMillis());loaded.resume();
        clock.addAndGet(2_999_000_000L);check(loaded.remainingMillis()==1,"three-second readback before expiry");
        clock.addAndGet(1_000_000L);check(loaded.remainingMillis()==0,"three-second readback expiry");
        System.out.println("PASS production timer + real NEW NBT checks="+checks+"; gameExecuted=false; oldBuildExecuted=false");
    }
}
