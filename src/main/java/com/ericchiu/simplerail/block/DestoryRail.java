package com.ericchiu.simplerail.block;

import com.ericchiu.simplerail.block.base.BasePoweredRail;
import com.ericchiu.simplerail.config.CommonConfig;
import com.mojang.serialization.MapCodec;
import net.minecraft.core.BlockPos;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.PoweredRailBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BooleanProperty;

/** Historical spelling and ordinary minecart removal; consist deletion belongs to T-061. */
public final class DestoryRail extends BasePoweredRail {
    public static final MapCodec<PoweredRailBlock> CODEC = simpleCodec(DestoryRail::new);
    public static final BooleanProperty NEED_POWER = BooleanProperty.create("need_power");

    public DestoryRail(BlockBehaviour.Properties properties) {
        super(properties);
        // Registry construction precedes config loading; placement projects loaded values.
        registerDefaultState(defaultBlockState().setValue(NEED_POWER, false));
    }

    @Override
    public MapCodec<PoweredRailBlock> codec() {
        return CODEC;
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        super.createBlockStateDefinition(builder);
        builder.add(NEED_POWER);
    }

    @Override
    public void onMinecartPass(BlockState state, Level level, BlockPos pos, AbstractMinecart cart) {
        if (!(level instanceof ServerLevel serverLevel) || cart.isRemoved()) {
            return;
        }
        CommonConfig.Snapshot config = CommonConfig.current();
        if (config.destoryNeedPower() && !state.getValue(POWERED)) {
            return;
        }

        // discard preserves vanilla removal hooks (including container contents), not damage/drop logic.
        cart.discard();
        double x = pos.getX() + 0.5D;
        double y = pos.getY() + 0.75D;
        double z = pos.getZ() + 0.5D;
        serverLevel.sendParticles(ParticleTypes.LARGE_SMOKE, x, y, z, 1, 0.0D, 0.0D, 0.0D, 0.0D);
        serverLevel.playSound(null, x, y, z, SoundEvents.GENERIC_BURN, SoundSource.BLOCKS, 4.0F, 4.0F);
    }

    @Override
    protected void onPlace(BlockState state, Level level, BlockPos pos, BlockState oldState, boolean moving) {
        if (!level.isClientSide && !oldState.is(this)) {
            state = state.setValue(NEED_POWER, CommonConfig.current().destoryNeedPower());
        }
        super.onPlace(state, level, pos, oldState, moving);
    }
}
