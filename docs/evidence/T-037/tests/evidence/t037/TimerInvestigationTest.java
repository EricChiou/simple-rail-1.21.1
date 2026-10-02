package evidence.t037;

import java.util.UUID;
import java.util.concurrent.atomic.AtomicLong;
import net.minecraft.nbt.CompoundTag;

/** Plain JVM investigation using actual NEW CompoundTag; no Minecraft bootstrap/server/world. */
public final class TimerInvestigationTest {
    private static int checks;
    private static final UUID CART = UUID.fromString("00000000-0000-0000-0000-000000000037");
    private static void check(boolean ok,String label) { checks++; if (!ok) throw new AssertionError(label); }
    private static void invalid(CompoundTag tag,String name) {
        TimerRecordCodec.Record record=TimerRecordCodec.decode(tag);
        check(record.cart()==null && record.remaining()==0,"Idle fallback: "+name);
    }
    public static void main(String[] args) {
        int[] seconds={0,1,5,10,15,20,25,30,40,50,60,2147483,2147484,Integer.MAX_VALUE};
        for(int s:seconds) {
            long mathematical=(long)s*1000L;
            check(TimerState.secondsToMillis(s)==mathematical,"long conversion "+s);
            System.out.println("ARITHMETIC seconds="+s+" old_int="+(s*1000)+" candidate_long="+mathematical);
        }
        check(2147483*1000==2147483000,"last nonoverflow integer second");
        check(2147484*1000==-2147483296,"first overflowing integer second");
        check(Integer.MAX_VALUE*1000==-1000,"allowed maximum becomes minus one second");
        try { TimerState.secondsToMillis(-1); throw new AssertionError("negative accepted"); }
        catch (IllegalArgumentException expected) { checks++; }

        CompoundTag empty=new CompoundTag();
        try { empty.getUUID("cart_uuid"); throw new AssertionError("NEW unguarded absent UUID unexpectedly accepted"); }
        catch (RuntimeException expected) { checks++; System.out.println("NEW_UNGUARDED_UUID="+expected.getClass().getName()); }
        check(empty.getLong("go_time")==0 && empty.getLong("save_time")==0,"NEW absent long defaults zero");
        invalid(empty,"empty unused timer");
        CompoundTag tag=new CompoundTag();tag.putUUID("cart_uuid",CART);invalid(tag,"UUID only");
        tag=new CompoundTag();tag.putLong("remaining_ms",3000);invalid(tag,"remaining only");
        tag.putString("cart_uuid",CART.toString());invalid(tag,"UUID wrong tag type");
        tag.putIntArray("cart_uuid",new int[]{1,2,3});invalid(tag,"UUID wrong length");
        tag.putUUID("cart_uuid",CART);tag.putInt("remaining_ms",3000);invalid(tag,"int instead of long");
        tag.putString("remaining_ms","3000");invalid(tag,"string instead of long");
        for(long bad:new long[]{-1,0,TimerState.MAX_MILLIS+1,Long.MAX_VALUE}) {
            tag.putLong("remaining_ms",bad);invalid(tag,"out of range "+bad);
        }
        for(long value:new long[]{1,2999,3000,10000,TimerState.MAX_MILLIS}) {
            var record=TimerRecordCodec.decode(TimerRecordCodec.encode(CART,value));
            check(CART.equals(record.cart()) && record.remaining()==value,"actual NEW NBT round trip "+value);
        }
        invalid(TimerRecordCodec.encode(null,3000),"null UUID encode");
        invalid(TimerRecordCodec.encode(CART,0),"expired encode");

        AtomicLong clock=new AtomicLong(1_000_000L);
        TimerState timer=new TimerState(clock::get);
        check(timer.remaining()==0,"unused idle");
        timer.start(CART,10000);
        clock.addAndGet(7_000_000_000L);
        check(timer.remaining()==3000,"seven REAL seconds elapsed without seven seconds of ticks");
        var snapshot=TimerRecordCodec.decode(TimerRecordCodec.encode(timer.cart(),timer.remaining()));
        clock.addAndGet(3_600_000_000_000L); // Unloaded/offline for one hour.
        TimerState loaded=new TimerState(clock::get);loaded.restore(snapshot.cart(),snapshot.remaining());
        clock.addAndGet(20_000_000_000L); // Deserialized but not yet ticking.
        check(loaded.remaining()==3000 && loaded.paused(),"load waits for resume; no offline/load-gap deduction");
        loaded.resume();clock.addAndGet(2_999_000_000L);check(loaded.remaining()==1,"still one millisecond to go");
        clock.addAndGet(1_000_000L);check(loaded.remaining()==0 && loaded.cart()==null,"expires at three seconds after resume");
        timer.start(CART,3000);long atStart=clock.get();
        for(int i=1;i<=1000;i++){clock.set(atStart+i*500_000L);check(timer.remaining()==3000-i/2,"fractional millisecond time not lost per tick "+i);}
        for(int reload=0;reload<2;reload++) {
            long remaining=timer.remaining();var record=TimerRecordCodec.decode(TimerRecordCodec.encode(timer.cart(),remaining));
            clock.addAndGet(60_000_000_000L);timer.restore(record.cart(),record.remaining());
            check(timer.remaining()==remaining,"repeated restore pauses "+reload);timer.resume();
        }
        timer.start(CART,TimerState.MAX_MILLIS);clock.addAndGet(1_000_000_000L);
        check(timer.remaining()==TimerState.MAX_MILLIS-1000,"maximum duration remains representable");

        long deadline=110000,saveTime=104000,unloadTime=107000,loadTime=120000;
        long restoredDeadline=deadline+(loadTime-saveTime);
        check(restoredDeadline-loadTime==6000,"OLD formula restores remainder at SAVE, not unload");
        check(deadline-unloadTime==3000,"actual remaining at later unload is three seconds");
        check((restoredDeadline-loadTime)-(deadline-unloadTime)==unloadTime-saveTime,"extra wait equals unsaved active gap");
        System.out.println("SAVE_GAP old_formula_remaining=6000 unload_remaining=3000 unsaved_gap=3000");
        System.out.println("PASS checks="+checks+"; actualNewNbt=true; oldRuntimeExecuted=false; minecraftBootstrap=false; gameExecuted=false");
    }
}
