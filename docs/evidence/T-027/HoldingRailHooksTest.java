package com.ericchiu.simplerail.block;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.PoweredRailBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.Vec3;

/** Tests the real hook source with explicitly isolated doubles, not a Minecraft run. */
public final class HoldingRailHooksTest {
    private static int checks;
    private static final BlockPos POS = new BlockPos(-17, 65, 23);
    private static void check(boolean value, String label) {
        checks++;
        if (!value) throw new AssertionError(label);
    }
    private static AbstractMinecart cart(Direction direction) {
        AbstractMinecart cart = new AbstractMinecart();
        cart.x = -16.5; cart.y = 65; cart.z = 23.5; cart.heading = direction;
        cart.setDeltaMovement(direction.getStepX() * 0.7, direction.getStepY() * 0.7, direction.getStepZ() * 0.7);
        return cart;
    }
    public static void main(String[] args) {
        HoldingRail rail = new HoldingRail(new BlockBehaviour.Properties());
        check(rail.defaultBlockState().getValue(HoldingRail.DIRECTION) == Direction.NORTH, "Default NORTH");
        check(!rail.defaultBlockState().getValue(PoweredRailBlock.POWERED), "Default unpowered");
        check(rail.builder.properties.contains(HoldingRail.DIRECTION) && rail.builder.properties.contains(PoweredRailBlock.POWERED), "Direction plus parent properties");

        for (Direction direction : Direction.values()) {
            Level level = new Level(rail.defaultBlockState());
            AbstractMinecart first = cart(direction);
            AbstractMinecart second = cart(direction);
            AbstractMinecart outside = cart(direction); outside.x += 3;
            level.carts.add(first); level.carts.add(second); level.carts.add(outside);
            rail.onMinecartPass(level.state, level, POS, first);
            check(level.state.getValue(HoldingRail.DIRECTION) == direction, "Capture direction " + direction);
            check(first.getDeltaMovement().equals(Vec3.ZERO), "Stop " + direction);
            check(first.x == -16.5 && first.y == 65 && first.z == 23.5, "Bottom center including negative coordinate");
            check(first.yaw == 35 && first.pitch == 12, "Keep rotation");
            check(level.lastFlags == Block.UPDATE_ALL, "Update flag 3");
            int writes = level.writes;
            rail.onMinecartPass(level.state, level, POS, first);
            check(level.writes == writes && level.state.getValue(HoldingRail.DIRECTION) == direction, "Stationary pass keeps stored direction");
            level.signal = true;
            // Simulate nested neighbor notification after parent writes POWERED.
            level.notification = () -> rail.updateState(level.state, level, POS, new Block());
            rail.updateState(level.state, level, POS, new Block());
            Vec3 expected = new Vec3(direction.getStepX() * 0.4, direction.getStepY() * 0.4, direction.getStepZ() * 0.4);
            check(first.getDeltaMovement().equals(expected) && second.getDeltaMovement().equals(expected), "Rising edge releases all local carts");
            check(outside.getDeltaMovement().equals(new Vec3(direction.getStepX() * 0.7, direction.getStepY() * 0.7, direction.getStepZ() * 0.7)), "Outside AABB untouched");
            check(level.queries == 1, "Reentrant notification causes no duplicate release");
            int velocityWrites = first.velocityWrites;
            rail.updateState(level.state, level, POS, new Block());
            rail.onMinecartPass(level.state, level, POS, first);
            check(first.velocityWrites == velocityWrites && level.queries == 1, "Stable power does not reset momentum");
            level.signal = false;
            rail.updateState(level.state, level, POS, new Block());
            check(level.queries == 1 && first.velocityWrites == velocityWrites, "Falling edge does not launch");
            rail.onMinecartPass(level.state, level, POS, first);
            check(first.getDeltaMovement().equals(Vec3.ZERO), "Loss of power stops on pass");
            level.signal = true;
            rail.updateState(level.state, level, POS, new Block());
            check(level.queries == 2 && first.getDeltaMovement().equals(expected), "Second rising edge releases again");
        }
        Level client = new Level(rail.defaultBlockState()); client.isClientSide = true; client.signal = true;
        AbstractMinecart clientCart = cart(Direction.EAST);
        rail.onMinecartPass(client.state, client, POS, clientCart);
        rail.updateState(client.state, client, POS, new Block());
        check(client.writes == 0 && client.queries == 0 && client.parentCalls == 0 && clientCart.moves == 0, "Client has no mutations");
        check(clientCart.getDeltaMovement().equals(new Vec3(0.7, 0, 0)), "Client momentum unchanged");
        Level replaced = new Level(rail.defaultBlockState()); replaced.signal = true; replaced.replaceOnParent = true;
        rail.updateState(replaced.state, replaced, POS, new Block());
        check(replaced.queries == 0, "Removed/replaced block never releases");
        Level empty = new Level(rail.defaultBlockState()); empty.signal = true;
        rail.updateState(empty.state, empty, POS, new Block());
        check(empty.state.getValue(PoweredRailBlock.POWERED) && empty.queries == 1, "Empty rail power update safe");
        System.out.println("PASS checks=" + checks + "; directions=6; MinecraftExecuted=false; isolatedDoubles=true");
    }
}
