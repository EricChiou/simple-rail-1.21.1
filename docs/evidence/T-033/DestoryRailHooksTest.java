package com.ericchiu.simplerail.block;

import com.ericchiu.simplerail.config.CommonConfig;
import java.util.List;
import net.minecraft.core.BlockPos;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.PoweredRailBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.RailShape;
import net.minecraft.world.phys.Vec3;

/** Actual product hook with isolated API doubles; never boots Minecraft. */
public final class DestoryRailHooksTest {
    private static int checks, rows, invocations;
    private static final boolean[] FLAGS={false,true};
    private static void check(boolean pass,String message){checks++;if(!pass)throw new AssertionError(message);}
    /** Checks virtual remove dispatch, not actual Minecraft inventory/loot. */
    private static final class ContainerCartDouble extends AbstractMinecart {
        int contentsHooks;
        @Override public void remove(Entity.RemovalReason reason){contentsHooks++;super.remove(reason);}
    }
    public static void main(String[] args){
        CommonConfig.active=null;DestoryRail rail=new DestoryRail(new BlockBehaviour.Properties());
        check(CommonConfig.reads==0,"Constructor never reads unloaded config");
        check(!rail.defaultBlockState().getValue(DestoryRail.NEED_POWER),"OLD default needPower=false");
        check(!rail.defaultBlockState().getValue(PoweredRailBlock.POWERED)
                &&rail.defaultBlockState().getValue(PoweredRailBlock.SHAPE)==RailShape.NORTH_SOUTH,"Inherited defaults retained");
        check(rail.builder.properties.contains(DestoryRail.NEED_POWER),"Custom state declared");
        BlockPos[] positions={new BlockPos(0,64,0),new BlockPos(-5,-20,12)};
        Vec3[] vectors={Vec3.ZERO,new Vec3(.7,0,0),new Vec3(-.7,.1,.2),new Vec3(0,0,.7),new Vec3(0,0,-.7)};
        for(boolean need:FLAGS)for(boolean power:FLAGS){
            rows++;
            for(RailShape shape:new RailShape[]{RailShape.NORTH_SOUTH,RailShape.EAST_WEST})
                for(boolean stored:FLAGS)for(BlockPos pos:positions)for(Vec3 vector:vectors)
                    for(boolean container:FLAGS)for(boolean occupied:FLAGS){
                        invocations++;
                        CommonConfig.active=new CommonConfig.Snapshot(need);
                        BlockState state=rail.defaultBlockState().setValue(PoweredRailBlock.POWERED,power)
                                .setValue(PoweredRailBlock.SHAPE,shape).setValue(DestoryRail.NEED_POWER,stored);
                        ServerLevel level=new ServerLevel(state);
                        AbstractMinecart cart=container?new ContainerCartDouble():new AbstractMinecart();
                        AbstractMinecart unrelated=new AbstractMinecart();level.carts.add(unrelated);
                        cart.setDeltaMovement(vector);Entity passenger=new Entity();
                        if(occupied)cart.passengers.add(passenger);
                        cart.afterRemove=()->{level.timeline.add("remove");CommonConfig.active=new CommonConfig.Snapshot(!need);};
                        int reads=CommonConfig.reads;rail.onMinecartPass(state,level,pos,cart);
                        boolean active=!need||power;
                        check(CommonConfig.reads==reads+1,"One loaded config snapshot");
                        check(cart.removed==active&&cart.removals==(active?1:0),"Power gate removes target only");
                        check(cart.reason==(active?Entity.RemovalReason.DISCARDED:null),"Discard rather than killed/unload");
                        check(!unrelated.removed&&level.queries==0,"No scan/removal of unrelated neighbor cart");
                        check(cart.getDeltaMovement().equals(vector)&&cart.velocityWrites==1&&cart.moves==0,"No custom cart velocity/position writes");
                        check(level.particleCalls==(active?1:0)&&level.soundCalls==(active?1:0),"Effects only for one successful removal");
                        check(passenger.riding==!(active&&occupied)&&passenger.moves==0,"Parent removal double handles riders, no rail teleport");
                        if(container)check(((ContainerCartDouble)cart).contentsHooks==(active?1:0),"Virtual removal hook preserved, no bypass");
                        if(active){
                            check(level.timeline.equals(List.of("remove","particle","sound")),"Removal before effects");
                            check(level.particle==ParticleTypes.LARGE_SMOKE&&level.count==1,"One large smoke request");
                            check(level.particleX==pos.getX()+.5&&level.particleY==pos.getY()+.75&&level.particleZ==pos.getZ()+.5,"Exact OLD effect coordinate");
                            check(level.dx==0&&level.dy==0&&level.dz==0&&level.speed==0,"Particle zero spread and speed");
                            check(level.sound==SoundEvents.GENERIC_BURN&&level.category==SoundSource.BLOCKS&&level.volume==4&&level.pitch==4,"OLD sound/category/volume/pitch");
                            check(level.excludedPlayer==null&&level.soundX==level.particleX&&level.soundY==level.particleY&&level.soundZ==level.particleZ,"Broadcast with no excluded player and same position");
                            reads=CommonConfig.reads;CommonConfig.active=null;
                            rail.onMinecartPass(state,level,pos,cart);
                            check(CommonConfig.reads==reads&&cart.removals==1&&level.particleCalls==1&&level.soundCalls==1,"Removed-cart guard avoids duplicate removal/effects before config read");
                        }
                    }
        }
        BlockState state=rail.defaultBlockState();BlockPos pos=positions[0];
        CommonConfig.active=null;int reads=CommonConfig.reads;AbstractMinecart cart=new AbstractMinecart();
        Level client=new Level(state);client.isClientSide=true;
        rail.onMinecartPass(state,client,pos,cart);
        rail.onMinecartPass(state,new Level(state),pos,cart);
        check(CommonConfig.reads==reads&&!cart.removed,"Client/non-ServerLevel exits before config or writes");
        for(boolean need:FLAGS){
            CommonConfig.active=new CommonConfig.Snapshot(need);ServerLevel level=new ServerLevel(state);
            rail.onPlace(state,level,pos,new BlockState(new Block()),false);
            check(level.state.getValue(DestoryRail.NEED_POWER)==need&&level.parentCalls==1,"New placement projects needPower");
            reads=CommonConfig.reads;CommonConfig.active=null;
            rail.onPlace(level.state,level,pos,level.state,false);
            check(CommonConfig.reads==reads&&level.state.getValue(DestoryRail.NEED_POWER)==need,"Same block does not rewrite display flag");
        }
        reads=CommonConfig.reads;rail.onPlace(state,client,pos,new BlockState(new Block()),false);
        check(CommonConfig.reads==reads&&client.parentCalls==1,"Client placement only delegates parent");
        // Fresh operations consume reload values even if the block's stored projection is unchanged.
        for(boolean need:new boolean[]{true,false,true}){
            CommonConfig.active=new CommonConfig.Snapshot(need);cart=new AbstractMinecart();
            rail.onMinecartPass(state,new ServerLevel(state),pos,cart);
            check(cart.removed==!need,"Current reloaded config governs next hook");
        }
        System.out.println("PASS checks="+checks+"; behaviorRows="+rows+"; invocations="+invocations+"; MinecraftExecuted=false");
    }
}
