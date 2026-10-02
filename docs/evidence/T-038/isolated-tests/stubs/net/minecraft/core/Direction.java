package net.minecraft.core;
public enum Direction {
 NORTH(0,0,-1), SOUTH(0,0,1), EAST(1,0,0), WEST(-1,0,0), UP(0,1,0), DOWN(0,-1,0);
 private final int x,y,z; Direction(int x,int y,int z){this.x=x;this.y=y;this.z=z;}
 public int getStepX(){return x;} public int getStepY(){return y;} public int getStepZ(){return z;}
 public enum Axis{X,Y,Z;public boolean isHorizontal(){return this!=Y;}}
 public Axis getAxis(){return y!=0?Axis.Y:x!=0?Axis.X:Axis.Z;}
 public Direction getClockWise(){return switch(this){case NORTH->EAST;case EAST->SOUTH;case SOUTH->WEST;case WEST->NORTH;default->throw new IllegalStateException();};}
}
