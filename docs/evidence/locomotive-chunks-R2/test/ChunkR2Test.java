package com.ericchiu.simplerail.entity;

import com.ericchiu.simplerail.config.CommonConfig;
import java.util.*;
import java.io.*;
import net.minecraft.core.BlockPos;
import net.minecraft.nbt.*;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.level.ChunkPos;
import net.minecraft.world.level.Level;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.common.NeoForge;
import net.neoforged.neoforge.common.world.chunk.*;
import net.neoforged.neoforge.event.entity.*;
import net.neoforged.neoforge.event.tick.LevelTickEvent;
import net.neoforged.neoforge.event.tick.EntityTickEvent;
import net.neoforged.neoforge.event.level.LevelEvent;

/** Actual coverage, loader and SavedData, real 1.21.1 NBT; world/ticket/event APIs are doubles. */
public final class ChunkR2Test {
    private static int checks;
    private static TicketController controller;
    private static void ok(boolean condition,String why){checks++;if(!condition)throw new AssertionError(why);}
    private static void join(Entity e){NeoForge.EVENT_BUS.fire(0,new EntityJoinLevelEvent(e,e.level()));}
    private static void leave(Entity e){NeoForge.EVENT_BUS.fire(1,new EntityLeaveLevelEvent(e,e.level()));}
    private static void tick(Level level){NeoForge.EVENT_BUS.fire(2,new LevelTickEvent.Pre(level));}
    private static void unload(Level level){NeoForge.EVENT_BUS.fire(3,new LevelEvent.Unload(level));}
    private static boolean blocked(Entity e){var event=new EntityTickEvent.Pre(e);NeoForge.EVENT_BUS.fire(4,event);return event.canceled;}
    private static LocomotiveCartEntity head(ServerLevel level,int x,int z){
        var h=new LocomotiveCartEntity(level);h.pos=new BlockPos(x,64,z);level.entities.put(h.id,h);return h;
    }
    private static Set<Long> owned(ServerLevel level,UUID id){
        Set<Long> result=new HashSet<>();
        for(var k:TicketController.tickets)if(k.level()==level&&k.owner().equals(id)&&k.controller().equals("simplerail:locomotive"))result.add(k.chunk());
        return result;
    }
    private static void boundsAndDiff(){
        for(int x:new int[]{-33,-32,-17,-16,-1,0,15,16,31,32})for(int z:new int[]{-17,-1,0,16}){
            Set<Long> s=new HashSet<>();ChunkTicketSet.includeBuffer(s,x,z);ok(s.size()==9,"3x3 unique");
            for(int dx=-1;dx<=1;dx++)for(int dz=-1;dz<=1;dz++)
                ok(s.contains(ChunkPos.asLong(Math.floorDiv(x,16)+dx,Math.floorDiv(z,16)+dz)),"negative/axis buffer");
        }
        var lease=new ChunkTicketSet();List<String> ops=new ArrayList<>();
        ok(lease.update(Set.of(1L,2L),true,c->ops.add("+"+c),c->true,c->ops.add("-"+c)),"first diff");
        ops.clear();ok(!lease.update(Set.of(2L,3L),true,c->ops.add("+"+c),c->c!=3,c->ops.add("-"+c)),"unready gate");
        ok(ops.equals(List.of("+3"))&&lease.applied().equals(Set.of(1L,2L,3L)),"add first, keep old while unready");
        ops.clear();ok(!lease.update(Set.of(2L,3L),false,c->ops.add("+"+c),c->true,c->ops.add("-"+c)),"missing position gate");
        ok(ops.isEmpty(),"no repeated add or premature release");
        ok(lease.update(Set.of(2L,3L),true,c->ops.add("+"+c),c->true,c->ops.add("-"+c)),"ready now");
        ok(ops.equals(List.of("-1")),"release exact obsolete difference");
        var failed=new ChunkTicketSet();
        try{failed.update(Set.of(8L),true,c->{throw new IllegalStateException("fake add error");},c->true,c->{});throw new AssertionError("throw expected");}
        catch(IllegalStateException expected){ok(failed.applied().isEmpty(),"failed add never marked owned");}
    }
    private static void lifecycle(){
        var level=new ServerLevel();var h=head(level,-1,-17);join(h);
        ok(owned(level,h.id).isEmpty(),"Join never loads chunks");tick(level);
        ok(owned(level,h.id).size()==9,"bootstrap parked head");
        TicketController.calls.clear();tick(level);LocomotiveChunkLoader.prepare(h);
        ok(TicketController.calls.isEmpty(),"unchanged tick does not reissue tickets");
        var tail=new AbstractMinecart(level);tail.pos=new BlockPos(-321,64,-17);level.entities.put(tail.id,tail);h.cars.add(tail.id);
        ok(LocomotiveChunkLoader.prepare(h),"long train ready");
        ok(owned(level,h.id).contains(ChunkPos.asLong(-21,-2)),"tail beyond head 5x5 is covered");
        for(int i=0;i<2000;i++){
            h.pos=new BlockPos(i*16,64,32);tail.pos=new BlockPos(i*16-320,64,32);
            h.targets.put(h.id,h.pos.offset(2,0,0));h.targets.put(tail.id,tail.pos.offset(2,0,0));
            ok(LocomotiveChunkLoader.prepare(h),"long route ready");
            ok(owned(level,h.id).size()==18,"count bounded by train, not distance");
            ok(LocomotiveChunkData.forLevel(level).get(h.id).chunks().equals(owned(level,h.id)),"saved current set matches lease");
        }
        h.cars.clear();h.targets.remove(tail.id);LocomotiveChunkLoader.prepare(h);
        ok(owned(level,h.id).size()==9,"disconnect drops tail coverage");
        var peer=head(level,h.pos.getX(),h.pos.getZ());join(peer);tick(level);
        ok(owned(level,peer.id).size()==9,"shared chunk, independent owner");
        h.reason=Entity.RemovalReason.KILLED;h.removed=true;leave(h);
        ok(owned(level,h.id).isEmpty()&&LocomotiveChunkData.forLevel(level).get(h.id)==null,"destroy releases and unregisters");
        ok(owned(level,peer.id).size()==9,"destroy cannot unforce other owner");
        CommonConfig.enabled=false;tick(level);
        ok(owned(level,peer.id).isEmpty()&&LocomotiveChunkData.forLevel(level).entries().isEmpty(),"disable clears all index and leases");
        CommonConfig.enabled=true;tick(level);ok(owned(level,peer.id).size()==9,"re-enable loaded heads");
        peer.reason=Entity.RemovalReason.CHANGED_DIMENSION;peer.removed=true;leave(peer);
        ok(owned(level,peer.id).isEmpty(),"dimension exit releases old world");unload(level);

        var client=new Level();var clientHead=new LocomotiveCartEntity(client);join(clientHead);tick(client);unload(client);
        ok(LocomotiveChunkLoader.prepare(clientHead),"client keeps normal movement without world tickets");
        var canceled=head(level,0,0);canceled.added=false;level.entities.remove(canceled.id);join(canceled);tick(level);
        ok(owned(level,canceled.id).isEmpty(),"canceled join not registered");
        var normal=new AbstractMinecart(level);join(normal);tick(level);
        ok(owned(level,normal.id).isEmpty(),"ordinary car is not an owner");unload(level);
    }
    private static void waitingAndStorage() throws Exception {
        var level=new ServerLevel();var h=head(level,0,0);join(h);tick(level);
        var tail=new AbstractMinecart(level);tail.pos=new BlockPos(512,64,0);level.entities.put(tail.id,tail);h.cars.add(tail.id);
        LocomotiveChunkLoader.prepare(h);long observed=tail.pos.asLong();
        level.entities.remove(tail.id);h.hints.put(tail.id,new BlockPos(32,64,0));
        ok(!LocomotiveChunkLoader.prepare(h),"unloaded linked car blocks motion");
        ok(blocked(tail),"linked car cannot drift under powered rail while head waits");
        ok(!blocked(h),"head tick must still consume pending ownership cuts");
        ok(!blocked(new AbstractMinecart(level)),"unrelated carts still tick");
        ok(owned(level,h.id).contains(ChunkPos.asLong(32,0)),"keep real last known tail position");
        ok(LocomotiveChunkData.forLevel(level).get(h.id).positions().get(tail.id)==observed,"stop hint cannot overwrite real position");
        level.entities.put(tail.id,tail);ok(LocomotiveChunkLoader.prepare(h),"late loaded carriage resumes");
        ok(!blocked(tail),"ready train resumes carriage physics");
        level.ticking=false;h.targets.put(h.id,new BlockPos(1024,64,0));var before=owned(level,h.id);
        ok(!LocomotiveChunkLoader.prepare(h),"target not ticking blocks motion");
        CommonConfig.enabled=false;ok(!blocked(tail),"disabled config bypasses wait gate");CommonConfig.enabled=true;
        ok(owned(level,h.id).containsAll(before),"old coverage retained until new ready");
        level.ticking=true;ok(LocomotiveChunkLoader.prepare(h),"target readiness resumes");

        LocomotiveChunkData data=LocomotiveChunkData.forLevel(level);
        CompoundTag saved=data.save(new CompoundTag(),null);
        ByteArrayOutputStream out=new ByteArrayOutputStream();NbtIo.write(saved,new DataOutputStream(out));
        CompoundTag read=NbtIo.read(new DataInputStream(new ByteArrayInputStream(out.toByteArray())));
        LocomotiveChunkData restored=LocomotiveChunkData.load(read,null);
        ok(restored.entries().equals(data.entries()),"real binary NBT round trip");
        try{restored.get(h.id).chunks().clear();throw new AssertionError("mutable");}catch(UnsupportedOperationException expected){checks++;}
        var bad=read.copy();bad.putInt("Schema",99);
        try{LocomotiveChunkData.load(bad,null);throw new AssertionError("schema accepted");}catch(IllegalArgumentException expected){checks++;}
        data.setDirty(false);var entry=data.get(h.id);data.put(h.id,entry.positions(),entry.chunks());
        ok(!data.isDirty(),"unchanged snapshot doesn't dirty storage");
        unload(level);

        var reboot=new ServerLevel();reboot.storage.data.put("simplerail_locomotive_chunks",restored);reboot.ioReady=false;
        tick(reboot);ok(owned(reboot,h.id).equals(entry.chunks()),"restore before entity IO without players");
        ok(!restored.get(h.id).chunks().isEmpty(),"getEntity null during IO is not deletion");
        var resumed=head(reboot,0,0);reboot.entities.remove(resumed.id);resumed.id=h.id;reboot.entities.put(resumed.id,resumed);
        var resumedTail=new AbstractMinecart(reboot);resumedTail.id=tail.id;resumedTail.pos=tail.pos;reboot.entities.put(tail.id,resumedTail);resumed.cars.add(tail.id);
        reboot.ioReady=true;tick(reboot);ok(!owned(reboot,h.id).isEmpty(),"loaded owner resumes after IO");
        CommonConfig.enabled=false;tick(reboot);ok(owned(reboot,h.id).isEmpty(),"disable restored owner");CommonConfig.enabled=true;unload(reboot);

        var orphan=new ServerLevel();orphan.storage.data.put("simplerail_locomotive_chunks",LocomotiveChunkData.load(read,null));
        orphan.ioReady=false;tick(orphan);ok(!owned(orphan,h.id).isEmpty(),"unresolved IO keeps bounded saved set");
        orphan.ioReady=true;tick(orphan);ok(owned(orphan,h.id).isEmpty(),"indexed area fully loaded but owner absent suspends tickets");
        ok(LocomotiveChunkData.forLevel(orphan).get(h.id)!=null,"suspended position hint retained, entity not deleted");unload(orphan);
    }
    private static void legacyCleanup(){
        var level=new ServerLevel();var old=UUID.randomUUID();var other=UUID.randomUUID();
        TicketController.tickets.add(new TicketController.Key(level,"simplerail:locomotive",old,99));
        TicketController.tickets.add(new TicketController.Key(level,"other:loader",other,99));
        var helper=new TicketHelper(level);helper.entities.put(old,Set.of(99L));helper.blocks.put(new BlockPos(1,2,3),Set.of(4L));
        controller.callback().validateTickets(level,helper);
        ok(owned(level,old).isEmpty()&&helper.blocks.isEmpty(),"R1 own raw entity/block tickets removed before restoration");
        ok(TicketController.tickets.contains(new TicketController.Key(level,"other:loader",other,99)),"other controller untouched");
        tick(level);ok(owned(level,old).isEmpty(),"no index means no invented R1 owner location");
        var h=head(level,0,0);join(h);tick(level);ok(owned(level,h.id).size()==9,"first manual load builds new index");
        unload(level);
    }
    public static void main(String[] args)throws Exception {
        var mod=new IEventBus();LocomotiveChunkLoader.register(mod);
        var event=new RegisterTicketControllersEvent();mod.fire(0,event);controller=event.controller;
        ok(controller.id().toString().equals("simplerail:locomotive"),"stable controller and callback");
        boundsAndDiff();lifecycle();waitingAndStorage();legacyCleanup();
        System.out.println("PASS "+checks+" assertions: real coverage/loader/SavedData and binary NBT; world/ticket/event APIs are doubles; NO Minecraft runtime");
    }
}
