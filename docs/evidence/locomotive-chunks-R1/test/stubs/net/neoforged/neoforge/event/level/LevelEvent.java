package net.neoforged.neoforge.event.level;
public class LevelEvent {
 public static class Unload {
  private final net.minecraft.world.level.Level level;
  public Unload(net.minecraft.world.level.Level level){this.level=level;}
  public net.minecraft.world.level.Level getLevel(){return level;}
 }
}
