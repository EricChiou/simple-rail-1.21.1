package net.minecraft.world.level.block.state;
import java.util.*;import net.minecraft.world.level.block.state.properties.Property;
public class StateDefinition {public static class Builder<B,S>{public final List<Property<?>> properties=new ArrayList<>();public void add(Property<?>... p){properties.addAll(Arrays.asList(p));}}}