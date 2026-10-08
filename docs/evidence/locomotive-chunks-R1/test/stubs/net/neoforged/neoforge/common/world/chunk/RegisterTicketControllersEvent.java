package net.neoforged.neoforge.common.world.chunk;
public final class RegisterTicketControllersEvent {
 public TicketController registered;
 public void register(TicketController controller){ if(registered!=null)throw new AssertionError("duplicate");registered=controller; }
}
