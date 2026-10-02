package net.minecraft.world.level;
import net.minecraft.core.BlockPos;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockState;
/** Tracks calls only; no chunk/save/tick simulation. */
public class Level {
    public boolean isClientSide;
    public int blockWrites, dirtyCalls;
    public BlockState state;
    public BlockEntity entity;
    public BlockEntity getBlockEntity(BlockPos p){return entity;}
    public boolean setBlock(BlockPos p,BlockState s,int flags){blockWrites++;state=s;return true;}
    public void blockEntityChanged(BlockPos p){dirtyCalls++;}
}
