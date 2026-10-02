package com.ericchiu.simplerail.client;

import com.ericchiu.simplerail.SimpleRail;
import com.ericchiu.simplerail.entity.Facing8;
import com.ericchiu.simplerail.entity.LocomotiveCartEntity;
import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.blaze3d.vertex.VertexConsumer;
import com.mojang.math.Axis;
import net.minecraft.client.model.geom.ModelLayerLocation;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.entity.EntityRenderer;
import net.minecraft.client.renderer.entity.EntityRendererProvider;
import net.minecraft.client.renderer.texture.OverlayTexture;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.util.Mth;
import net.minecraft.world.phys.Vec3;

/** One custom body, with vanilla minecart track interpolation and damage pose. */
public final class LocomotiveCartRenderer extends EntityRenderer<LocomotiveCartEntity> {
    public static final ModelLayerLocation LAYER = new ModelLayerLocation(
            ResourceLocation.fromNamespaceAndPath(SimpleRail.MODID, "locomotive_cart"), "main");
    private static final ResourceLocation TEXTURE = ResourceLocation.fromNamespaceAndPath(
            SimpleRail.MODID, "textures/entity/locomotive_cart.png");

    private final LocomotiveCartModel model;
    public LocomotiveCartRenderer(EntityRendererProvider.Context context) {
        super(context);
        shadowRadius = 0.7F;
        model = new LocomotiveCartModel(context.bakeLayer(LAYER));
    }

    @Override
    public ResourceLocation getTextureLocation(LocomotiveCartEntity entity) {
        return TEXTURE;
    }

    @Override
    public void render(LocomotiveCartEntity entity, float entityYaw, float partialTicks,
            PoseStack pose, MultiBufferSource buffer, int packedLight) {
        super.render(entity, entityYaw, partialTicks, pose, buffer, packedLight);
        pose.pushPose();
        long jitter = (long) entity.getId() * 493286711L;
        jitter = jitter * jitter * 4392167121L + jitter * 98761L;
        pose.translate((((float) (jitter >> 16 & 7L) + 0.5F) / 8.0F - 0.5F) * 0.004F,
                (((float) (jitter >> 20 & 7L) + 0.5F) / 8.0F - 0.5F) * 0.004F,
                (((float) (jitter >> 24 & 7L) + 0.5F) / 8.0F - 0.5F) * 0.004F);

        double x = Mth.lerp((double) partialTicks, entity.xOld, entity.getX());
        double y = Mth.lerp((double) partialTicks, entity.yOld, entity.getY());
        double z = Mth.lerp((double) partialTicks, entity.zOld, entity.getZ());
        float pitch = Mth.lerp(partialTicks, entity.xRotO, entity.getXRot());
        Vec3 path = entity.getPos(x, y, z);
        if (path != null) {
            Vec3 ahead = entity.getPosOffs(x, y, z, 0.3F);
            Vec3 behind = entity.getPosOffs(x, y, z, -0.3F);
            if (ahead == null) ahead = path;
            if (behind == null) behind = path;
            pose.translate(path.x - x, (ahead.y + behind.y) / 2.0D - y, path.z - z);
            Vec3 tangent = behind.subtract(ahead);
            if (tangent.lengthSqr() > 0.0D) pitch = (float) (Math.atan(tangent.normalize().y) * 73.0D);
        }

        Facing8 facing = entity.facing();
        pose.translate(0.0F, 0.375F, 0.0F);
        pose.mulPose(Axis.YP.rotationDegrees(facing.yaw()));
        pose.mulPose(Axis.ZP.rotationDegrees(
                facing == Facing8.EAST || facing == Facing8.SOUTH ? pitch : -pitch));
        float hurt = (float) entity.getHurtTime() - partialTicks;
        float damage = Math.max(0.0F, entity.getDamage() - partialTicks);
        if (hurt > 0.0F) {
            pose.mulPose(Axis.XP.rotationDegrees(Mth.sin(hurt) * hurt * damage / 10.0F * entity.getHurtDir()));
        }

        pose.scale(-1.0F, -1.0F, 1.0F);
        model.setupAnim(entity, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F);
        VertexConsumer vertices = buffer.getBuffer(model.renderType(getTextureLocation(entity)));
        model.renderToBuffer(pose, vertices, packedLight, OverlayTexture.NO_OVERLAY);
        pose.popPose();
    }
}
