package net.minecraft.world.level.block;
import java.util.function.Function;import com.mojang.serialization.MapCodec;import net.minecraft.world.level.block.state.*;
public class Block{
 public static final int UPDATE_ALL=3;private BlockState defaults;
 public Block(){defaults=new BlockState(this);}public BlockState defaultBlockState(){return defaults;}protected void registerDefaultState(BlockState s){defaults=s;}
 protected static <T>MapCodec<T> simpleCodec(Function<BlockBehaviour.Properties,T> factory){return new MapCodec<T>();}
}