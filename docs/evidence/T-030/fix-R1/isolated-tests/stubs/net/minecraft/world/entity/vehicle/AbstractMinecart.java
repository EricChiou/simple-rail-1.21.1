package net.minecraft.world.entity.vehicle;
import net.minecraft.core.*;import net.minecraft.world.phys.Vec3;
public class AbstractMinecart{
 public double x,y,z;public float yaw=35,pitch=12;public int velocityWrites,moves;public Direction heading=Direction.NORTH;private Vec3 velocity=Vec3.ZERO;
 public Vec3 getDeltaMovement(){return velocity;}public Direction getMotionDirection(){return heading;}public float getYRot(){return yaw;}public float getXRot(){return pitch;}
 public void setDeltaMovement(Vec3 v){velocity=v;velocityWrites++;}public void setDeltaMovement(double x,double y,double z){setDeltaMovement(new Vec3(x,y,z));}
 public void moveTo(BlockPos pos,float yaw,float pitch){x=pos.x()+0.5;y=pos.y();z=pos.z()+0.5;this.yaw=yaw;this.pitch=pitch;moves++;}
}