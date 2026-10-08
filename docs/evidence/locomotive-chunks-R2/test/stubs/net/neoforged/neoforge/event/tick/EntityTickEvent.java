package net.neoforged.neoforge.event.tick;
public class EntityTickEvent {
 public static class Pre {
  private final net.minecraft.world.entity.Entity entity;public boolean canceled;
  public Pre(net.minecraft.world.entity.Entity entity){this.entity=entity;}
  public net.minecraft.world.entity.Entity getEntity(){return entity;}
  public void setCanceled(boolean value){canceled=value;}
 }
}
