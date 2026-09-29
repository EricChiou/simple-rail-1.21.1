package com.ericchiu.simplerail.mixin;

import com.ericchiu.simplerail.block.OnewayRail;
import net.minecraft.core.BlockPos;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.level.block.PoweredRailBlock;
import net.minecraft.world.level.block.state.BlockState;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Redirect;

@Mixin(AbstractMinecart.class)
public abstract class AbstractMinecartMixin {
    /**
     * Suppress the powered-rail brake classification only inside track movement.
     * The separate activator check in tick is untouched, as is powered acceleration.
     */
    @Redirect(
            method = "moveAlongTrack(Lnet/minecraft/core/BlockPos;Lnet/minecraft/world/level/block/state/BlockState;)V",
            at = @At(value = "INVOKE", target = "Lnet/minecraft/world/level/block/PoweredRailBlock;isActivatorRail()Z"),
            require = 1, expect = 1, allow = 1
    )
    private boolean simplerail$coastOnUnpoweredOnewayRail(
            PoweredRailBlock rail, BlockPos pos, BlockState state) {
        return rail.isActivatorRail()
                || (rail instanceof OnewayRail && !state.getValue(PoweredRailBlock.POWERED));
    }
}
