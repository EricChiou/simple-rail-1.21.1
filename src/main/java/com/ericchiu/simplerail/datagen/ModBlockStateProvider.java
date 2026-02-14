package com.ericchiu.simplerail.datagen;

import com.ericchiu.simplerail.SimpleRail;
import com.ericchiu.simplerail.block.HighSpeedRailBlock;
import com.ericchiu.simplerail.registry.ModBlocks;

import net.minecraft.data.PackOutput;
import net.minecraft.world.level.block.state.properties.RailShape;
import net.neoforged.neoforge.client.model.generators.BlockStateProvider;
import net.neoforged.neoforge.client.model.generators.ConfiguredModel;
import net.neoforged.neoforge.client.model.generators.ModelFile;
import net.neoforged.neoforge.common.data.ExistingFileHelper;

public class ModBlockStateProvider extends BlockStateProvider {
  public ModBlockStateProvider(PackOutput output, ExistingFileHelper exFileHelper) {
    super(output, SimpleRail.MODID, exFileHelper);
  }

  @Override
  protected void registerStatesAndModels() {
    registerHighSpeedRail();
  }

  private void registerHighSpeedRail() {
    // Define the models using the textures
    // === 未充能 (Off) 的模型 ===
    ModelFile railFlatOff = models().getBuilder("block/high_speed_rail")
        .parent(models().getExistingFile(mcLoc("block/rail_flat")))
        .texture("rail", modLoc("block/high_speed_rail"))
        .renderType("minecraft:cutout");

    ModelFile railRaisedNeOff = models().getBuilder("block/high_speed_rail_raised_ne")
        .parent(models().getExistingFile(mcLoc("block/template_rail_raised_ne")))
        .texture("rail", modLoc("block/high_speed_rail"))
        .renderType("minecraft:cutout");

    ModelFile railRaisedSwOff = models().getBuilder("block/high_speed_rail_raised_sw")
        .parent(models().getExistingFile(mcLoc("block/template_rail_raised_sw")))
        .texture("rail", modLoc("block/high_speed_rail"))
        .renderType("minecraft:cutout");

    // === 充能 (On) 的模型 ===
    ModelFile railFlatOn = models().getBuilder("block/high_speed_rail_on")
        .parent(models().getExistingFile(mcLoc("block/rail_flat")))
        .texture("rail", modLoc("block/high_speed_rail_on"))
        .renderType("minecraft:cutout");

    ModelFile railRaisedNeOn = models().getBuilder("block/high_speed_rail_raised_ne_on")
        .parent(models().getExistingFile(mcLoc("block/template_rail_raised_ne")))
        .texture("rail", modLoc("block/high_speed_rail_on"))
        .renderType("minecraft:cutout");

    ModelFile railRaisedSwOn = models().getBuilder("block/high_speed_rail_raised_sw_on")
        .parent(models().getExistingFile(mcLoc("block/template_rail_raised_sw")))
        .texture("rail", modLoc("block/high_speed_rail_on"))
        .renderType("minecraft:cutout");

    // === 將模型與 BlockState 綁定 ===
    getVariantBuilder(ModBlocks.HIGH_SPEED_RAIL.get()).forAllStates(state -> {
      boolean powered = state.getValue(HighSpeedRailBlock.POWERED);
      RailShape shape = state.getValue(HighSpeedRailBlock.SHAPE);
      
      // 根據充能狀態選擇對應的基礎模型
      ModelFile flat = powered ? railFlatOn : railFlatOff;
      ModelFile raisedNe = powered ? railRaisedNeOn : railRaisedNeOff;
      ModelFile raisedSw = powered ? railRaisedSwOn : railRaisedSwOff;

      // 根據軌道形狀 (Shape) 決定使用的模型與旋轉角度
      return switch (shape) {
        case NORTH_SOUTH -> ConfiguredModel.builder().modelFile(flat).build();
        case EAST_WEST -> ConfiguredModel.builder().modelFile(flat).rotationY(90).build();
        case ASCENDING_NORTH -> ConfiguredModel.builder().modelFile(raisedNe).build();
        case ASCENDING_EAST -> ConfiguredModel.builder().modelFile(raisedNe).rotationY(90).build();
        case ASCENDING_SOUTH -> ConfiguredModel.builder().modelFile(raisedSw).build();
        case ASCENDING_WEST -> ConfiguredModel.builder().modelFile(raisedSw).rotationY(90).build();
        // 動力軌道正常情況下不會產生轉彎 (SOUTH_EAST 等)，若有例外則回退至平面
        default -> ConfiguredModel.builder().modelFile(flat).build();
      };
    });
  }
}