package net.minecraft.world.level.block;
import com.mojang.serialization.MapCodec;import net.minecraft.world.level.block.state.properties.*;
public class PoweredRailBlock extends Block {public static final Property<Boolean> POWERED=new Property<>("powered");public static final EnumProperty<RailShape> SHAPE=EnumProperty.create("shape",RailShape.class);public MapCodec<PoweredRailBlock> codec(){return null;} public boolean isActivatorRail(){return false;}}
