package net.neoforged.neoforge.event.entity;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.level.Level;
public final class EntityJoinLevelEvent extends EntityEvent {
 private final Level level;
 public EntityJoinLevelEvent(Entity entity,Level level){super(entity);this.level=level;}
 public Level getLevel(){return level;}
}
