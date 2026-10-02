package com.ericchiu.simplerail.item;

import com.ericchiu.simplerail.block.TimerHoldingRail;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.context.UseOnContext;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.BooleanProperty;

/** Calls the production Wrench against explicit world/state test doubles. */
public final class TimerWrenchRegressionTest {
    private static final BlockPos POS = new BlockPos(10, 64, 10);
    private static final Wrench WRENCH = new Wrench(new Item.Properties().stacksTo(1));
    private static int checks;

    public static void main(String[] args) {
        TimerHoldingRail timer = new TimerHoldingRail();
        BooleanProperty powered = BooleanProperty.create("powered");
        for (Direction initial : new Direction[] {Direction.NORTH, Direction.EAST, Direction.SOUTH, Direction.WEST}) {
            for (int oldLevel = 0; oldLevel <= 9; oldLevel++) {
                BlockState state = timer.defaultBlockState().setValue(TimerHoldingRail.LEVEL, oldLevel)
                        .setValue(TimerHoldingRail.DIRECTION, initial).setValue(powered, true);
                ServerLevel world = click(state);
                check(world.state.getValue(TimerHoldingRail.LEVEL) == (oldLevel + 1) % 10,
                        "Level must advance after direction was recorded by a cart");
                check(world.state.getValue(TimerHoldingRail.DIRECTION) == initial.getClockWise(),
                        "Direction still rotates");
                check(world.state.getValue(powered) && world.writes == 1 && world.lastFlags == Block.UPDATE_ALL,
                        "Preserve other properties with one update");
            }
        }

        for (Direction vertical : new Direction[] {Direction.UP, Direction.DOWN}) {
            BlockState state = timer.defaultBlockState().setValue(TimerHoldingRail.LEVEL, 9)
                    .setValue(TimerHoldingRail.DIRECTION, vertical);
            ServerLevel world = click(state);
            check(world.state.getValue(TimerHoldingRail.LEVEL) == 0 &&
                    world.state.getValue(TimerHoldingRail.DIRECTION) == vertical && world.writes == 1,
                    "Vertical direction remains unchanged while level wraps");
        }

        BlockState state = timer.defaultBlockState().setValue(TimerHoldingRail.LEVEL, 4)
                .setValue(TimerHoldingRail.DIRECTION, Direction.NORTH);
        ServerLevel world = new ServerLevel(state);
        AbstractMinecart cart = new AbstractMinecart();
        cart.x = POS.x() + 0.5;
        cart.y = POS.y();
        cart.z = POS.z() + 0.5;
        world.carts.add(cart);
        WRENCH.useOn(new UseOnContext(world, POS, new ItemStack(), false));
        check(world.writes == 0 && world.state == state, "Occupied rail remains protected");

        System.out.println("PASS checks=" + checks + "; actualProductionWrench=true; MinecraftExecuted=false");
    }

    private static ServerLevel click(BlockState state) {
        ServerLevel world = new ServerLevel(state);
        ItemStack stack = new ItemStack();
        check(WRENCH.useOn(new UseOnContext(world, POS, stack, false)) == InteractionResult.CONSUME,
                "Server action consumed");
        check(stack.count == 1 && stack.writes == 0, "Wrench remains reusable");
        return world;
    }

    private static void check(boolean result, String message) {
        checks++;
        if (!result) {
            throw new AssertionError(message);
        }
    }
}
