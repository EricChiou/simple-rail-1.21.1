package net.minecraft.world.item;
import net.minecraft.world.InteractionResult;import net.minecraft.world.item.context.UseOnContext;import net.neoforged.neoforge.common.ItemAbility;
public class Item{public final Properties properties;public Item(Properties properties){this.properties=properties;}public InteractionResult useOn(UseOnContext context){return InteractionResult.PASS;}public boolean canPerformAction(ItemStack stack,ItemAbility ability){return false;}public static class Properties{public int maxStack=64;public Properties stacksTo(int size){maxStack=size;return this;}}}
