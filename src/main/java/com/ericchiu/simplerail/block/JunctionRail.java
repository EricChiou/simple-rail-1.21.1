package com.ericchiu.simplerail.block;

import com.ericchiu.simplerail.block.base.BaseRail;
import com.ericchiu.simplerail.blockentity.JunctionRailBlockEntity;
import java.util.UUID;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.EntityBlock;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.RailShape;
import net.minecraft.world.phys.Vec3;

/** Shared two-callback passage; each placed rail owns its pending carts. */
public abstract class JunctionRail extends BaseRail implements EntityBlock {
    protected JunctionRail(BlockBehaviour.Properties properties) {
        super(properties);
    }

    protected abstract JunctionRoute.Kind kind();

    protected JunctionRoute.Cardinal route(BlockState state, JunctionRoute.Cardinal incoming) {
        return JunctionRoute.destination(kind(), incoming, incoming, false);
    }

    @Override
    public boolean isStraight() {
        return true;
    }

    @Override
    public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return new JunctionRailBlockEntity(pos, state);
    }

    @Override
    public void onMinecartPass(BlockState state, Level level, BlockPos pos, AbstractMinecart cart) {
        if (!(level instanceof ServerLevel server) || cart.isRemoved()
                || !(server.getBlockEntity(pos) instanceof JunctionRailBlockEntity transit)) return;

        UUID id = cart.getUUID();
        JunctionRailBlockEntity.Passage pending = transit.take(id);
        if (pending != null) {
            Direction direction = direction(pending.direction());
            BlockPos target = pending.destination();
            cart.moveTo(target, pending.yRot(), pending.xRot());
            cart.setDeltaMovement(direction.getStepX() * pending.speed(),
                    direction.getStepY(), direction.getStepZ() * pending.speed());
            return;
        }

        Vec3 motion = cart.getDeltaMovement();
        if (motion.x == 0.0D && motion.z == 0.0D) return;
        JunctionRoute.Cardinal incoming = cardinal(cart.getMotionDirection());
        if (incoming == null) return;
        JunctionRoute.Cardinal output = route(state, incoming);
        Direction destination = direction(output);
        double speed = Math.max(Math.abs(motion.x), Math.abs(motion.z));
        transit.put(id, new JunctionRailBlockEntity.Passage(output, pos.relative(destination),
                speed, cart.getYRot(), cart.getXRot()));
        RailShape axis = destination.getAxis() == Direction.Axis.X
                ? RailShape.EAST_WEST : RailShape.NORTH_SOUTH;
        server.setBlock(pos, state.setValue(SHAPE, axis), Block.UPDATE_ALL);
        cart.setDeltaMovement(Vec3.ZERO);
        cart.moveTo(pos, cart.getYRot(), cart.getXRot());
    }

    protected static JunctionRoute.Cardinal cardinal(Direction direction) {
        return switch (direction) {
            case EAST -> JunctionRoute.Cardinal.EAST;
            case WEST -> JunctionRoute.Cardinal.WEST;
            case NORTH -> JunctionRoute.Cardinal.NORTH;
            case SOUTH -> JunctionRoute.Cardinal.SOUTH;
            default -> null;
        };
    }

    private static Direction direction(JunctionRoute.Cardinal cardinal) {
        return switch (cardinal) {
            case EAST -> Direction.EAST;
            case WEST -> Direction.WEST;
            case NORTH -> Direction.NORTH;
            case SOUTH -> Direction.SOUTH;
        };
    }
}
