package net.minecraft.world.level.block.state;
import java.util.*;import net.minecraft.world.level.block.Block;import net.minecraft.world.level.block.state.properties.Property;
public class BlockState{
 private final Block block;private final Map<Property<?>,Object> values;
 public BlockState(Block block){this(block,new HashMap<>());}private BlockState(Block block,Map<Property<?>,Object> values){this.block=block;this.values=values;}
 @SuppressWarnings("unchecked") public <T>T getValue(Property<T> p){return (T)values.get(p);}
 public <T>BlockState setValue(Property<T> p,T value){if(values.containsKey(p)&&Objects.equals(values.get(p),value))return this;block.definition.properties.put(p.name,p);Map<Property<?>,Object> copy=new HashMap<>(values);copy.put(p,value);return new BlockState(block,copy);}
 public boolean is(Block b){return block==b;}
 public Block getBlock(){return block;}public boolean is(net.minecraft.tags.TagKey<Block> tag){return block.tags.contains(tag);}
}
