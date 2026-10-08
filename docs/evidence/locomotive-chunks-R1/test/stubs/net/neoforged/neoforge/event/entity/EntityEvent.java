package net.neoforged.neoforge.event.entity;
import net.minecraft.world.entity.Entity;
public class EntityEvent {
 private final Entity entity;
 public EntityEvent(Entity entity){this.entity=entity;}
 public Entity getEntity(){return entity;}
 public static class EnteringSection extends EntityEvent {
  private final boolean changed;
  public EnteringSection(Entity entity,boolean changed){super(entity);this.changed=changed;}
  public boolean didChunkChange(){return changed;}
 }
}
