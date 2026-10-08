package com.ericchiu.simplerail.entity;
import java.util.*;import net.minecraft.core.BlockPos;
public final class LocomotiveCartEntity extends net.minecraft.world.entity.vehicle.AbstractMinecart {
 public final List<UUID> cars=new ArrayList<>();
 public final Map<UUID,BlockPos> hints=new HashMap<>(), targets=new HashMap<>();
 public LocomotiveCartEntity(net.minecraft.world.level.Level level){super(level);}
 public List<UUID> trainIds(){return List.copyOf(cars);}
 public Map<UUID,BlockPos> chunkLoadingHints(){return hints;}
 public Map<UUID,BlockPos> chunkLoadingTargets(){return targets;}
}
