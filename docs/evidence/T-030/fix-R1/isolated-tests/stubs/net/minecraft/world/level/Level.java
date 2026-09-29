package net.minecraft.world.level;
import java.util.*;import net.minecraft.core.BlockPos;import net.minecraft.world.level.block.state.BlockState;import net.minecraft.world.entity.vehicle.AbstractMinecart;import net.minecraft.world.phys.AABB;
public class Level{
 public boolean isClientSide,signal,replaceOnParent;public int writes,queries,parentCalls,lastFlags;public BlockState state;public final List<AbstractMinecart> carts=new ArrayList<>();public Runnable notification;private boolean notifying;
 public Level(BlockState s){state=s;}public BlockState getBlockState(BlockPos p){return state;}
 public void setBlock(BlockPos p,BlockState s,int flags){state=s;writes++;lastFlags=flags;if(notification!=null && !notifying){notifying=true;notification.run();notifying=false;}}
 public <T extends AbstractMinecart>List<T> getEntitiesOfClass(Class<T> type,AABB box){queries++;List<T> found=new ArrayList<>();for(AbstractMinecart c:carts){if(type.isInstance(c)&&box.overlaps(c.x,c.y,c.z))found.add(type.cast(c));}return found;}
}