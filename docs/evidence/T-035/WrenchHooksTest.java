package com.ericchiu.simplerail.item;

import com.ericchiu.simplerail.registry.ModTags;
import net.minecraft.core.*;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.item.*;
import net.minecraft.world.item.context.UseOnContext;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.*;
import net.neoforged.neoforge.common.*;

/** Actual hook against isolated fixtures, including source-inferred U-09 behavior. */
public final class WrenchHooksTest {
    private static int checks,cases;
    private static final BlockPos POS=new BlockPos(-5,64,12);
    private static final Wrench WRENCH=new Wrench(new Item.Properties().stacksTo(1));
    private static void check(boolean pass,String message){checks++;if(!pass)throw new AssertionError(message);}
    private static BlockState fixture(boolean rail,boolean machine){Block block=new Block();if(rail)block.tags.add(ModTags.RAILS);if(machine)block.tags.add(ModTags.MACHINES);return block.defaultBlockState();}
    private static ServerLevel use(BlockState state,boolean occupied,boolean nullPlayer){
        cases++;ServerLevel level=new ServerLevel(state);
        if(occupied){AbstractMinecart cart=new AbstractMinecart();cart.x=POS.x()+.5;cart.y=POS.y();cart.z=POS.z()+.5;level.carts.add(cart);}
        ItemStack stack=new ItemStack();InteractionResult result=WRENCH.useOn(new UseOnContext(level,POS,stack,nullPlayer));
        check(result==InteractionResult.CONSUME,"OLD server consume result");check(stack.count==1&&stack.writes==0,"No item consumption/damage");
        check(level.writes==0||level.lastFlags==Block.UPDATE_ALL,"Update flag 3");return level;
    }
    public static void main(String[] args){
        check(WRENCH.properties.maxStack==1,"Single stack property in supplied factory contract");
        for(boolean rail:new boolean[]{false,true})for(boolean machine:new boolean[]{false,true})
            for(boolean occupied:new boolean[]{false,true})for(boolean nullPlayer:new boolean[]{false,true}){
                boolean railAllowed=rail&&!occupied;
                BooleanProperty reverse=BooleanProperty.create("reverse");BlockState state=fixture(rail,machine).setValue(reverse,false);
                ServerLevel level=use(state,occupied,nullPlayer);
                check(level.state.getValue(reverse)==railAllowed,"Reverse rail-only and empty clicked cell");
                check(level.queries==(rail?1:0),"Cart query only for rails");
                IntegerProperty counter=IntegerProperty.create("level",0,9);
                for(int value=0;value<=9;value++){
                    state=fixture(rail,machine).setValue(counter,value);level=use(state,occupied,nullPlayer);
                    check(level.state.getValue(counter)==((railAllowed||machine)?(value+1)%10:value),"Full level cycle 9 to 0; machine ignores carts");
                }
                for(String name:new String[]{"direction","facing"}){
                    EnumProperty<Direction> direction=EnumProperty.create(name,Direction.class);
                    for(Direction current:Direction.values()){
                        state=fixture(rail,machine).setValue(direction,current);level=use(state,occupied,nullPlayer);
                        boolean enabled=name.equals("direction")?railAllowed:machine;
                        Direction expected=enabled&&current.getAxis().isHorizontal()?current.getClockWise():current;
                        check(level.state.getValue(direction)==expected,"Four-way clockwise; up/down untouched");
                    }
                }
                state=fixture(rail,machine);level=use(state,occupied,nullPlayer);
                check(level.writes==0,"Absent properties safe, no world write");
            }
        // Regression oracle for OLD same-initial-state writes: pending U-09 decision, not claimed a fix.
        IntegerProperty counter=IntegerProperty.create("level",0,9);EnumProperty<Direction> direction=EnumProperty.create("direction",Direction.class);
        BooleanProperty reverse=BooleanProperty.create("reverse");
        BlockState state=fixture(true,false).setValue(reverse,false).setValue(counter,9).setValue(direction,Direction.NORTH);
        ServerLevel level=use(state,false,false);
        check(!level.state.getValue(reverse)&&level.state.getValue(counter)==9&&level.state.getValue(direction)==Direction.EAST&&level.writes==3,"U-09 source-compatible last direction overwrites reverse/level");
        EnumProperty<Direction> facing=EnumProperty.create("facing",Direction.class);
        state=fixture(false,true).setValue(facing,Direction.NORTH).setValue(counter,9);level=use(state,true,false);
        check(level.state.getValue(facing)==Direction.NORTH&&level.state.getValue(counter)==0&&level.writes==2,"U-09 machine level overwrites facing");
        state=fixture(true,false).setValue(counter,9).setValue(direction,Direction.UP);level=use(state,false,false);
        check(level.state.getValue(counter)==0&&level.state.getValue(direction)==Direction.UP,"Vertical no-op does not overwrite prior level write");
        // Name alone must not cause an invalid typed property access or unsupported counter range.
        state=fixture(true,true).setValue(IntegerProperty.create("reverse",0,1),0).setValue(IntegerProperty.create("level",0,15),15)
                .setValue(EnumProperty.create("direction",RailShape.class),RailShape.NORTH_SOUTH)
                .setValue(BooleanProperty.create("facing"),true);
        level=use(state,false,true);check(level.writes==0,"Wrong types/range safely skipped");
        state=fixture(true,false).setValue(BooleanProperty.create("reverse"),false);
        Level client=new Level(state);client.isClientSide=true;
        check(WRENCH.useOn(new UseOnContext(client,POS,new ItemStack(),true))==InteractionResult.SUCCESS&&client.writes==0&&client.queries==0,"Client returns success, no reads/cart query/write");
        Level invalid=new Level(state);
        check(WRENCH.useOn(new UseOnContext(invalid,POS,new ItemStack(),true))==InteractionResult.PASS&&invalid.writes==0,"Non-ServerLevel safe return");
        ServerLevel neighbor=new ServerLevel(state);AbstractMinecart cart=new AbstractMinecart();cart.x=POS.x()+2;cart.y=POS.y();cart.z=POS.z()+.5;neighbor.carts.add(cart);
        WRENCH.useOn(new UseOnContext(neighbor,POS,new ItemStack(),true));
        check(neighbor.writes==1&&neighbor.state.getValue((BooleanProperty)state.getBlock().getStateDefinition().getProperty("reverse")),"Unrelated distant cart does not block");
        // Near-edge bounding-box overlap is sufficient; center need not lie in the cell.
        neighbor=new ServerLevel(state);cart=new AbstractMinecart();cart.x=POS.x()+1.2;cart.y=POS.y();cart.z=POS.z()+.5;neighbor.carts.add(cart);
        WRENCH.useOn(new UseOnContext(neighbor,POS,new ItemStack(),true));check(neighbor.writes==0,"Bounding-box overlap blocks rail edit in fixture geometry");
        ItemStack stack=new ItemStack();check(WRENCH.canPerformAction(stack,ItemAbilities.HOE_DIG)&&WRENCH.canPerformAction(stack,ItemAbilities.HOE_TILL),"HOE abilities retained");
        check(!WRENCH.canPerformAction(stack,new ItemAbility("pickaxe_dig")),"No extra abilities");
        System.out.println("PASS checks="+checks+"; cases="+cases+"; U09=source-compatible/pending; MinecraftExecuted=false");
    }
}
