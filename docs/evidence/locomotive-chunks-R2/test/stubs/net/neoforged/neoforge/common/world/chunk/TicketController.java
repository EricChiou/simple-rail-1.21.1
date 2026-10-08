package net.neoforged.neoforge.common.world.chunk;
import java.util.*;import net.minecraft.resources.ResourceLocation;import net.minecraft.server.level.ServerLevel;
public record TicketController(ResourceLocation id, LoadingValidationCallback callback) {
 public record Key(ServerLevel level,String controller,UUID owner,long chunk){}
 public static final Set<Key> tickets=new HashSet<>();
 public static final List<String> calls=new ArrayList<>();
 public boolean forceChunk(ServerLevel level,UUID owner,int x,int z,boolean add,boolean ticking){
  if(!ticking)throw new AssertionError("not ticking");
  long packed=net.minecraft.world.level.ChunkPos.asLong(x,z);
  Key key=new Key(level,id.toString(),owner,packed); calls.add((add?"+":"-")+owner+":"+packed);
  return add?tickets.add(key):tickets.remove(key);
 }
}
