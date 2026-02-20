package com.ericchiu.simplerail.registry;

import com.ericchiu.simplerail.SimpleRail;
import com.ericchiu.simplerail.entity.FacingDirection;
import net.minecraft.network.FriendlyByteBuf;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.network.syncher.EntityDataSerializer;
import net.neoforged.neoforge.registries.DeferredRegister;
import net.neoforged.neoforge.registries.NeoForgeRegistries;

import java.util.function.Supplier;

public class ModEntityDataSerializers {

  // 使用 NeoForge 的註冊器
  public static final DeferredRegister<EntityDataSerializer<?>> SERIALIZERS = 
    DeferredRegister.create(NeoForgeRegistries.Keys.ENTITY_DATA_SERIALIZERS, SimpleRail.MODID);

  // 使用 StreamCodec.of 來定義 Encode (寫入) 與 Decode (讀取) 邏輯
  public static final Supplier<EntityDataSerializer<FacingDirection>> FACING_DIRECTION = 
    SERIALIZERS.register("facing_direction", () -> EntityDataSerializer.forValueType(
      StreamCodec.<FriendlyByteBuf, FacingDirection>of(
        (buf, direction) -> buf.writeEnum(direction), // Encoder
        (buf) -> buf.readEnum(FacingDirection.class)  // Decoder
      )
    ));
}