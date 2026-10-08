package net.neoforged.neoforge.event.tick;
public class LevelTickEvent {
 public static class Post {
  private final net.minecraft.world.level.Level level;
  public Post(net.minecraft.world.level.Level level){this.level=level;}
  public net.minecraft.world.level.Level getLevel(){return level;}
 }
}
