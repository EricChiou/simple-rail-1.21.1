package net.neoforged.neoforge.common.world.chunk;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.entity.Entity;
import java.util.*;
public record TicketController(ResourceLocation id) {
 public record Call(ServerLevel level,UUID owner,int x,int z,boolean add,boolean ticking){}
 public static final List<Call> calls=new ArrayList<>();
 public static final Set<Call> persisted=new HashSet<>();
 public static Runnable onNewTicket;
 public boolean forceChunk(ServerLevel level,Entity owner,int x,int z,boolean add,boolean ticking){
  var c=new Call(level,owner.getUUID(),x,z,add,ticking); calls.add(c);
  boolean changed=persisted.add(c);
  if(changed && onNewTicket!=null){var action=onNewTicket;onNewTicket=null;action.run();}
  return changed;
 }
}
