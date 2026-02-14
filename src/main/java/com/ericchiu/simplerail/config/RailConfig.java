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
    public final ModConfigSpec.DoubleValue highSpeedRailAcceleration;

    public Server(ModConfigSpec.Builder builder) {
      builder.push("Rail Settings");

      highSpeedRailMaxSpeed = builder
        .comment("The maximum speed of the high-speed rail. Vanilla powered rail is 0.4.")
        .defineInRange("highSpeedRailMaxSpeed", 0.8, 0.1, 5.0);

      highSpeedRailAcceleration = builder
        .comment("The acceleration factor applied when passing over the rail.")
        .defineInRange("highSpeedRailAcceleration", 0.1, 0.01, 1.0);

      builder.pop();
    }
  }
}
