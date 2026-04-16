package com.ericchiu.simplerail.config;

import net.neoforged.neoforge.common.ModConfigSpec;

/**
 * 模組設定檔
 * 依據 GEMINI.md 規範：設定檔 comment 使用英文
 */
public class Config {
  private static final ModConfigSpec.Builder BUILDER = new ModConfigSpec.Builder();

  // 目前尚無自訂設定，僅保留 SPEC 用於註冊
  public static final ModConfigSpec SPEC = BUILDER.build();
}
