package com.ericchiu.simplerail.client.renderer;

import org.joml.Vector3f;

import com.ericchiu.simplerail.SimpleRail;
import com.ericchiu.simplerail.client.ModModelLayers;
import com.ericchiu.simplerail.client.model.LocomotiveModel;
import com.ericchiu.simplerail.entity.FacingDirection;
import com.ericchiu.simplerail.entity.LocomotiveEntity;
import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.blaze3d.vertex.VertexConsumer;
import com.mojang.math.Axis;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.entity.EntityRenderer;
import net.minecraft.client.renderer.entity.EntityRendererProvider;
import net.minecraft.client.renderer.texture.OverlayTexture;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.util.Mth;
import net.minecraft.world.phys.Vec3;

public class LocomotiveRenderer extends EntityRenderer<LocomotiveEntity> {
  private static final ResourceLocation TEXTURE = ResourceLocation.fromNamespaceAndPath(SimpleRail.MODID, "textures/entity/locomotive.png");
  protected final LocomotiveModel<LocomotiveEntity> model;

  public LocomotiveRenderer(EntityRendererProvider.Context context) {
    super(context);
    // 透過 context 烘焙 (Bake) 出我們定義好的模型
    this.model = new LocomotiveModel<>(context.bakeLayer(ModModelLayers.LOCOMOTIVE_LAYER));
  }

  @Override
  public ResourceLocation getTextureLocation(LocomotiveEntity entity) {
    return TEXTURE;
  }

  @Override
  public void render(LocomotiveEntity entity, float entityYaw, float partialTicks, PoseStack poseStack, MultiBufferSource buffer, int packedLight) {
    super.render(entity, entityYaw, partialTicks, poseStack, buffer, packedLight);
    poseStack.pushPose();

    // 1. 處理軌道上的震動微調 (還原舊程式碼邏輯)
    long i = (long) entity.getId() * 493286711L;
    i = i * i * 4392167121L + i * 98761L;
    float f = (((float) (i >> 16 & 7L) + 0.5F) / 8.0F - 0.5F) * 0.004F;
    float f1 = (((float) (i >> 20 & 7L) + 0.5F) / 8.0F - 0.5F) * 0.004F;
    float f2 = (((float) (i >> 24 & 7L) + 0.5F) / 8.0F - 0.5F) * 0.004F;
    poseStack.translate(f, f1, f2);

    // 2. 處理軌道平滑移動與轉向計算
    double d0 = Mth.lerp((double) partialTicks, entity.xOld, entity.getX());
    double d1 = Mth.lerp((double) partialTicks, entity.yOld, entity.getY());
    double d2 = Mth.lerp((double) partialTicks, entity.zOld, entity.getZ());
    Vec3 vec3 = entity.getPos(d0, d1, d2);
    float f3 = Mth.lerp(partialTicks, entity.xRotO, entity.getXRot());

    if (vec3 != null) {
      Vec3 vec31 = entity.getPosOffs(d0, d1, d2, 0.3F);
      Vec3 vec32 = entity.getPosOffs(d0, d1, d2, -0.3F);
      if (vec31 == null) vec31 = vec3;
      if (vec32 == null) vec32 = vec3;

      poseStack.translate(vec3.x - d0, (vec31.y + vec32.y) / 2.0D - d1, vec3.z - d2);
      Vec3 vec33 = vec32.add(-vec31.x, -vec31.y, -vec31.z);
      if (vec33.length() != 0.0D) {
        vec33 = vec33.normalize();
        entityYaw = (float) (Math.atan2(vec33.z, vec33.x) * 180.0D / Math.PI);
        f3 = (float) (Math.atan(vec33.y) * 73.0D);
      }
    }

    // 3. 處理旋轉角度
    float rotY = 180.0F - entityYaw;
    float rotZ = -f3;
    this.setRenderDirection(entity, poseStack, rotY, rotZ);

    poseStack.translate(0.0F, 0.375F, 0.0F);

    // 4. 處理受擊搖晃 (Hurt Wobble)
    float hurtTime = (float) entity.getHurtTime() - partialTicks;
    float damage = entity.getDamage() - partialTicks;
    if (damage < 0.0F) damage = 0.0F;

    if (hurtTime > 0.0F) {
      poseStack.mulPose(Axis.XP.rotationDegrees(Mth.sin(hurtTime) * hurtTime * damage / 10.0F * (float) entity.getHurtDir()));
    }

    // 5. 模型縮放反轉 (渲染標準化) 與最終繪製
    poseStack.scale(-1.0F, -1.0F, 1.0F);
    this.model.setupAnim(entity, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F);
    
    VertexConsumer vertexconsumer = buffer.getBuffer(this.model.renderType(this.getTextureLocation(entity)));
    // 1.21.1 的 renderToBuffer 需要傳入 ARGB 的顏色 int，0xFFFFFFFF 代表純白色(無渲染濾鏡)
    this.model.renderToBuffer(poseStack, vertexconsumer, packedLight, OverlayTexture.NO_OVERLAY, 0xFFFFFFFF);
    
    poseStack.popPose();
  }

   private void setRenderDirection(LocomotiveEntity entity, PoseStack poseStack, float rotY, float rotZ) {
    FacingDirection facingDirection = entity.getFacingDirection();
    if (facingDirection == null) return; // 避免剛生成時 facingDirection 還沒同步過來導致 NullPointerException

    switch (facingDirection) {
      case EAST:
        rotY = 180.0F;
        rotZ = -rotZ;
        break;
      case WEST:
        rotY = 0.0F;
        break;
      case NORTH:
        rotY = -90.0F;
        break;
      case SOUTH:
        rotY = 90.0F;
        rotZ = -rotZ;
        break;
      case NORTH_EAST:
        rotY = -135.0F;
        break;
      case NORTH_WEST:
        rotY = -45.0F;
        break;
      case SOUTH_EAST:
        rotY = 135.0F;
        break;
      case SOUTH_WEST:
        rotY = 45.0F;
        break;
    }

    poseStack.mulPose(Axis.YP.rotationDegrees(rotY));
    poseStack.mulPose(Axis.ZP.rotationDegrees(rotZ));
  }
}