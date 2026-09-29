$ErrorActionPreference='Stop'
$e=Join-Path (Get-Location) 'docs/evidence/T-027'
$root=$e+'/isolated-tests'
# Compile the actual HoldingRail against local test doubles, never real Minecraft classes.
$sources=[ordered]@{
'com/mojang/serialization/MapCodec.java'=@'
package com.mojang.serialization; public class MapCodec<T> {}
'@
'net/minecraft/core/Direction.java'=@'
package net.minecraft.core;
public enum Direction {
 NORTH(0,0,-1), SOUTH(0,0,1), EAST(1,0,0), WEST(-1,0,0), UP(0,1,0), DOWN(0,-1,0);
 private final int x,y,z; Direction(int x,int y,int z){this.x=x;this.y=y;this.z=z;}
 public int getStepX(){return x;} public int getStepY(){return y;} public int getStepZ(){return z;}
}
'@
'net/minecraft/core/BlockPos.java'=@'
package net.minecraft.core; public record BlockPos(int x,int y,int z) {}
'@
'net/minecraft/world/phys/Vec3.java'=@'
package net.minecraft.world.phys; public record Vec3(double x,double y,double z){public static final Vec3 ZERO=new Vec3(0,0,0);}
'@
'net/minecraft/world/phys/AABB.java'=@'
package net.minecraft.world.phys;
import net.minecraft.core.BlockPos;
public record AABB(BlockPos pos) {
 public boolean overlaps(double x,double y,double z){return x+0.49>pos.x() && x-0.49<pos.x()+1 && y+0.7>pos.y() && y<pos.y()+1 && z+0.49>pos.z() && z-0.49<pos.z()+1;}
}
'@
'net/minecraft/world/level/block/state/properties/Property.java'=@'
package net.minecraft.world.level.block.state.properties; public class Property<T>{public final String name;public Property(String name){this.name=name;}}
'@
'net/minecraft/world/level/block/state/properties/EnumProperty.java'=@'
package net.minecraft.world.level.block.state.properties;
public class EnumProperty<T extends Enum<T>> extends Property<T>{private EnumProperty(String name){super(name);}public static <T extends Enum<T>> EnumProperty<T> create(String name,Class<T> type){return new EnumProperty<T>(name);}}
'@
'net/minecraft/world/level/block/state/BlockBehaviour.java'=@'
package net.minecraft.world.level.block.state; public class BlockBehaviour{public static class Properties{}}
'@
'net/minecraft/world/level/block/state/StateDefinition.java'=@'
package net.minecraft.world.level.block.state;
import java.util.*;import net.minecraft.world.level.block.state.properties.Property;
public class StateDefinition {public static class Builder<B,S>{public final List<Property<?>> properties=new ArrayList<>();public void add(Property<?>... p){properties.addAll(Arrays.asList(p));}}}
'@
'net/minecraft/world/level/block/state/BlockState.java'=@'
package net.minecraft.world.level.block.state;
import java.util.*;import net.minecraft.world.level.block.Block;import net.minecraft.world.level.block.state.properties.Property;
public class BlockState{
 private final Block block;private final Map<Property<?>,Object> values;
 public BlockState(Block block){this(block,new HashMap<>());}private BlockState(Block block,Map<Property<?>,Object> values){this.block=block;this.values=values;}
 @SuppressWarnings("unchecked") public <T>T getValue(Property<T> p){return (T)values.get(p);}
 public <T>BlockState setValue(Property<T> p,T value){Map<Property<?>,Object> copy=new HashMap<>(values);copy.put(p,value);return new BlockState(block,copy);}
 public boolean is(Block b){return block==b;}
}
'@
'net/minecraft/world/level/block/Block.java'=@'
package net.minecraft.world.level.block;
import java.util.function.Function;import com.mojang.serialization.MapCodec;import net.minecraft.world.level.block.state.*;
public class Block{
 public static final int UPDATE_ALL=3;private BlockState defaults;
 public Block(){defaults=new BlockState(this);}public BlockState defaultBlockState(){return defaults;}protected void registerDefaultState(BlockState s){defaults=s;}
 protected static <T>MapCodec<T> simpleCodec(Function<BlockBehaviour.Properties,T> factory){return new MapCodec<T>();}
}
'@
'net/minecraft/world/level/block/PoweredRailBlock.java'=@'
package net.minecraft.world.level.block;
import com.mojang.serialization.MapCodec;import net.minecraft.world.level.block.state.properties.Property;
public class PoweredRailBlock extends Block {public static final Property<Boolean> POWERED=new Property<>("powered");public MapCodec<PoweredRailBlock> codec(){return null;}}
'@
'net/minecraft/world/entity/vehicle/AbstractMinecart.java'=@'
package net.minecraft.world.entity.vehicle;
import net.minecraft.core.*;import net.minecraft.world.phys.Vec3;
public class AbstractMinecart{
 public double x,y,z;public float yaw=35,pitch=12;public int velocityWrites,moves;public Direction heading=Direction.NORTH;private Vec3 velocity=Vec3.ZERO;
 public Vec3 getDeltaMovement(){return velocity;}public Direction getMotionDirection(){return heading;}public float getYRot(){return yaw;}public float getXRot(){return pitch;}
 public void setDeltaMovement(Vec3 v){velocity=v;velocityWrites++;}public void setDeltaMovement(double x,double y,double z){setDeltaMovement(new Vec3(x,y,z));}
 public void moveTo(BlockPos pos,float yaw,float pitch){x=pos.x()+0.5;y=pos.y();z=pos.z()+0.5;this.yaw=yaw;this.pitch=pitch;moves++;}
}
'@
'net/minecraft/world/level/Level.java'=@'
package net.minecraft.world.level;
import java.util.*;import net.minecraft.core.BlockPos;import net.minecraft.world.level.block.state.BlockState;import net.minecraft.world.entity.vehicle.AbstractMinecart;import net.minecraft.world.phys.AABB;
public class Level{
 public boolean isClientSide,signal,replaceOnParent;public int writes,queries,parentCalls,lastFlags;public BlockState state;public final List<AbstractMinecart> carts=new ArrayList<>();public Runnable notification;private boolean notifying;
 public Level(BlockState s){state=s;}public BlockState getBlockState(BlockPos p){return state;}
 public void setBlock(BlockPos p,BlockState s,int flags){state=s;writes++;lastFlags=flags;if(notification!=null && !notifying){notifying=true;notification.run();notifying=false;}}
 public <T extends AbstractMinecart>List<T> getEntitiesOfClass(Class<T> type,AABB box){queries++;List<T> found=new ArrayList<>();for(AbstractMinecart c:carts){if(type.isInstance(c)&&box.overlaps(c.x,c.y,c.z))found.add(type.cast(c));}return found;}
}
'@
'com/ericchiu/simplerail/block/base/BasePoweredRail.java'=@'
package com.ericchiu.simplerail.block.base;
import net.minecraft.core.BlockPos;import net.minecraft.world.level.Level;import net.minecraft.world.level.block.*;import net.minecraft.world.level.block.state.*;import net.minecraft.world.entity.vehicle.AbstractMinecart;
public class BasePoweredRail extends PoweredRailBlock{
 public final StateDefinition.Builder<Block,BlockState> builder=new StateDefinition.Builder<>();
 public BasePoweredRail(BlockBehaviour.Properties p){createBlockStateDefinition(builder);registerDefaultState(defaultBlockState().setValue(POWERED,false));}
 protected void createBlockStateDefinition(StateDefinition.Builder<Block,BlockState> b){b.add(POWERED);}
 public void onMinecartPass(BlockState s,Level l,BlockPos p,AbstractMinecart c){}
 protected void updateState(BlockState s,Level l,BlockPos p,Block b){l.parentCalls++;if(l.replaceOnParent){l.state=new BlockState(new Block());return;}if(s.getValue(POWERED)!=l.signal){l.setBlock(p,s.setValue(POWERED,l.signal),Block.UPDATE_ALL);}}
}
'@
}
foreach($entry in $sources.GetEnumerator()){$path=$root+'/stubs/'+$entry.Key;New-Item -ItemType Directory -Force (Split-Path $path)|Out-Null;[IO.File]::WriteAllText($path,$entry.Value,[Text.UTF8Encoding]::new($false))}
New-Item -ItemType Directory -Force ($root+'/classes')|Out-Null
$java='C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot/bin'
$files=@(Get-ChildItem ($root+'/stubs') -Recurse -Filter '*.java'|ForEach-Object {$_.FullName})+@((Join-Path (Get-Location) 'src/main/java/com/ericchiu/simplerail/block/HoldingRail.java'),($e+'/HoldingRailHooksTest.java'))
$started=[DateTime]::UtcNow.ToString('o')
& ($java+'/javac.exe') --release 21 -encoding UTF-8 -Xlint:unchecked -Werror -d ($root+'/classes') $files *> ($e+'/hooks-compile-01.log');$compileCode=$LASTEXITCODE
& ($java+'/java.exe') -cp ($root+'/classes') com.ericchiu.simplerail.block.HoldingRailHooksTest *> ($e+'/hooks-test-01.log');$runCode=$LASTEXITCODE
[ordered]@{command='powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-027/hooks-test.ps1';compileCommand='Temurin 21 javac --release 21 -encoding UTF-8 -Xlint:unchecked -Werror -d isolated-tests/classes [15 explicit test doubles + actual HoldingRail.java + HoldingRailHooksTest.java]';compileExitCode=$compileCode;runCommand='Temurin 21 java -cp isolated-tests/classes com.ericchiu.simplerail.block.HoldingRailHooksTest';runExitCode=$runCode;startedUtc=$started;finishedUtc=[DateTime]::UtcNow.ToString('o');scope='Actual production hook code compiled separately against local doubles; no real Minecraft classes loaded';gameExecuted=$false}|ConvertTo-Json|Set-Content -Encoding UTF8 ($e+'/hooks-test.json')
Get-Content ($e+'/hooks-compile-01.log');Get-Content ($e+'/hooks-test-01.log')
if($compileCode -ne 0 -or $runCode -ne 0){exit 1}
