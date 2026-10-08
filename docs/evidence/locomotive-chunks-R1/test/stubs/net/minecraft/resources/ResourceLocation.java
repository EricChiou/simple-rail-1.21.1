package net.minecraft.resources;
public record ResourceLocation(String namespace,String path){
 public static ResourceLocation fromNamespaceAndPath(String ns,String path){return new ResourceLocation(ns,path);}
 public String toString(){return namespace+":"+path;}
}
