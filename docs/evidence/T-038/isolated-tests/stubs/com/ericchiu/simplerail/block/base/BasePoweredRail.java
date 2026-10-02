package com.ericchiu.simplerail.block.base;
import net.minecraft.core.BlockPos;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.*;
import net.minecraft.world.level.block.state.*;
import net.minecraft.world.level.block.state.properties.Property;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
/** Parent movement/geometry is a double, not Minecraft runtime. */
public class BasePoweredRail extends PoweredRailBlock {
    public BasePoweredRail(BlockBehaviour.Properties p) {
        createBlockStateDefinition(new StateDefinition.Builder<>());
        registerDefaultState(defaultBlockState().setValue(POWERED,false));
    }
    protected void createBlockStateDefinition(StateDefinition.Builder<Block,BlockState> b) { b.add(POWERED); }
    public void onMinecartPass(BlockState s,Level l,BlockPos p,AbstractMinecart c) {}
}
