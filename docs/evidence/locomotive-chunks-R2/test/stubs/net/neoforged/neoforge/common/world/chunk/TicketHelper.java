package net.neoforged.neoforge.common.world.chunk;
import java.util.*;import net.minecraft.core.BlockPos;import net.minecraft.server.level.ServerLevel;
public final class TicketHelper {
 public final ServerLevel level;
 public final Map<UUID,Set<Long>> entities=new HashMap<>();
 public final Map<BlockPos,Set<Long>> blocks=new HashMap<>();
 public TicketHelper(ServerLevel level){this.level=level;}
 public Map<UUID,Set<Long>> getEntityTickets(){return Map.copyOf(entities);}
 public Map<BlockPos,Set<Long>> getBlockTickets(){return Map.copyOf(blocks);}
 public void removeAllTickets(UUID owner){TicketController.tickets.removeIf(k->k.level()==level && k.controller().equals("simplerail:locomotive") && k.owner().equals(owner));}
 public void removeAllTickets(BlockPos owner){blocks.remove(owner);}
}
