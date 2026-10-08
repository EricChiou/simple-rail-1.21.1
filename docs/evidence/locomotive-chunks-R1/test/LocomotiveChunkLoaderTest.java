package com.ericchiu.simplerail.entity;
import com.ericchiu.simplerail.config.CommonConfig;
import net.minecraft.core.BlockPos;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.level.Level;
import net.minecraft.world.entity.Entity;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.common.NeoForge;
import net.neoforged.neoforge.common.world.chunk.*;
import net.neoforged.neoforge.event.entity.*;
import net.neoforged.neoforge.event.tick.LevelTickEvent;
import net.neoforged.neoforge.event.level.LevelEvent;

public final class LocomotiveChunkLoaderTest {
 private static int checks;
 private static void ok(boolean value,String msg){checks++;if(!value)throw new AssertionError(msg);}
 private static LocomotiveCartEntity head(Level level,int x,int z){
  var e=new LocomotiveCartEntity(level);e.pos=new BlockPos(x,64,z);e.added=true;return e;
 }
 private static void join(Entity e){NeoForge.EVENT_BUS.fire(0,new EntityJoinLevelEvent(e,e.level()));}
 private static void cross(Entity e,boolean changed){NeoForge.EVENT_BUS.fire(1,new EntityEvent.EnteringSection(e,changed));}
 private static void tick(Level l){NeoForge.EVENT_BUS.fire(2,new LevelTickEvent.Post(l));}
 private static void unload(Level l){NeoForge.EVENT_BUS.fire(3,new LevelEvent.Unload(l));}
 private static void clear(){TicketController.calls.clear();}
 private static void batch(LocomotiveCartEntity e,int x,int z){
  ok(TicketController.calls.size()==25,"25 OLD center requests");
  for(var c:TicketController.calls){
   ok(c.level()==e.level(),"dimension isolation");ok(c.owner().equals(e.getUUID()),"entity UUID owner");
   ok(c.x()==x && c.z()==z,"center only, negative floor conversion");
   ok(c.add() && c.ticking(),"persistent add + ticking, never release");
  }
 }
 public static void main(String[] args){
  var modBus=new IEventBus(); LocomotiveChunkLoader.register(modBus);
  ok(modBus.listeners.size()==1,"controller mod event");
  ok(NeoForge.EVENT_BUS.listeners.size()==4,"join/cross/post/unload registered");
  var registration=new RegisterTicketControllersEvent();modBus.fire(0,registration);
  ok(registration.registered.id().toString().equals("simplerail:locomotive"),"stable controller ID");
  var a=new ServerLevel();var b=new ServerLevel();var client=new Level();
  var h=head(a,-1,-17);
  join(h);join(h);ok(TicketController.calls.isEmpty(),"join cannot synchronously load/deadlock");
  tick(a);batch(h,-1,-2);ok(TicketController.persisted.size()==1,"stub deduplicates repeated center");
  clear();tick(a);ok(TicketController.calls.isEmpty(),"bootstrap not repeated every tick");
  cross(h,false);ok(TicketController.calls.isEmpty(),"Y-only movement ignored");
  h.pos=new BlockPos(16,80,32);cross(h,true);batch(h,1,2);
  clear();cross(h,true);batch(h,1,2); // existing ticket returns false, not failure
  clear();CommonConfig.enabled=false;h.pos=new BlockPos(32,80,32);cross(h,true);join(h);tick(a);
  ok(TicketController.calls.isEmpty(),"disabled config suppresses adds");
  ok(TicketController.persisted.size()==2,"disabled never releases existing tickets");
  CommonConfig.enabled=true;cross(h,true);batch(h,2,2);
  clear();var local=head(client,0,0);join(local);cross(local,true);tick(client);
  var normal=new Entity(a);normal.added=true;join(normal);cross(normal,true);tick(a);
  ok(TicketController.calls.isEmpty(),"client and non-locomotive ignored");
  var canceled=head(a,0,0);canceled.added=false;join(canceled);tick(a);cross(canceled,true);
  var removed=head(a,0,0);join(removed);removed.removed=true;tick(a);cross(removed,true);
  ok(TicketController.calls.isEmpty(),"canceled/unadded and removed heads ignored");
  var moved=head(a,0,0);join(moved);moved.world=b;tick(a);
  ok(TicketController.calls.isEmpty(),"stale join in previous dimension ignored");
  join(moved);tick(b);batch(moved,0,0);
  clear();var pending=head(a,48,48);join(pending);unload(a);tick(a);
  ok(TicketController.calls.isEmpty(),"world unload clears bootstrap queue only");
  join(pending);tick(a);batch(pending,3,3); // same coordinates on a new join must work
  clear();var one=head(a,64,64);var two=head(b,64,64);
  join(one);join(two);tick(a);batch(one,4,4);clear();tick(b);batch(two,4,4);
  clear();var third=head(a,80,80);var nested=head(a,96,96);
  TicketController.onNewTicket=()->join(nested);join(third);tick(a);batch(third,5,5);
  clear();tick(a);batch(nested,6,6); // nested chunk load cannot lose queued new entities
  clear();join(nested);tick(a);batch(nested,6,6); // disk-load bootstrap, no player test doubles
  int stored=TicketController.persisted.size();unload(a);unload(b);
  ok(TicketController.persisted.size()==stored,"unload must not release persisted tickets");
  System.out.println("PASS "+checks+" assertions on actual LocomotiveChunkLoader with isolated API doubles; no Minecraft or real ticket persistence run");
 }
}
