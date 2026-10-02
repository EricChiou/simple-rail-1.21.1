package net.minecraft.world.level.block;
import net.minecraft.core.BlockPos;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.entity.*;
public interface EntityBlock {
    BlockEntity newBlockEntity(BlockPos p,BlockState s);
    <T extends BlockEntity> BlockEntityTicker<T> getTicker(Level l,BlockState s,BlockEntityType<T> t);
}
