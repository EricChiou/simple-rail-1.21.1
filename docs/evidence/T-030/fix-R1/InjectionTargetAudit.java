import java.io.InputStream;
import java.util.List;
import java.util.zip.ZipFile;
import org.objectweb.asm.ClassReader;
import org.objectweb.asm.Type;
import org.objectweb.asm.tree.*;

/** Reads class bytes only. No Minecraft class loading or Mixin/game bootstrap. */
public final class InjectionTargetAudit {
    private static int checks;
    private static final String METHOD = "moveAlongTrack";
    private static final String DESC = "(Lnet/minecraft/core/BlockPos;Lnet/minecraft/world/level/block/state/BlockState;)V";
    private static final String OWNER = "net/minecraft/world/level/block/PoweredRailBlock";
    private static void check(boolean pass,String label) {
        checks++;
        if (!pass) throw new AssertionError(label);
    }
    private static ClassNode read(ZipFile jar,String entry) throws Exception {
        try (InputStream stream = jar.getInputStream(jar.getEntry(entry))) {
            ClassNode node = new ClassNode(); new ClassReader(stream).accept(node,0); return node;
        }
    }
    private static int calls(MethodNode method) {
        int count=0;
        for (AbstractInsnNode insn : method.instructions) {
            if (insn instanceof MethodInsnNode call && call.owner.equals(OWNER)
                    && call.name.equals("isActivatorRail") && call.desc.equals("()Z")) count++;
        }
        return count;
    }
    private static Object value(AnnotationNode annotation,String key) {
        for(int i=0;i<annotation.values.size();i+=2) if(annotation.values.get(i).equals(key)) return annotation.values.get(i+1);
        return null;
    }
    public static void main(String[] args) throws Exception {
        try(ZipFile target=new ZipFile(args[0]);ZipFile product=new ZipFile(args[1])) {
            ClassNode cart=read(target,"net/minecraft/world/entity/vehicle/AbstractMinecart.class");
            List<MethodNode> matches=cart.methods.stream().filter(m->m.name.equals(METHOD)&&m.desc.equals(DESC)).toList();
            check(matches.size()==1,"Unique fixed-version target method descriptor");
            check(calls(matches.getFirst())==1,"Exactly one classification invocation in moveAlongTrack");
            check(cart.methods.stream().filter(m->m.name.equals("tick")).mapToInt(InjectionTargetAudit::calls).sum()==1,
                    "Separate activator invocation in tick exists outside selected method");
            ClassNode mixin=read(product,"com/ericchiu/simplerail/mixin/AbstractMinecartMixin.class");
            MethodNode handler=mixin.methods.stream().filter(m->m.name.equals("simplerail$coastOnUnpoweredOnewayRail")).findFirst().orElseThrow();
            check(handler.desc.equals("(L"+OWNER+";Lnet/minecraft/core/BlockPos;Lnet/minecraft/world/level/block/state/BlockState;)Z"),
                    "Receiver plus complete enclosing-method argument capture has expected descriptor");
            AnnotationNode redirect=handler.visibleAnnotations.stream().filter(a->a.desc.endsWith("/Redirect;")).findFirst().orElseThrow();
            check(value(redirect,"method").equals(List.of(METHOD+DESC)),"Mixin selects only track movement, not tick");
            for(String key : List.of("require","expect","allow")) check(value(redirect,key).equals(1),"Single call constraint "+key);
            AnnotationNode at=(AnnotationNode)value(redirect,"at");
            check(value(at,"value").equals("INVOKE") && value(at,"target").equals("L"+OWNER+";isActivatorRail()Z"),"Injection owner/name/descriptor pinned");
            AnnotationNode declared=mixin.invisibleAnnotations.stream().filter(a->a.desc.endsWith("/Mixin;")).findFirst().orElseThrow();
            check(value(declared,"value").equals(List.of(Type.getObjectType(cart.name))),"Mixin target is AbstractMinecart");
            ClassNode rail=read(product,"com/ericchiu/simplerail/block/OnewayRail.class");
            MethodNode pass=rail.methods.stream().filter(m->m.name.equals("onMinecartPass")).findFirst().orElseThrow();
            check(java.util.stream.StreamSupport.stream(pass.instructions.spliterator(),false).noneMatch(i->i instanceof MethodInsnNode call && call.name.equals("multiply")),
                    "Compiled oneway callback has no compensating multiplier");
        }
        System.out.println("PASS checks="+checks+"; offlineClassBytes=true; minecraftLoaded=false; mixinWeavingExecuted=false");
    }
}
