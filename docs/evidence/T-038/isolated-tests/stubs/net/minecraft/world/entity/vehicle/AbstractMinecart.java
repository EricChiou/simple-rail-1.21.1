package net.minecraft.world.entity.vehicle;
import java.util.UUID;
import net.minecraft.core.*;
import net.minecraft.world.phys.Vec3;
public class AbstractMinecart {
    public UUID id=UUID.randomUUID();
    public Direction heading=Direction.NORTH;
    public int moves,velocityWrites;
    private Vec3 velocity=Vec3.ZERO;
    public UUID getUUID(){return id;}
    public Vec3 getDeltaMovement(){return velocity;}
    public void setDeltaMovement(Vec3 v){velocity=v;velocityWrites++;}
    public void setDeltaMovement(double x,double y,double z){setDeltaMovement(new Vec3(x,y,z));}
    public Direction getMotionDirection(){return heading;}
    public float getYRot(){return 32;}
    public float getXRot(){return 9;}
    public void moveTo(BlockPos p,float yaw,float pitch){moves++;}
}
