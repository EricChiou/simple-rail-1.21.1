package net.minecraft.world.level.block.entity;
import net.minecraft.core.*;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.state.BlockState;
public class BlockEntity {
    public Level level;
    public int dirtyCalls;
    public BlockEntity(BlockEntityType<?> t,BlockPos p,BlockState s) {}
    public void setChanged(){dirtyCalls++;}
    protected void saveAdditional(CompoundTag t,HolderLookup.Provider p) {}
    protected void loadAdditional(CompoundTag t,HolderLookup.Provider p) {}
}
