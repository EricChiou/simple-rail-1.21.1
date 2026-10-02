package com.ericchiu.simplerail.blockentity;
import com.ericchiu.simplerail.block.TimerHoldingRail;
import com.ericchiu.simplerail.config.CommonConfig;
import com.ericchiu.simplerail.registry.ModBlockEntities;
import java.util.concurrent.atomic.AtomicLong;
import net.minecraft.core.*;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.*;
import net.minecraft.world.phys.Vec3;
/** Actual production rail + BE + timer + data, with explicit external doubles and actual NEW NBT. */
public final class TimerRailHooksTest {
    private static int checks;
    private static void check(boolean ok,String label){checks++;if(!ok)throw new AssertionError(label);}
    public static void main(String[] args) {
        var pos=new BlockPos(10,64,10);var rail=new TimerHoldingRail(new BlockBehaviour.Properties());
        check(rail.defaultBlockState().getValue(TimerHoldingRail.LEVEL)==0,"default level");
        check(rail.defaultBlockState().getValue(TimerHoldingRail.DIRECTION)==Direction.DOWN,"explicit default direction");
        Level world=new Level();world.state=rail.defaultBlockState();
        var cart=new AbstractMinecart();cart.setDeltaMovement(new Vec3(0.2,0,0));
        int reads=CommonConfig.reads;
        rail.onMinecartPass(world.state,world,pos,cart);
        check(cart.getDeltaMovement().equals(new Vec3(0.24,0,0))&&cart.moves==0,"level zero OLD moving bypass");
        check(CommonConfig.reads==reads,"level zero no config read");
        cart.setDeltaMovement(Vec3.ZERO);int writes=cart.velocityWrites;
        rail.onMinecartPass(world.state,world,pos,cart);check(cart.velocityWrites==writes,"stationary bypass no write");
        world.state=world.state.setValue(TimerHoldingRail.LEVEL,1);
        cart.setDeltaMovement(new Vec3(0.2,0,0));rail.onMinecartPass(world.state,world,pos,cart);
        check(cart.getDeltaMovement().equals(new Vec3(0.24,0,0)),"missing BE bypass");
        world.isClientSide=true;writes=cart.velocityWrites;rail.onMinecartPass(world.state,world,pos,cart);
        check(cart.velocityWrites==writes&&CommonConfig.reads==reads,"client has no gameplay/config write");
        check(rail.getTicker(world,world.state,ModBlockEntities.TIMER_HOLDING_RAIL.get())==null,"client ticker absent");
        world.isClientSide=false;
        check(rail.getTicker(world,world.state,new BlockEntityType<TimerHoldingRailBlockEntity>())==null,"wrong BE ticker absent");
        var ticker=rail.getTicker(world,world.state,ModBlockEntities.TIMER_HOLDING_RAIL.get());check(ticker!=null,"server ticker bound");
        for(int level=1;level<=9;level++)for(Direction direction:Direction.values())for(boolean power:new boolean[]{false,true}) {
            AtomicLong clock=new AtomicLong(1_000_000L);
            world=new Level();world.state=rail.defaultBlockState().setValue(TimerHoldingRail.LEVEL,level).setValue(TimerHoldingRail.POWERED,power);
            var be=new TimerHoldingRailBlockEntity(pos,world.state,clock::get);be.level=world;world.entity=be;
            cart=new AbstractMinecart();cart.heading=direction;cart.setDeltaMovement(new Vec3(0.3,0,0));
            CommonConfig.seconds=5;reads=CommonConfig.reads;
            rail.onMinecartPass(world.state,world,pos,cart);
            check(CommonConfig.reads==reads+1&&CommonConfig.lastLevel==level,"correct live level setting");
            check(be.ownsCart(cart.id)&&be.dirtyCalls==1,"start persists UUID and duration");
            check(cart.getDeltaMovement().equals(Vec3.ZERO)&&cart.moves==1,"new cart stopped");
            check(world.state.getValue(TimerHoldingRail.DIRECTION)==direction,"direction recorded");
            CompoundTag tag=new CompoundTag();be.saveAdditional(tag,null);
            check(tag.getCompound(HoldingTimerData.KEY).getLong("remaining_ms")==5000,"start snapshot");
            CommonConfig.seconds=60;clock.addAndGet(2_000_000_000L);
            ticker.tick(world,pos,world.state,be);
            check(world.dirtyCalls==1&&be.dirtyCalls==1,"tick marks persistence without neighbour setChanged");
            reads=CommonConfig.reads;rail.onMinecartPass(world.state,world,pos,cart);
            check(CommonConfig.reads==reads&&cart.getDeltaMovement().equals(Vec3.ZERO),"active wait not reset by reload");
            tag=new CompoundTag();be.saveAdditional(tag,null);
            check(tag.getCompound(HoldingTimerData.KEY).getLong("remaining_ms")==3000,"save after real two seconds");
            check(be.pauseForUnload(),"unload requests final chunk snapshot");clock.addAndGet(90_000_000_000L);
            CompoundTag frozen=new CompoundTag();be.saveAdditional(frozen,null);
            check(frozen.getCompound(HoldingTimerData.KEY).getLong("remaining_ms")==3000,"unloaded snapshot frozen");
            var restored=new TimerHoldingRailBlockEntity(pos,world.state,clock::get);restored.level=world;world.entity=restored;
            restored.loadAdditional(frozen,null);clock.addAndGet(20_000_000_000L);
            ticker.tick(world,pos,world.state,restored);clock.addAndGet(2_999_000_000L);
            check(!restored.readyToRelease(),"readback still waits almost three seconds");
            clock.addAndGet(1_000_000L);rail.onMinecartPass(world.state,world,pos,cart);
            Vec3 expected=new Vec3(direction.getStepX()*0.4,direction.getStepY()*0.4,direction.getStepZ()*0.4);
            check(cart.getDeltaMovement().equals(expected),"release in stored direction");
            reads=CommonConfig.reads;rail.onMinecartPass(world.state,world,pos,cart);
            check(CommonConfig.reads==reads&&cart.getDeltaMovement().equals(expected),"same cart keeps releasing");
            var replacement=new AbstractMinecart();rail.onMinecartPass(world.state,world,pos,replacement);
            tag=new CompoundTag();restored.saveAdditional(tag,null);
            check(restored.ownsCart(replacement.id)&&tag.getCompound(HoldingTimerData.KEY).getLong("remaining_ms")==60000,"different cart uses reloaded setting");
        }
        var clock=new AtomicLong();world=new Level();world.state=rail.defaultBlockState().setValue(TimerHoldingRail.LEVEL,1);
        var be=new TimerHoldingRailBlockEntity(pos,world.state,clock::get);world.entity=be;be.level=world;
        cart=new AbstractMinecart();CommonConfig.seconds=0;
        rail.onMinecartPass(world.state,world,pos,cart);check(cart.moves==1,"zero setting still stops on first new-cart callback");
        rail.onMinecartPass(world.state,world,pos,cart);check(cart.getDeltaMovement().equals(new Vec3(0,0,-0.4)),"zero setting releases next callback");
        CompoundTag unused=new CompoundTag();be.loadAdditional(unused,null);check(!be.ownsCart(cart.id),"missing data resets idle");
        check(!be.pauseForUnload(),"unused unload no timer snapshot requirement");
        System.out.println("PASS actual rail/BE hooks checks="+checks+"; matrix=9levels*6directions*2power; external doubles; no game runtime");
    }
}
