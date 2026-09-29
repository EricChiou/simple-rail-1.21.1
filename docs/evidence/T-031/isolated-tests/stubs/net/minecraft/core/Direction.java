package net.minecraft.core;
public enum Direction {
 NORTH(0,0,-1), SOUTH(0,0,1), EAST(1,0,0), WEST(-1,0,0), UP(0,1,0), DOWN(0,-1,0);
 private final int x,y,z; Direction(int x,int y,int z){this.x=x;this.y=y;this.z=z;}
 public int getStepX(){return x;} public int getStepY(){return y;} public int getStepZ(){return z;}
}