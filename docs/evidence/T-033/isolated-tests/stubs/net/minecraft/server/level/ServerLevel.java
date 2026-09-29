package net.minecraft.server.level;
import java.util.*;import net.minecraft.world.level.Level;import net.minecraft.world.level.block.state.BlockState;import net.minecraft.core.particles.ParticleOptions;import net.minecraft.sounds.*;
/** Records outgoing call parameters only; no real packet/world/audio simulation. */
public class ServerLevel extends Level {
 public int particleCalls,soundCalls,count;public double particleX,particleY,particleZ,dx,dy,dz,speed,soundX,soundY,soundZ;
 public float volume,pitch;public Object excludedPlayer;public ParticleOptions particle;public SoundEvent sound;public SoundSource category;
 public final List<String> timeline=new ArrayList<>();
 public ServerLevel(BlockState state){super(state);}
 public <T extends ParticleOptions>int sendParticles(T type,double x,double y,double z,int count,double dx,double dy,double dz,double speed){
  timeline.add("particle");particleCalls++;particle=type;particleX=x;particleY=y;particleZ=z;this.count=count;this.dx=dx;this.dy=dy;this.dz=dz;this.speed=speed;return 0;
 }
 public void playSound(Object excludedPlayer,double x,double y,double z,SoundEvent sound,SoundSource category,float volume,float pitch){
  timeline.add("sound");soundCalls++;this.excludedPlayer=excludedPlayer;soundX=x;soundY=y;soundZ=z;this.sound=sound;this.category=category;this.volume=volume;this.pitch=pitch;
 }
}
