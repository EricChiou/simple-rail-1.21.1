package net.neoforged.bus.api;
import java.util.function.Consumer;
public class IEventBus {
 public final java.util.List<Consumer<?>> listeners=new java.util.ArrayList<>();
 public <T> void addListener(Consumer<T> listener){listeners.add(listener);}
 @SuppressWarnings("unchecked")public void fire(int i,Object e){((Consumer<Object>)listeners.get(i)).accept(e);}
}
