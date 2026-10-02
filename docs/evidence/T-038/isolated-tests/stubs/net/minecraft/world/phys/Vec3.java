package net.minecraft.world.phys;
public record Vec3(double x,double y,double z) {
    public static final Vec3 ZERO=new Vec3(0,0,0);
    public Vec3 scale(double s){return new Vec3(x*s,y*s,z*s);}
}
