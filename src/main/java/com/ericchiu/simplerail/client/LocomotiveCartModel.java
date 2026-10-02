package com.ericchiu.simplerail.client;

import com.ericchiu.simplerail.entity.LocomotiveCartEntity;
import net.minecraft.client.model.MinecartModel;
import net.minecraft.client.model.geom.ModelPart;
import net.minecraft.client.model.geom.PartPose;
import net.minecraft.client.model.geom.builders.CubeListBuilder;
import net.minecraft.client.model.geom.builders.LayerDefinition;
import net.minecraft.client.model.geom.builders.MeshDefinition;
import net.minecraft.client.model.geom.builders.PartDefinition;

/** Six OLD boxes at the original 96x64 UV coordinates. */
public final class LocomotiveCartModel extends MinecartModel<LocomotiveCartEntity> {
    public LocomotiveCartModel(ModelPart root) {
        super(root);
    }

    public static LayerDefinition createBodyLayer() {
        MeshDefinition mesh = new MeshDefinition();
        PartDefinition cart = mesh.getRoot().addOrReplaceChild("cart", CubeListBuilder.create(),
                PartPose.offset(0.0F, 5.0F, 0.0F));
        cart.addOrReplaceChild("body", CubeListBuilder.create().texOffs(0, 0).mirror()
                .addBox(-2.0F, -14.0F, -6.0F, 11.0F, 11.0F, 12.0F), PartPose.ZERO);
        cart.addOrReplaceChild("furnace", CubeListBuilder.create().texOffs(47, 0).mirror()
                .addBox(-9.0F, -15.0F, -7.0F, 7.0F, 12.0F, 14.0F), PartPose.ZERO);
        cart.addOrReplaceChild("chassis", CubeListBuilder.create().texOffs(0, 27).mirror()
                .addBox(-10.0F, -3.0F, -8.0F, 20.0F, 2.0F, 16.0F), PartPose.ZERO);
        cart.addOrReplaceChild("wheels", CubeListBuilder.create().texOffs(0, 46).mirror()
                .addBox(-9.0F, -1.0F, -7.0F, 18.0F, 1.0F, 14.0F), PartPose.ZERO);
        cart.addOrReplaceChild("bumper", CubeListBuilder.create().texOffs(65, 46).mirror()
                .addBox(9.0F, -4.0F, -6.0F, 1.0F, 4.0F, 12.0F), PartPose.ZERO);
        cart.addOrReplaceChild("smokestack", CubeListBuilder.create().texOffs(73, 27).mirror()
                .addBox(4.0F, -18.0F, -2.0F, 4.0F, 4.0F, 4.0F), PartPose.ZERO);
        return LayerDefinition.create(mesh, 96, 64);
    }
}
