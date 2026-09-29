package com.ericchiu.simplerail.block;

import com.ericchiu.simplerail.config.CommonConfig;
import com.ericchiu.simplerail.mixin.AbstractMinecartMixin;
import java.lang.reflect.Method;
import net.minecraft.core.BlockPos;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.PoweredRailBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.RailShape;
import net.minecraft.world.phys.Vec3;

/** Calls the real redirect and hook against doubles; never starts Minecraft. */
public final class CoastingRegressionTest {
    private static int checks;
    private static void check(boolean pass, String message) {
        checks++;
        if (!pass) throw new AssertionError(message);
    }

    public static void main(String[] args) throws Exception {
        AbstractMinecartMixin mixin = new AbstractMinecartMixin() {};
        Method redirect = AbstractMinecartMixin.class.getDeclaredMethod(
                "simplerail$coastOnUnpoweredOnewayRail", PoweredRailBlock.class, BlockPos.class, BlockState.class);
        redirect.setAccessible(true);
        BlockPos pos = new BlockPos(0,64,0);
        OnewayRail oneway = new OnewayRail(new BlockBehaviour.Properties());
        PoweredRailBlock ordinaryPowered = new PoweredRailBlock();
        PoweredRailBlock activator = new PoweredRailBlock() {
            @Override public boolean isActivatorRail() { return true; }
        };
        for (boolean powered : new boolean[]{false,true}) {
            BlockState state = oneway.defaultBlockState().setValue(PoweredRailBlock.POWERED,powered);
            check((boolean) redirect.invoke(mixin,oneway,pos,state) == !powered,
                    "Only unpowered oneway skips powered-rail physics");
            check(!(boolean) redirect.invoke(mixin,ordinaryPowered,pos,state),
                    "Vanilla/other powered rails retain brake/acceleration classification");
            check((boolean) redirect.invoke(mixin,activator,pos,state), "Activator classification retained");
        }
        CommonConfig.active = new CommonConfig.Snapshot(true,false);
        // Cover below/above the vanilla 0.03 stop threshold, both signs, both axes and reverse values.
        for (RailShape shape : new RailShape[]{RailShape.NORTH_SOUTH,RailShape.EAST_WEST}) {
            for (boolean reverse : new boolean[]{false,true}) {
                BlockState state = oneway.defaultBlockState().setValue(PoweredRailBlock.SHAPE,shape)
                        .setValue(PoweredRailBlock.POWERED,false).setValue(OnewayRail.REVERSE,reverse);
                for (double speed : new double[]{0,0.001,0.02,0.029,0.03,0.031,0.1,0.4,0.8}) {
                    for (int sign : new int[]{-1,1}) {
                        Vec3 incoming = shape == RailShape.NORTH_SOUTH
                                ? new Vec3(0,0,sign*speed) : new Vec3(sign*speed,0,0);
                        AbstractMinecart cart = new AbstractMinecart();
                        cart.setDeltaMovement(incoming);
                        boolean brake = !(boolean) redirect.invoke(mixin,oneway,pos,state);
                        if (brake) cart.setDeltaMovement(speed < 0.03 ? Vec3.ZERO : incoming.multiply(0.5,0,0.5));
                        // Ordinary natural friction is shared; this is a source-based isolated model.
                        cart.setDeltaMovement(cart.getDeltaMovement().multiply(0.96,0,0.96));
                        int writes = cart.velocityWrites;
                        oneway.onMinecartPass(state,new Level(state),pos,cart);
                        Vec3 expected = incoming.multiply(0.96,0,0.96);
                        check(cart.getDeltaMovement().equals(expected), "Matches ordinary friction, no brake/1.2 multiplier");
                        check(cart.velocityWrites == writes, "Inactive callback does not overwrite motion");
                    }
                }
            }
        }
        System.out.println("PASS checks="+checks+"; modeledMotionCases=72; gameExecuted=false; mixinWeavingExecuted=false");
    }
}
