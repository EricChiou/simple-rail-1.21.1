package evidence.t010;

import com.mojang.serialization.MapCodec;
import java.util.List;
import java.util.UUID;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.registries.Registries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.tags.BlockTags;
import net.minecraft.tags.TagKey;
import net.minecraft.util.RandomSource;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.ItemInteractionResult;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.item.context.UseOnContext;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.PoweredRailBlock;
import net.minecraft.world.level.block.RailBlock;
import net.minecraft.world.level.block.SoundType;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.level.block.state.properties.EnumProperty;
import net.minecraft.world.level.block.state.properties.IntegerProperty;
import net.minecraft.world.level.block.state.properties.RailShape;
import net.minecraft.world.level.material.FluidState;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.Vec3;
import net.neoforged.neoforge.common.ItemAbility;
import net.neoforged.neoforge.common.ItemAbilities;

/** Compilation only: no mod entry, no registrations, no main; never loaded or instantiated. */
public final class T010Probe {
    static final BooleanProperty REVERSE=BooleanProperty.create("reverse");
    static final BooleanProperty NEED_POWER=BooleanProperty.create("need_power");
    static final BooleanProperty USE_POWER=BooleanProperty.create("use_power");
    static final IntegerProperty LEVEL=IntegerProperty.create("level",0,9);
    static final EnumProperty<Direction> DIRECTION=EnumProperty.create("direction",Direction.class);
    static final TagKey<Block> RAILS=TagKey.create(Registries.BLOCK,ResourceLocation.fromNamespaceAndPath("simplerail","rails"));
    static final TagKey<Block> MACHINES=TagKey.create(Registries.BLOCK,ResourceLocation.fromNamespaceAndPath("simplerail","machines"));
    static final TagKey<Item> WRENCH=TagKey.create(Registries.ITEM,ResourceLocation.fromNamespaceAndPath("simplerail","wrench"));
    static BlockBehaviour.Properties railProperties(){
        return BlockBehaviour.Properties.of().noCollission().strength(0.7F).sound(SoundType.METAL);
    }

    public static class FlatRailProbe extends RailBlock {
        static final MapCodec<RailBlock> CODEC=simpleCodec(FlatRailProbe::new);
        public FlatRailProbe(BlockBehaviour.Properties properties){super(properties);}
        @Override public MapCodec<RailBlock> codec(){return CODEC;}
        @Override public boolean canMakeSlopes(BlockState s,BlockGetter l,BlockPos p){return false;}
        @Override public boolean isFlexibleRail(BlockState s,BlockGetter l,BlockPos p){return false;}
        @Override public boolean isValidRailShape(RailShape shape){return shape==RailShape.NORTH_SOUTH || shape==RailShape.EAST_WEST;}
        @Override public boolean canEntityDestroy(BlockState s,BlockGetter l,BlockPos p,Entity e){return false;}
        @Override public float getRailMaxSpeed(BlockState s,Level l,BlockPos p,AbstractMinecart cart){return 0.8F;}
        @Override public RailShape getRailDirection(BlockState s,BlockGetter l,BlockPos p,AbstractMinecart cart){return s.getValue(SHAPE);}
        @Override public void onMinecartPass(BlockState s,Level l,BlockPos p,AbstractMinecart c){if(!l.isClientSide)cartOperations(l,p,c);}
        @Override public boolean onDestroyedByPlayer(BlockState s,Level l,BlockPos p,Player player,boolean harvest,FluidState fluid){
            return super.onDestroyedByPlayer(s,l,p,player,harvest,fluid);
        }
        @Override public void destroy(LevelAccessor l,BlockPos p,BlockState s){super.destroy(l,p,s);}
        @Override protected void onRemove(BlockState s,Level l,BlockPos p,BlockState replacement,boolean moving){
            if(!s.is(replacement.getBlock())){/* cleanup candidate; no actual cache */}
            super.onRemove(s,l,p,replacement,moving);
        }
    }

    /** Union of custom properties for signature compilation, NOT an ID's real StateDefinition. */
    public static class PoweredProbe extends PoweredRailBlock {
        static final MapCodec<PoweredRailBlock> CODEC=simpleCodec(PoweredProbe::new);
        public PoweredProbe(BlockBehaviour.Properties properties){
            super(properties,true); // same powered (not activator) choice as OLD
            registerDefaultState(defaultBlockState().setValue(DIRECTION,Direction.NORTH).setValue(LEVEL,0)
                .setValue(REVERSE,false).setValue(NEED_POWER,true).setValue(USE_POWER,false));
        }
        @Override public MapCodec<PoweredRailBlock> codec(){return CODEC;}
        @Override protected void createBlockStateDefinition(StateDefinition.Builder<Block,BlockState> b){
            super.createBlockStateDefinition(b);b.add(DIRECTION,LEVEL,REVERSE,NEED_POWER,USE_POWER);
        }
        @Override public boolean canMakeSlopes(BlockState s,BlockGetter l,BlockPos p){return false;}
        @Override public boolean canEntityDestroy(BlockState s,BlockGetter l,BlockPos p,Entity e){return false;}
        @Override public float getRailMaxSpeed(BlockState s,Level l,BlockPos p,AbstractMinecart c){return 0.8F;}
        @Override public void onMinecartPass(BlockState s,Level l,BlockPos p,AbstractMinecart c){
            if(l.isClientSide)return;
            boolean powered=s.getValue(POWERED);
            int level=s.getValue(LEVEL);
            if(!powered && level>0){c.setDeltaMovement(Vec3.ZERO);c.moveTo(p,c.getYRot(),c.getXRot());}
        }
        @Override protected void updateState(BlockState s,Level l,BlockPos p,Block neighbor){
            boolean before=s.getValue(POWERED);
            boolean direct=l.hasNeighborSignal(p);
            super.updateState(s,l,p,neighbor);
            boolean after=l.getBlockState(p).getValue(POWERED);
            // before/direct/after are distinct; no release algorithm is being implemented here.
        }
        @Override protected void onPlace(BlockState s,Level l,BlockPos p,BlockState old,boolean moving){super.onPlace(s,l,p,old,moving);}
        @Override public BlockState getStateForPlacement(BlockPlaceContext c){return super.getStateForPlacement(c);}
    }

