package net.minecraft.server.level;
import net.minecraft.world.entity.Entity;
/** Only records choice of packet-sending API; never sends an actual packet. */
public class ServerPlayer extends Entity {
 public int teleports;
 public void teleportTo(double x,double y,double z){super.moveTo(x,y,z);teleports++;}
 @Override public void moveTo(double x,double y,double z){throw new AssertionError("Player requires teleport API");}
}
