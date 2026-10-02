package net.minecraft.world.level.block.state.properties;
import java.util.*;
public class IntegerProperty extends Property<Integer>{private IntegerProperty(String name,int min,int max){super(name);type=Integer.class;List<Integer> values=new ArrayList<>();for(int i=min;i<=max;i++)values.add(i);possible=values;}public static IntegerProperty create(String name,int min,int max){return new IntegerProperty(name,min,max);}}
