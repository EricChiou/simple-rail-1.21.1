package com.ericchiu.simplerail.config;

import net.neoforged.neoforge.common.ModConfigSpec;
import org.apache.commons.lang3.tuple.Pair;

public class RailConfig {
  public static final Server SERVER;
  public static final ModConfigSpec SERVER_SPEC;

  static {
    final Pair<Server, ModConfigSpec> specPair = new ModConfigSpec.Builder().configure(Server::new);
    SERVER_SPEC = specPair.getRight();
    SERVER = specPair.getLeft();
  }

  public static class Server {
    public final ModConfigSpec.DoubleValue highSpeedRailMaxSpeed;

    public Server(ModConfigSpec.Builder builder) {
      builder.push("general");

      highSpeedRailMaxSpeed = builder
        .comment("The maximum speed for the High Speed Rail.",
                 "Vanilla powered rail is 0.4. Be careful setting this too high (> 1.0) as carts may derail on corners.")
        .defineInRange("highSpeedRailMaxSpeed", 0.8, 0.1, 5.0);

      builder.pop();
    }
  }
}
