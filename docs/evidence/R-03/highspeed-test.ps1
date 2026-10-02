$ErrorActionPreference='Stop'
$root=(Get-Location).Path
$out=Join-Path $root 'docs/evidence/R-03/highspeed'
$utf8=[Text.UTF8Encoding]::new($false)
# Review-authored branch/geometry fixtures for the actual HighSpeedRail source.
# These types are test doubles, not Minecraft classes.
$stubs=@{
'com/mojang/serialization/MapCodec.java'='package com.mojang.serialization; public class MapCodec<T>{}'
'net/minecraft/core/Direction.java'='package net.minecraft.core; public enum Direction {EAST(1,0),WEST(-1,0),SOUTH(0,1),NORTH(0,-1),UP(0,0),DOWN(0,0); public final int x,z; Direction(int x,int z){this.x=x;this.z=z;}}'
'net/minecraft/core/BlockPos.java'='package net.minecraft.core; public record BlockPos(int x,int y,int z){public BlockPos relative(Direction d){return new BlockPos(x+d.x,y,z+d.z);}public BlockPos above(){return new BlockPos(x,y+1,z);}public int getX(){return x;}public int getY(){return y;}public int getZ(){return z;}}'
'net/minecraft/world/level/BlockGetter.java'='package net.minecraft.world.level; public interface BlockGetter{}'
'net/minecraft/world/level/Level.java'='package net.minecraft.world.level; import java.util.*;import net.minecraft.core.BlockPos;import net.minecraft.world.level.block.state.BlockState;public class Level implements BlockGetter{public final Map<BlockPos,BlockState> blocks=new HashMap<>();public BlockState getBlockState(BlockPos pos){return blocks.getOrDefault(pos,new BlockState(null,null,false));}}'
'net/minecraft/world/level/block/state/properties/RailShape.java'='package net.minecraft.world.level.block.state.properties; public enum RailShape{NORTH_SOUTH,EAST_WEST,ASCENDING_EAST,ASCENDING_WEST,ASCENDING_NORTH,ASCENDING_SOUTH}'
'net/minecraft/world/level/block/state/BlockBehaviour.java'='package net.minecraft.world.level.block.state;public class BlockBehaviour{public static class Properties{}}'
'net/minecraft/world/level/block/state/BlockState.java'='package net.minecraft.world.level.block.state;import net.minecraft.world.level.block.state.properties.RailShape;public record BlockState(Object block,RailShape shape,boolean tagged){public Object getBlock(){return block;}}'
'net/minecraft/world/level/block/BaseRailBlock.java'='package net.minecraft.world.level.block;import net.minecraft.world.level.block.state.*;import net.minecraft.world.level.block.state.properties.*;import net.minecraft.world.level.*;import net.minecraft.core.*;import net.minecraft.world.entity.vehicle.*;public class BaseRailBlock{public static boolean isRail(BlockState s){return s.tagged()&&s.block() instanceof BaseRailBlock;}public RailShape getRailDirection(BlockState s,BlockGetter l,BlockPos p,AbstractMinecart c){return s.shape();}}'
'net/minecraft/world/level/block/PoweredRailBlock.java'='package net.minecraft.world.level.block;public class PoweredRailBlock extends BaseRailBlock{}'
'com/ericchiu/simplerail/block/base/BasePoweredRail.java'='package com.ericchiu.simplerail.block.base;import java.util.function.Function;import com.mojang.serialization.MapCodec;import net.minecraft.world.level.block.*;import net.minecraft.world.level.block.state.*;import net.minecraft.world.level.*;import net.minecraft.core.*;import net.minecraft.world.entity.vehicle.*;public class BasePoweredRail extends PoweredRailBlock{public static float configured=0.8f;public BasePoweredRail(BlockBehaviour.Properties p){}public static MapCodec<PoweredRailBlock> simpleCodec(Function<BlockBehaviour.Properties,? extends PoweredRailBlock> f){return new MapCodec<>();}public MapCodec<PoweredRailBlock> codec(){return null;}public boolean canMakeSlopes(BlockState s,BlockGetter l,BlockPos p){return false;}public float getRailMaxSpeed(BlockState s,Level l,BlockPos p,AbstractMinecart c){return configured;}}'
'net/minecraft/world/entity/vehicle/AbstractMinecart.java'='package net.minecraft.world.entity.vehicle;public class AbstractMinecart{public static class Vec3{public final double x,y,z;public Vec3(double x,double y,double z){this.x=x;this.y=y;this.z=z;}}public record Box(double w,double d){public double getXsize(){return w;}public double getZsize(){return d;}}public double x,y,z;public Vec3 motion;public Box box=new Box(0.98f,0.98f);public Vec3 getDeltaMovement(){return motion;}public double getX(){return x;}public double getY(){return y;}public double getZ(){return z;}public Box getBoundingBox(){return box;}}'
}
foreach($entry in $stubs.GetEnumerator()){$path=Join-Path $out ('stubs/'+$entry.Key);New-Item -ItemType Directory -Force (Split-Path $path)|Out-Null;[IO.File]::WriteAllText($path,$entry.Value,$utf8)}
$classes=Join-Path $out 'classes'
New-Item -ItemType Directory -Force $classes|Out-Null
$files=@(Get-ChildItem -Recurse -File ($out+'/stubs') -Filter '*.java'|ForEach-Object {$_.FullName})+@((Join-Path $root 'src/main/java/com/ericchiu/simplerail/block/HighSpeedRail.java'),(Join-Path $root 'src/main/java/com/ericchiu/simplerail/block/RailAscentMovementLimit.java'),(Join-Path $root 'docs/evidence/R-03/HighSpeedReviewTest.java'))
function Run([string]$name,[string]$exe,[string[]]$arguments){
 $pinfo=[Diagnostics.ProcessStartInfo]::new();$pinfo.FileName=(Get-Command $exe).Source;$pinfo.Arguments=($arguments|ForEach-Object {'"'+$_+'"'})-join ' ';$pinfo.WorkingDirectory=$out;$pinfo.UseShellExecute=$false;$pinfo.CreateNoWindow=$true;$pinfo.RedirectStandardOutput=$true;$pinfo.RedirectStandardError=$true
 $p=[Diagnostics.Process]::Start($pinfo);$o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync();$p.WaitForExit()
 [IO.File]::WriteAllText(($out+'/'+$name+'.log'),$o.Result+$e.Result,$utf8)
 [IO.File]::WriteAllText(($out+'/'+$name+'.json'),([ordered]@{exe=$pinfo.FileName;arguments=$arguments;utc=[DateTime]::UtcNow.ToString('o');exitCode=$p.ExitCode}|ConvertTo-Json -Depth 5),$utf8)
 Write-Output ($name+': '+$p.ExitCode+' '+$o.Result.Trim());if($p.ExitCode -ne 0){throw $name}
}
Run 'compile' 'javac' (@('--release','21','-proc:none','-encoding','UTF-8','-Xlint:all','-Werror','-d',$classes)+$files)
Run 'run' 'java' @('-ea','-cp',$classes,'com.ericchiu.simplerail.block.HighSpeedReviewTest')
[IO.File]::WriteAllText(($out+'/inputs.json'),(@($files|ForEach-Object {[pscustomobject]@{path=$_;sha256=(Get-FileHash -LiteralPath $_).Hash}})|ConvertTo-Json -Depth 5),$utf8)
