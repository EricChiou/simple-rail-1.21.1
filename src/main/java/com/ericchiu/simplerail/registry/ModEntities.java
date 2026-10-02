package com.ericchiu.simplerail.registry;

import com.ericchiu.simplerail.SimpleRail;
import com.ericchiu.simplerail.entity.LocomotiveCartEntity;
import net.minecraft.core.registries.Registries;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.MobCategory;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

public final class ModEntities {
    private static final DeferredRegister<EntityType<?>> TYPES =
            DeferredRegister.create(Registries.ENTITY_TYPE, SimpleRail.MODID);

    public static final DeferredHolder<EntityType<?>, EntityType<LocomotiveCartEntity>> LOCOMOTIVE_CART =
            TYPES.register("locomotive_cart", () -> EntityType.Builder
                    .<LocomotiveCartEntity>of(LocomotiveCartEntity::new, MobCategory.MISC)
                    .sized(0.98F, 0.7F)
                    .clientTrackingRange(8)
                    .build("simplerail:locomotive_cart"));

    private ModEntities() {}

    public static void register(IEventBus modEventBus) {
        TYPES.register(modEventBus);
    }
}
