package evidence.t015;

import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.blaze3d.vertex.VertexConsumer;
import com.mojang.math.Axis;
import net.minecraft.client.model.MinecartModel;
import net.minecraft.client.model.geom.ModelLayerLocation;
import net.minecraft.client.model.geom.ModelPart;
import net.minecraft.client.model.geom.PartPose;
import net.minecraft.client.model.geom.builders.CubeListBuilder;
import net.minecraft.client.model.geom.builders.LayerDefinition;
import net.minecraft.client.model.geom.builders.MeshDefinition;
import net.minecraft.client.model.geom.builders.PartDefinition;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.entity.EntityRenderer;
import net.minecraft.client.renderer.entity.EntityRendererProvider;
import net.minecraft.client.renderer.texture.OverlayTexture;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.vehicle.MinecartFurnace;
import net.neoforged.neoforge.client.event.EntityRenderersEvent;

// Signature/shape probe only. It is never registered in the product or executed in Minecraft.
public final class T015Probe {
    private static final ModelLayerLocation LAYER = new ModelLayerLocation(
        ResourceLocation.fromNamespaceAndPath("simplerail", "locomotive_cart"), "main");
    private static final ResourceLocation TEXTURE = ResourceLocation.fromNamespaceAndPath(
        "simplerail", "textures/entity/locomotive_cart.png");

    private T015Probe() {}

    public static void registerLayers(EntityRenderersEvent.RegisterLayerDefinitions event) {
        event.registerLayerDefinition(LAYER, Model::createBodyLayer);
    }

    public static void registerRenderer(EntityRenderersEvent.RegisterRenderers event, EntityType<MinecartFurnace> type) {
        event.registerEntityRenderer(type, Renderer::new);
    }

    public static final class Model extends MinecartModel<MinecartFurnace> {
        public Model(ModelPart root) { super(root); }

        public static LayerDefinition createBodyLayer() {
            MeshDefinition mesh = new MeshDefinition();
            PartDefinition cart = mesh.getRoot().addOrReplaceChild("cart", CubeListBuilder.create(), PartPose.offset(0.0F, 5.0F, 0.0F));
            cart.addOrReplaceChild("body", CubeListBuilder.create().texOffs(0, 0).mirror().addBox(-2, -14, -6, 11, 11, 12), PartPose.ZERO);
            cart.addOrReplaceChild("furnace", CubeListBuilder.create().texOffs(47, 0).mirror().addBox(-9, -15, -7, 7, 12, 14), PartPose.ZERO);
            cart.addOrReplaceChild("chassis", CubeListBuilder.create().texOffs(0, 27).mirror().addBox(-10, -3, -8, 20, 2, 16), PartPose.ZERO);
            cart.addOrReplaceChild("wheels", CubeListBuilder.create().texOffs(0, 46).mirror().addBox(-9, -1, -7, 18, 1, 14), PartPose.ZERO);
            cart.addOrReplaceChild("bumper", CubeListBuilder.create().texOffs(65, 46).mirror().addBox(9, -4, -6, 1, 4, 12), PartPose.ZERO);
            cart.addOrReplaceChild("smokestack", CubeListBuilder.create().texOffs(73, 27).mirror().addBox(4, -18, -2, 4, 4, 4), PartPose.ZERO);
            return LayerDefinition.create(mesh, 96, 64);
        }
    }

    public static final class Renderer extends EntityRenderer<MinecartFurnace> {
        private final Model model;

        public Renderer(EntityRendererProvider.Context context) {
            super(context);
            this.model = new Model(context.bakeLayer(LAYER));
        }

        @Override
        public ResourceLocation getTextureLocation(MinecartFurnace entity) { return TEXTURE; }

        @Override
        public void render(MinecartFurnace entity, float entityYaw, float partialTicks, PoseStack pose,
                           MultiBufferSource buffers, int packedLight) {
            pose.pushPose();
            pose.mulPose(Axis.YP.rotationDegrees(180.0F - entityYaw));
            pose.scale(-1.0F, -1.0F, 1.0F);
            model.setupAnim(entity, 0, 0, 0, 0, 0);
            VertexConsumer vertices = buffers.getBuffer(model.renderType(getTextureLocation(entity)));
            model.renderToBuffer(pose, vertices, packedLight, OverlayTexture.NO_OVERLAY);
            pose.popPose();
            super.render(entity, entityYaw, partialTicks, pose, buffers, packedLight);
        }
    }
}
