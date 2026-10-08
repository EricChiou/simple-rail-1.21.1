package net.minecraft.server.level;
import java.util.*;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.level.saveddata.SavedData;
import net.minecraft.core.BlockPos;
import net.minecraft.resources.ResourceLocation;
public class ServerLevel extends net.minecraft.world.level.Level {
 public final Map<UUID,Entity> entities=new HashMap<>();
 public final Storage storage=new Storage();
 public boolean ioReady=true, ticking=true;
 public Entity getEntity(UUID id){return entities.get(id);}
 public boolean areEntitiesLoaded(long chunk){return ioReady;}
 public boolean isPositionEntityTicking(BlockPos pos){return ticking;}
 public Storage getDataStorage(){return storage;}
 public Dimension dimension(){return new Dimension();}
 public record Dimension(){public ResourceLocation location(){return ResourceLocation.parse("test:dimension");}}
 public static final class Storage {
  public final Map<String,SavedData> data=new HashMap<>();
  @SuppressWarnings("unchecked") public <T extends SavedData>T computeIfAbsent(SavedData.Factory<T> factory,String key){
   return (T)data.computeIfAbsent(key,k->factory.constructor().get());
  }
 }
}
