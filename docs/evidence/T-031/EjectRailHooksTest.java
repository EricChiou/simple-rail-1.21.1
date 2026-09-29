package com.ericchiu.simplerail.block;

import com.ericchiu.simplerail.config.CommonConfig;
import net.minecraft.core.BlockPos;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.PoweredRailBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.RailShape;
import net.minecraft.world.phys.Vec3;

/** Compiles the actual EjectRail hook against local doubles; no Minecraft classes loaded. */
public final class EjectRailHooksTest {
    private static int checks, rows, invocations;
    private static final boolean[] FLAGS = {false,true};
    private static void check(boolean pass,String message) {
        checks++;
        if (!pass) throw new AssertionError(message);
    }
    public static void main(String[] args) {
        CommonConfig.active=null;
        EjectRail rail=new EjectRail(new BlockBehaviour.Properties());
        check(CommonConfig.reads==0,"Constructor does not read unloaded config");
        check(!rail.defaultBlockState().getValue(EjectRail.REVERSE)
                && rail.defaultBlockState().getValue(EjectRail.NEED_POWER),"Stable default flags");
        check(!rail.defaultBlockState().getValue(PoweredRailBlock.POWERED)
                && rail.defaultBlockState().getValue(PoweredRailBlock.SHAPE)==RailShape.NORTH_SOUTH,"Inherited defaults retained");
        check(rail.builder.properties.contains(EjectRail.REVERSE)
                && rail.builder.properties.contains(EjectRail.NEED_POWER),"Both custom properties declared");
        Vec3[] inputs={new Vec3(.7,0,0),new Vec3(-.7,0,0),new Vec3(0,0,.7),new Vec3(0,0,-.7)};
        BlockPos[] positions={new BlockPos(-5,65,12),new BlockPos(7,-20,-31)};
        for (RailShape shape:new RailShape[]{RailShape.NORTH_SOUTH,RailShape.EAST_WEST})
            for (boolean reverse:FLAGS) for(boolean powered:FLAGS) for(boolean need:FLAGS)
                for(int distance:new int[]{1,3,100}) {
                    rows++;
                    for(boolean storedNeed:FLAGS) for(Vec3 input:inputs) for(BlockPos pos:positions)
                        for(int count:new int[]{0,1,3}) {
                            invocations++;
                            CommonConfig.active=new CommonConfig.Snapshot(distance,need);
                            BlockState state=rail.defaultBlockState().setValue(PoweredRailBlock.SHAPE,shape)
                                    .setValue(PoweredRailBlock.POWERED,powered).setValue(EjectRail.REVERSE,reverse)
                                    .setValue(EjectRail.NEED_POWER,storedNeed);
                            AbstractMinecart cart=new AbstractMinecart();cart.setDeltaMovement(input);
                            Entity[] people=new Entity[count];
                            for(int i=0;i<count;i++){people[i]=i%2==0?new ServerPlayer():new Entity();cart.passengers.add(people[i]);}
                            // Config reload after detaching must not mix settings within an operation.
                            cart.afterEject=()->CommonConfig.active=new CommonConfig.Snapshot(distance==100?1:100,!need);
                            int reads=CommonConfig.reads;
                            rail.onMinecartPass(state,new Level(state),pos,cart);
                            boolean active=!need||powered;
                            check(CommonConfig.reads==reads+1,"Exactly one current config snapshot");
                            check(cart.ejections==(active&&count>0?1:0),"Detach all once, only if active and occupied");
                            check(cart.passengers.size()==(active?0:count),"No skipped passenger after list mutation");
                            check(cart.velocityWrites==1&&cart.getDeltaMovement().equals(input)&&cart.moves==0,"Hook never moves/stops cart");
                            check(cart.passengerReads==(active?1:0),"Power gate precedes passenger query");
                            for(Entity p:people) {
                                if(!active) {
                                    check(p.riding&&p.moves==0&&p.velocityWrites==0,"Inactive leaves riders untouched");
                                } else {
                                    // OLD absolute coordinates; negative side intentionally differs by one from centered +/-distance.
                                    double negative=-distance-0.5,positive=distance+0.5;
                                    double expectedX=shape==RailShape.NORTH_SOUTH?pos.getX()+(reverse?positive:negative):pos.getX()+0.5;
                                    double expectedZ=shape==RailShape.EAST_WEST?pos.getZ()+(reverse?positive:negative):pos.getZ()+0.5;
                                    check(!p.riding&&p.moves==1,"Dismount before exactly one final move");
                                    check(p.x==expectedX&&p.y==pos.getY()&&p.z==expectedZ,"Exact OLD side coordinate, including negative origin and height");
                                    check(p.getDeltaMovement().equals(Vec3.ZERO)&&p.velocityWrites==1,"Passenger momentum zeroed");
                                    check(p.yaw==35&&p.pitch==12,"Orientation retained");
                                }
                                if(p instanceof ServerPlayer player)check(player.teleports==(active?1:0),"Player dispatch uses packet API double");
                            }
                        }
                }
        BlockPos pos=positions[0];BlockState state=rail.defaultBlockState();
        CommonConfig.active=null;
        Level client=new Level(state);client.isClientSide=true;AbstractMinecart cart=new AbstractMinecart();
        cart.passengers.add(new ServerPlayer());int reads=CommonConfig.reads;
        rail.onMinecartPass(state,client,pos,cart);
        check(CommonConfig.reads==reads&&cart.ejections==0&&cart.passengerReads==0,"Client exits before config/entity writes");
        for(boolean need:FLAGS) {
            CommonConfig.active=new CommonConfig.Snapshot(3,need);Level level=new Level(state);
            rail.onPlace(state,level,pos,new BlockState(new Block()),false);
            check(level.state.getValue(EjectRail.NEED_POWER)==need&&level.parentCalls==1,"New server placement projects config through parent");
            CommonConfig.active=null;reads=CommonConfig.reads;
            rail.onPlace(level.state,level,pos,level.state,false);
            check(CommonConfig.reads==reads&&level.state.getValue(EjectRail.NEED_POWER)==need,"Same-block update does not rewrite display flag");
        }
        CommonConfig.active=null;reads=CommonConfig.reads;
        rail.onPlace(state,client,pos,new BlockState(new Block()),false);
        check(CommonConfig.reads==reads&&client.parentCalls==1,"Client placement only delegates to parent");
        // Repeated hooks must use a newly loaded distance, while stored display state stays unchanged.
        for(int d:new int[]{1,100,3}) {
            CommonConfig.active=new CommonConfig.Snapshot(d,false);cart=new AbstractMinecart();Entity p=new Entity();cart.passengers.add(p);
            rail.onMinecartPass(state,new Level(state),pos,cart);
            check(p.x==pos.getX()-d-0.5,"Reloaded distance governs next hook");
        }
        System.out.println("PASS checks="+checks+"; behaviorRows="+rows+"; invocations="+invocations+"; MinecraftExecuted=false");
    }
}
