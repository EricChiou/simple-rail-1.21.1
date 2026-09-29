package net.minecraft.world.level.block.state.properties;
public final class BooleanProperty extends Property<Boolean> {
    private BooleanProperty(String name) { super(name); }
    public static BooleanProperty create(String name) { return new BooleanProperty(name); }
}
