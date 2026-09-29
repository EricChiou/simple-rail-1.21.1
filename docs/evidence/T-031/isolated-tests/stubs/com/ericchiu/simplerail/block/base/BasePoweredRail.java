package com.ericchiu.simplerail.block.base;
import net.minecraft.core.BlockPos;import net.minecraft.world.level.Level;import net.minecraft.world.level.block.*;import net.minecraft.world.level.block.state.*;import net.minecraft.world.entity.vehicle.AbstractMinecart;import net.minecraft.world.level.block.state.properties.RailShape;
public class BasePoweredRail extends PoweredRailBlock{
 public final StateDefinition.Builder<Block,BlockState> builder=new StateDefinition.Builder<>();
 public BasePoweredRail(BlockBehaviour.Properties p){createBlockStateDefinition(builder);registerDefaultState(defaultBlockState().setValue(POWERED,false).setValue(SHAPE,RailShape.NORTH_SOUTH));}
 protected void createBlockStateDefinition(StateDefinition.Builder<Block,BlockState> b){b.add(POWERED,SHAPE);}
 protected void onPlace(BlockState s,Level l,BlockPos p,BlockState old,boolean moving){l.parentCalls++;if(!old.is(this) && !l.isClientSide){l.setBlock(p,s,Block.UPDATE_ALL);}}
 public void onMinecartPass(BlockState s,Level l,BlockPos p,AbstractMinecart c){}
 protected void updateState(BlockState s,Level l,BlockPos p,Block b){l.parentCalls++;if(l.replaceOnParent){l.state=new BlockState(new Block());return;}if(s.getValue(POWERED)!=l.signal){l.setBlock(p,s.setValue(POWERED,l.signal),Block.UPDATE_ALL);}}
}
