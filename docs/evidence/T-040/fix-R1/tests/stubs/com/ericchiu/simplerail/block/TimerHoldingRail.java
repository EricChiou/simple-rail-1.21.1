package com.ericchiu.simplerail.block;

import com.ericchiu.simplerail.registry.ModTags;
import net.minecraft.core.Direction;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.properties.EnumProperty;
import net.minecraft.world.level.block.state.properties.IntegerProperty;

/** Type-only fixture; NEW build compiles the real TimerHoldingRail separately. */
public final class TimerHoldingRail extends Block {
    public static final IntegerProperty LEVEL = IntegerProperty.create("level", 0, 9);
    public static final EnumProperty<Direction> DIRECTION = EnumProperty.create("direction", Direction.class);

    public TimerHoldingRail() {
        tags.add(ModTags.RAILS);
        registerDefaultState(defaultBlockState().setValue(LEVEL, 0).setValue(DIRECTION, Direction.DOWN));
    }
}
