package net.minecraft.world.entity;
import net.minecraft.world.phys.Vec3;
/** Instrumented position/velocity double; no game runtime. */
public class Entity {
 public double x=99,y=88,z=77;public float yaw=35,pitch=12;
 public int moves,velocityWrites;public boolean riding=true;
 private Vec3 velocity=new Vec3(0.3,-0.2,0.1);
 public Vec3 getDeltaMovement(){return velocity;}
 public void setDeltaMovement(Vec3 v){velocity=v;velocityWrites++;}
 public void moveTo(double x,double y,double z){
  if(riding)throw new AssertionError("Must dismount before final position");
  this.x=x;this.y=y;this.z=z;moves++;
 }
}
