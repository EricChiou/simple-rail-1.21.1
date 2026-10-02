package net.minecraft.world.level.block.state.properties;
import java.util.*;
public class Property<T>{public final String name;protected Class<T> type;protected Collection<T> possible=List.of();public Property(String name){this.name=name;}public Class<T> getValueClass(){return type;}public Collection<T> getPossibleValues(){return possible;}}
