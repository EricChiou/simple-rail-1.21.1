package com.ericchiu.simplerail.block;

import com.ericchiu.simplerail.block.base.BasePoweredRail;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.BaseRailBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.RailShape;

/** Actual HighSpeedRail hook with explicit local doubles; no game or physics engine. */
public final class HighSpeedReviewTest {
    private static int checks;
    private static void check(boolean pass, String label) {
        checks++;
        if (!pass) throw new AssertionError(label);
    }
    private static RailShape slope(Direction d) {
        return switch (d) {
            case EAST -> RailShape.ASCENDING_EAST;
            case WEST -> RailShape.ASCENDING_WEST;
            case NORTH -> RailShape.ASCENDING_NORTH;
            case SOUTH -> RailShape.ASCENDING_SOUTH;
            default -> throw new IllegalArgumentException();
        };
    }
    public static void main(String[] args) {
        HighSpeedRail rail = new HighSpeedRail(new BlockBehaviour.Properties());
        BaseRailBlock neighbor = new BaseRailBlock();
        for (Direction dir : new Direction[] {Direction.EAST, Direction.WEST, Direction.NORTH, Direction.SOUTH}) {
            boolean alongX = dir.x != 0;
            boolean positive = dir.x + dir.z > 0;
            RailShape flat = alongX ? RailShape.EAST_WEST : RailShape.NORTH_SOUTH;
            for (int origin : new int[] {0, -101}) {
                BlockPos pos = new BlockPos(origin, 65, origin);
                for (boolean currentAscent : new boolean[] {false, true}) {
                    BlockState state = new BlockState(rail, currentAscent ? slope(dir) : flat, true);
                    BlockPos next = currentAscent ? pos.relative(dir).above() : pos.relative(dir);
                    AbstractMinecart cart = new AbstractMinecart();
                    cart.x = origin + (alongX ? (positive ? 0.8 : 0.2) : 0.5);
                    cart.z = origin + (alongX ? 0.5 : (positive ? 0.8 : 0.2));
                    cart.y = 65 + (currentAscent ? 1 : 0);
                    cart.motion = new AbstractMinecart.Vec3(dir.x * 0.8, 0, dir.z * 0.8);
                    Level level = new Level();
                    level.blocks.put(next, new BlockState(neighbor, slope(dir), true));
                    check(rail.canMakeSlopes(state, level, pos), "high-speed exception");
                    for (float config : new float[] {0.4f, 0.8f, 2f}) {
                        BasePoweredRail.configured = config;
                        float actual = rail.getRailMaxSpeed(state, level, pos, cart);
                        // This setup has support face 1.2 away in every signed axis.
                        double ideal = Math.min(config, 1.2 - (double) 0.98f / 2 - 1e-6);
                        check(Math.abs(actual - ideal) < 2e-7, "axis/sign/negative-coordinate/ascent cap");
                        check(actual >= 0 && actual <= config, "configured maximum retained");
                        check(actual + (double) 0.98f / 2 < 1.2, "support clearance");
                    }
                    BasePoweredRail.configured = 0.8f;
                    check(rail.getRailMaxSpeed(state, level, pos, null) == 0.8f, "null query");
                    cart.motion = new AbstractMinecart.Vec3(0, 0, 0);
                    check(rail.getRailMaxSpeed(state, level, pos, cart) == 0.8f, "stationary query");
                    cart.motion = new AbstractMinecart.Vec3(dir.x * 0.8, 0, dir.z * 0.8);
                    cart.y = next.y() + 1;
                    check(rail.getRailMaxSpeed(state, level, pos, cart) == 0.8f, "already raised");
                    cart.y--;
                    level.blocks.put(next, new BlockState(neighbor, flat, true));
                    check(rail.getRailMaxSpeed(state, level, pos, cart) == 0.8f, "flat neighbor");
                    level.blocks.put(next, new BlockState(neighbor, alongX ? RailShape.ASCENDING_NORTH : RailShape.ASCENDING_EAST, true));
                    check(rail.getRailMaxSpeed(state, level, pos, cart) == 0.8f, "perpendicular slope");
                    level.blocks.put(next, new BlockState(neighbor, slope(dir), false));
                    check(rail.getRailMaxSpeed(state, level, pos, cart) == 0.8f, "untagged rail");
                    level.blocks.put(next, new BlockState(new Object(), slope(dir), true));
                    check(rail.getRailMaxSpeed(state, level, pos, cart) == 0.8f, "tag alone cannot trigger cast");
                    level.blocks.clear();
                    check(rail.getRailMaxSpeed(state, level, pos, cart) == 0.8f, "no neighbor");
                }
            }
        }
        System.out.println("PASS checks=" + checks + "; actualHighSpeedHook=true; explicitDoubles=true; minecraftExecuted=false");
    }
}
