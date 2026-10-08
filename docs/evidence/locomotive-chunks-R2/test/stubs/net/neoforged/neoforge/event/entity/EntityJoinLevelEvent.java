package net.neoforged.neoforge.event.entity;
public record EntityJoinLevelEvent(net.minecraft.world.entity.Entity entity,net.minecraft.world.level.Level level){
public net.minecraft.world.entity.Entity getEntity(){return entity;}public net.minecraft.world.level.Level getLevel(){return level;}}
