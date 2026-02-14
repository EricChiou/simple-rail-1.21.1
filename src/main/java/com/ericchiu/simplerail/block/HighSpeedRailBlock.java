package com.ericchiu.simplerail.block;

import com.ericchiu.simplerail.config.RailConfig;

import net.minecraft.core.BlockPos;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.PoweredRailBlock;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.Vec3;

public class HighSpeedRailBlock extends PoweredRailBlock {

  public HighSpeedRailBlock(Properties properties) {
    super(properties, true);
  }

  @Override
  public float getRailMaxSpeed(BlockState state, Level level, BlockPos pos, AbstractMinecart cart) {
    return RailConfig.SERVER.highSpeedRailMaxSpeed.get().floatValue();
  }

  @Override
  public void onMinecartPass(BlockState state, Level level, BlockPos pos, AbstractMinecart cart) {
    // 若軌道未充能，則不進行加速 (保留原版煞車行為)
    if (!state.getValue(POWERED)) {
      super.onMinecartPass(state, level, pos, cart);
      return;
    }

    // 取得當前速度向量
    Vec3 motion = cart.getDeltaMovement();
    double currentSpeed = motion.horizontalDistance();

    // 如果速度非常小，則不進行加速 (避免在靜止或極慢時施加推力導致不自然的行為)
    if (currentSpeed < 0.01) {
      super.onMinecartPass(state, level, pos, cart);
      return;
    }

    // 取得最大速度設定
    double maxSpeed = RailConfig.SERVER.highSpeedRailMaxSpeed.get();

    // 如果當前速度已達最大速度，則不進行加速
    if (currentSpeed >= maxSpeed)
      return;

    // 取得加速度設定
    double accel = RailConfig.SERVER.highSpeedRailAcceleration.get();

    // 如果當前速度小於最大速度，則進行加速
    cart.setDeltaMovement(motion.add(motion.normalize().scale(accel)));
  }
}