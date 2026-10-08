package net.minecraft.world.entity;
import java.util.UUID;import net.minecraft.core.BlockPos;import net.minecraft.world.level.Level;
public class Entity {
 public Level world;public boolean removed,added=true;public UUID id=UUID.randomUUID();
 public BlockPos pos=new BlockPos(0,64,0);public RemovalReason reason;
 public Entity(Level world){this.world=world;}
 public Level level(){return world;} public UUID getUUID(){return id;}
 public BlockPos blockPosition(){return pos;} public boolean isRemoved(){return removed;}
 public boolean isAddedToLevel(){return added;} public RemovalReason getRemovalReason(){return reason;}
 public enum RemovalReason { KILLED,DISCARDED,UNLOADED_TO_CHUNK,CHANGED_DIMENSION;
 public boolean shouldDestroy(){return this==KILLED||this==DISCARDED;} }
}