    /** Machine hook signatures only; no block entity, menu or dispenser implementation. */
    public static class MachineProbe extends Block {
        static final MapCodec<MachineProbe> CODEC=simpleCodec(MachineProbe::new);
        public MachineProbe(BlockBehaviour.Properties properties){
            super(properties);
            registerDefaultState(defaultBlockState().setValue(LEVEL,0).setValue(BlockStateProperties.POWERED,false)
                .setValue(BlockStateProperties.FACING,Direction.NORTH).setValue(BlockStateProperties.TRIGGERED,false));
        }
        @Override public MapCodec<MachineProbe> codec(){return CODEC;}
        @Override protected void createBlockStateDefinition(StateDefinition.Builder<Block,BlockState> b){
            b.add(LEVEL,BlockStateProperties.POWERED,BlockStateProperties.FACING,BlockStateProperties.TRIGGERED);
        }
        @Override protected void neighborChanged(BlockState s,Level l,BlockPos p,Block neighbor,BlockPos from,boolean moving){
            if(!l.isClientSide && l.hasNeighborSignal(p)){/* server-only candidate */}
        }
        @Override protected void tick(BlockState s,ServerLevel l,BlockPos p,RandomSource random){l.scheduleTick(p,this,10);}
        @Override protected int getSignal(BlockState s,BlockGetter l,BlockPos p,Direction side){return s.getValue(LEVEL)>0 && s.getValue(BlockStateProperties.POWERED)?15:0;}
        @Override protected boolean isSignalSource(BlockState state){return true;}
        @Override protected ItemInteractionResult useItemOn(ItemStack stack,BlockState s,Level l,BlockPos p,Player player,InteractionHand hand,BlockHitResult hit){
            return stack.is(WRENCH)?ItemInteractionResult.SKIP_DEFAULT_BLOCK_INTERACTION:ItemInteractionResult.PASS_TO_DEFAULT_BLOCK_INTERACTION;
        }
        @Override protected InteractionResult useWithoutItem(BlockState s,Level l,BlockPos p,Player player,BlockHitResult hit){return InteractionResult.sidedSuccess(l.isClientSide);}
    }

    public static class WrenchProbe extends Item {
        public WrenchProbe(){super(new Item.Properties().stacksTo(1).fireResistant());}
        @Override public InteractionResult useOn(UseOnContext c){
            Level level=c.getLevel();if(level.isClientSide)return InteractionResult.SUCCESS;
            if(!(level instanceof ServerLevel server))return InteractionResult.PASS;
            BlockPos p=c.getClickedPos();Vec3 hit=c.getClickLocation();Direction horizontal=c.getHorizontalDirection();
            List<AbstractMinecart> carts=server.getEntitiesOfClass(AbstractMinecart.class,new AABB(p));
            BlockState s=server.getBlockState(p);
            if(s.is(RAILS) || s.is(MACHINES)){
                if(s.hasProperty(REVERSE))s=s.cycle(REVERSE);
                if(s.hasProperty(LEVEL))s=s.setValue(LEVEL,(s.getValue(LEVEL)+1)%10);
                if(s.hasProperty(DIRECTION) && s.getValue(DIRECTION).getAxis().isHorizontal())s=s.setValue(DIRECTION,s.getValue(DIRECTION).getClockWise());
                server.setBlock(p,s,Block.UPDATE_ALL);
            }
            Entity byId=server.getEntity(UUID.randomUUID()); // signature only; never run
            return InteractionResult.CONSUME;
        }
        @Override public InteractionResult onItemUseFirst(ItemStack stack,UseOnContext c){return InteractionResult.PASS;}
        @Override public boolean canPerformAction(ItemStack stack,ItemAbility ability){
            return ItemAbilities.DEFAULT_HOE_ACTIONS.contains(ability); // candidate capability, not adopted product behavior
        }
    }

    static void cartOperations(Level l,BlockPos p,AbstractMinecart c){
        Vec3 v=c.getDeltaMovement();Direction motion=c.getMotionDirection();
        c.setDeltaMovement(motion.getStepX()*0.4D,motion.getStepY()*0.4D,motion.getStepZ()*0.4D);
        c.moveTo(p,c.getYRot(),c.getXRot());
        c.moveTo(p.getX()+0.5D,p.getY(),p.getZ()+0.5D,c.getYRot(),c.getXRot());
        for(Entity passenger:List.copyOf(c.getPassengers())){passenger.stopRiding();passenger.setDeltaMovement(Vec3.ZERO);passenger.moveTo(p.getX(),p.getY(),p.getZ());}
        c.ejectPassengers();
        boolean rails=l.getBlockState(p).is(BlockTags.RAILS);
        boolean pickaxe=l.getBlockState(p).is(BlockTags.MINEABLE_WITH_PICKAXE);
        double cap=c.getMaxSpeedWithRail();boolean enabled=c.shouldDoRailFunctions();
        c.discard(); // remove/discard signature only; not a migrated deletion algorithm
    }
}
