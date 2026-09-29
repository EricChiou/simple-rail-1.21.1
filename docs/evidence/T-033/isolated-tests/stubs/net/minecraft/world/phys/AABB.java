package net.minecraft.world.phys;
import net.minecraft.core.BlockPos;
public record AABB(BlockPos pos) {
 public boolean overlaps(double x,double y,double z){return x+0.49>pos.x() && x-0.49<pos.x()+1 && y+0.7>pos.y() && y<pos.y()+1 && z+0.49>pos.z() && z-0.49<pos.z()+1;}
}