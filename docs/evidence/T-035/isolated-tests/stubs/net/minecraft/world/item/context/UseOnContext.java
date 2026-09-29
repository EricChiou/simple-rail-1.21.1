package net.minecraft.world.item.context;
import net.minecraft.world.level.Level;import net.minecraft.core.BlockPos;import net.minecraft.world.item.ItemStack;
public record UseOnContext(Level level,BlockPos pos,ItemStack stack,boolean nullPlayer){public Level getLevel(){return level;}public BlockPos getClickedPos(){return pos;}}
