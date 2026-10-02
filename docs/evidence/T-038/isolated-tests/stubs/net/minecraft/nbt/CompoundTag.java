package net.minecraft.nbt;
import java.util.*;
public class CompoundTag implements Tag {
    private final Map<String,Object> values=new HashMap<>();
    public void put(String key,CompoundTag value){values.put(key,value);}
    public CompoundTag getCompound(String key){Object v=values.get(key);return v instanceof CompoundTag tag?tag:new CompoundTag();}
    public void putInt(String key,int value){values.put(key,value);}
    public int getInt(String key){Object v=values.get(key);return v instanceof Integer n?n:0;}
    public void putLong(String key,long value){values.put(key,value);}
    public long getLong(String key){Object v=values.get(key);return v instanceof Long n?n:0;}
    public void putUUID(String key,UUID value){values.put(key,value);}
    public UUID getUUID(String key){return (UUID)values.get(key);}
    public boolean hasUUID(String key){return values.get(key) instanceof UUID;}
    public boolean contains(String key,int type){Object v=values.get(key);return type==TAG_INT?v instanceof Integer:type==TAG_LONG&&v instanceof Long;}
}
