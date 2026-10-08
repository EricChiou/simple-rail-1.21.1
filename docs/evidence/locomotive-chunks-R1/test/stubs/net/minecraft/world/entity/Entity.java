package net.minecraft.world.entity;
import java.util.UUID;
import net.minecraft.world.level.Level;
public class Entity {
 public Level world; public boolean removed, added;
 public net.minecraft.core.BlockPos pos=new net.minecraft.core.BlockPos(0,64,0);
 private final UUID uuid=UUID.randomUUID();
 public Entity(Level world){this.world=world;}
 public Level level(){return world;}
 public boolean isRemoved(){return removed;}
 public boolean isAddedToLevel(){return added;}
 public net.minecraft.core.BlockPos blockPosition(){return pos;}
 public UUID getUUID(){return uuid;}
}
