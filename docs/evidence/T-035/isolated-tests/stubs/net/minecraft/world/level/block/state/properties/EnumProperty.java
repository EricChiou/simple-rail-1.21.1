package net.minecraft.world.level.block.state.properties;
public class EnumProperty<T extends Enum<T>> extends Property<T>{private EnumProperty(String name,Class<T> type){super(name);this.type=type;possible=java.util.List.of(type.getEnumConstants());}public static <T extends Enum<T>> EnumProperty<T> create(String name,Class<T> type){return new EnumProperty<T>(name,type);}}
