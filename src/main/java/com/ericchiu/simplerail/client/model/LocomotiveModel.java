package com.ericchiu.simplerail.client.model;

import com.ericchiu.simplerail.entity.LocomotiveEntity;
import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.blaze3d.vertex.VertexConsumer;
import net.minecraft.client.model.EntityModel;
import net.minecraft.client.model.geom.ModelPart;
import net.minecraft.client.model.geom.PartPose;
import net.minecraft.client.model.geom.builders.CubeListBuilder;
import net.minecraft.client.model.geom.builders.LayerDefinition;
import net.minecraft.client.model.geom.builders.MeshDefinition;
import net.minecraft.client.model.geom.builders.PartDefinition;

public class LocomotiveModel<T extends LocomotiveEntity> extends EntityModel<T> {

  private final ModelPart root;

  public LocomotiveModel(ModelPart root) {
    this.root = root;
  }

  // 【最佳實踐】使用 LayerDefinition 來靜態定義模型的層級與大小
  public static LayerDefinition createBodyLayer() {
    MeshDefinition meshdefinition = new MeshDefinition();
    PartDefinition partdefinition = meshdefinition.getRoot();

    // 建立 cart 基礎節點，設定相對位置
    PartDefinition cart = partdefinition.addOrReplaceChild("cart", 
        CubeListBuilder.create(), 
        PartPose.offset(0.0F, 5.0F, 0.0F));

    // 將所有部件作為 cart 的子節點加入
    cart.addOrReplaceChild("body", CubeListBuilder.create().mirror().texOffs(0, 0)
        .addBox(-2.0F, -14.0F, -6.0F, 11.0F, 11.0F, 12.0F), PartPose.ZERO);

    cart.addOrReplaceChild("furnace", CubeListBuilder.create().mirror().texOffs(47, 0)
        .addBox(-9.0F, -15.0F, -7.0F, 7.0F, 12.0F, 14.0F), PartPose.ZERO);

    cart.addOrReplaceChild("chassis", CubeListBuilder.create().mirror().texOffs(0, 27)
        .addBox(-10.0F, -3.0F, -8.0F, 20.0F, 2.0F, 16.0F), PartPose.ZERO);

    cart.addOrReplaceChild("wheels", CubeListBuilder.create().mirror().texOffs(0, 46)
        .addBox(-9.0F, -1.0F, -7.0F, 18.0F, 1.0F, 14.0F), PartPose.ZERO);

    cart.addOrReplaceChild("bumper", CubeListBuilder.create().mirror().texOffs(65, 46)
        .addBox(9.0F, -4.0F, -6.0F, 1.0F, 4.0F, 12.0F), PartPose.ZERO);

    cart.addOrReplaceChild("smokestack", CubeListBuilder.create().mirror().texOffs(73, 27)
        .addBox(4.0F, -18.0F, -2.0F, 4.0F, 4.0F, 4.0F), PartPose.ZERO);

    // 回傳包含貼圖尺寸 (96x64) 的定義
    return LayerDefinition.create(meshdefinition, 96, 64);
  }

  @Override
  public void setupAnim(T entity, float limbSwing, float limbSwingAmount, float ageInTicks, float netHeadYaw, float headPitch) {
    // 礦車動畫通常由 Renderer 直接旋轉 PoseStack，這裡留空即可
  }

  @Override
  public void renderToBuffer(PoseStack poseStack, VertexConsumer buffer, int packedLight, int packedOverlay, int color) {
    // 直接渲染根節點
    root.render(poseStack, buffer, packedLight, packedOverlay, color);
  }
}