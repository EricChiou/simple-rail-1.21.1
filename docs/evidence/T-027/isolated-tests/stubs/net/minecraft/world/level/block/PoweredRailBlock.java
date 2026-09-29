package net.minecraft.world.level.block;
import com.mojang.serialization.MapCodec;import net.minecraft.world.level.block.state.properties.Property;
public class PoweredRailBlock extends Block {public static final Property<Boolean> POWERED=new Property<>("powered");public MapCodec<PoweredRailBlock> codec(){return null;}}