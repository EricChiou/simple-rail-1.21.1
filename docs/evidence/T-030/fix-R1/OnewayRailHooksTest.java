package com.ericchiu.simplerail.block;

import com.ericchiu.simplerail.config.CommonConfig;
import net.minecraft.core.BlockPos;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.PoweredRailBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.RailShape;
import net.minecraft.world.phys.Vec3;

/** Actual production hook source with local doubles; no Minecraft runtime. */
public final class OnewayRailHooksTest {
    private static int checks;
    private static int rows;
    private static final BlockPos POS = new BlockPos(-5, 65, 12);
    private static final boolean[] FLAGS = {false, true};
    private static void check(boolean pass, String message) {
        checks++;
        if (!pass) throw new AssertionError(message);
    }
    private static boolean same(Vec3 first, Vec3 second) {
        return first.x() == second.x() && first.y() == second.y() && first.z() == second.z();
    }
    public static void main(String[] args) {
        CommonConfig.active = null;
        OnewayRail rail = new OnewayRail(new BlockBehaviour.Properties());
        check(CommonConfig.reads == 0, "Construction never reads unloaded config");
        check(!rail.defaultBlockState().getValue(OnewayRail.REVERSE)
                && rail.defaultBlockState().getValue(OnewayRail.NEED_POWER)
                && !rail.defaultBlockState().getValue(OnewayRail.USE_POWER), "Stable constructor defaults");
        check(rail.builder.properties.contains(OnewayRail.REVERSE)
                && rail.builder.properties.contains(OnewayRail.NEED_POWER)
                && rail.builder.properties.contains(OnewayRail.USE_POWER), "All custom state fields defined");

        Vec3[] incoming = {new Vec3(0.7,0,0), new Vec3(-0.7,0,0), new Vec3(0,0,0.7),
                new Vec3(0,0,-0.7), Vec3.ZERO, new Vec3(0.2,0.1,-0.3)};
        for (RailShape shape : new RailShape[]{RailShape.NORTH_SOUTH, RailShape.EAST_WEST}) {
            for (boolean reverse : FLAGS) for (boolean powered : FLAGS)
                for (boolean need : FLAGS) for (boolean use : FLAGS) {
                    rows++;
                    CommonConfig.active = new CommonConfig.Snapshot(need, use);
                    // Frozen four-vector oracle from OLD goForward/goReverse source.
                    Vec3 directed = shape == RailShape.NORTH_SOUTH
                            ? (reverse ? new Vec3(0,0,0.4) : new Vec3(0,0,-0.4))
                            : (reverse ? new Vec3(-0.4,0,0) : new Vec3(0.4,0,0));
                    boolean passive = need && !use && !powered;
                    // Deliberately disagreeing stored flags prove gameplay uses the current snapshot.
                    for (boolean storedNeed : FLAGS) for (boolean storedUse : FLAGS) for (Vec3 input : incoming) {
                        BlockState state = rail.defaultBlockState().setValue(PoweredRailBlock.SHAPE, shape)
                                .setValue(PoweredRailBlock.POWERED, powered).setValue(OnewayRail.REVERSE, reverse)
                                .setValue(OnewayRail.NEED_POWER, storedNeed).setValue(OnewayRail.USE_POWER, storedUse);
                        Level level = new Level(state);
                        AbstractMinecart cart = new AbstractMinecart(); cart.setDeltaMovement(input);
                        int writes = cart.velocityWrites; int reads = CommonConfig.reads;
                        rail.onMinecartPass(state, level, POS, cart);
                        Vec3 expected = passive ? input : directed;
                        check(same(cart.getDeltaMovement(), expected), "Branch/direction vector for row " + rows);
                        check(CommonConfig.reads == reads+1, "Exactly one snapshot per operation");
                        check(level.writes == 0 && cart.moves == 0, "Pass never changes world state/position");
                        check(cart.velocityWrites == writes + (passive ? 0 : 1), "All passive vectors are untouched");
                    }
                }
        }
        check(rows == 32, "All 32 flat shape/reverse/power/config rows");

        for (boolean need : FLAGS) for (boolean use : FLAGS) {
            CommonConfig.active = new CommonConfig.Snapshot(need, use);
            BlockState initial = rail.defaultBlockState().setValue(OnewayRail.REVERSE,true)
                    .setValue(PoweredRailBlock.SHAPE,RailShape.EAST_WEST);
            Level level = new Level(initial);
            int reads = CommonConfig.reads;
            rail.onPlace(initial, level, POS, new Block().defaultBlockState(), false);
            check(level.state.getValue(OnewayRail.NEED_POWER) == need
                    && level.state.getValue(OnewayRail.USE_POWER) == use, "Placement forwards loaded fields to writing parent");
            check(level.state.getValue(OnewayRail.REVERSE)
                    && level.state.getValue(PoweredRailBlock.SHAPE) == RailShape.EAST_WEST, "Placement keeps reverse and shape");
            check(CommonConfig.reads == reads+1 && level.lastFlags == 3, "Placement uses one snapshot / parent update");
            BlockState stored = level.state;
            CommonConfig.active = new CommonConfig.Snapshot(!need,!use);
            rail.onPlace(stored, level, POS, stored, false);
            check(level.state == stored && CommonConfig.reads == reads+1, "Same block change/reload does not reproject state");
            AbstractMinecart cart = new AbstractMinecart(); cart.setDeltaMovement(new Vec3(0,0,0.7));
            rail.onMinecartPass(stored, level, POS, cart);
            Vec3 expected = !need && use ? new Vec3(0,0,0.7) : new Vec3(-0.4,0,0);
            check(same(cart.getDeltaMovement(),expected), "Reload changes callback from fresh snapshot despite stored flags");
        }
        CommonConfig.active = null;
        Level client = new Level(rail.defaultBlockState()); client.isClientSide = true;
        AbstractMinecart cart = new AbstractMinecart(); cart.setDeltaMovement(new Vec3(0.7,0,0));
        int reads = CommonConfig.reads;
        rail.onMinecartPass(client.state, client, POS, cart);
        rail.onPlace(client.state, client, POS, new Block().defaultBlockState(), false);
        check(CommonConfig.reads == reads && client.writes == 0 && same(cart.getDeltaMovement(),new Vec3(0.7,0,0)), "Client doesn't read config or mutate gameplay");
        System.out.println("PASS checks="+checks+"; truthRows="+rows+"; gameExecuted=false; isolatedDoubles=true");
    }
}
