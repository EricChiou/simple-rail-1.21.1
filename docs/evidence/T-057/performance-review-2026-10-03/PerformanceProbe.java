import com.ericchiu.simplerail.entity.TrainBlockRoute;
import com.ericchiu.simplerail.entity.TrainFormation;
import java.lang.management.ManagementFactory;
import java.lang.reflect.Field;
import java.util.*;

/** Plain JVM only. No Minecraft classes, entity ticking, world, or server bootstrap. */
public final class PerformanceProbe {
    static volatile double sink;
    static int checks;
    static final TrainBlockRoute.Point HEAD = new TrainBlockRoute.Point(0.5, 64, 0.5);
    static final class Counted<E> extends AbstractList<E> {
        final List<E> source;
        long reads, copied;
        Counted(List<E> source) { this.source = source; }
        public int size() { return source.size(); }
        public E get(int i) { reads++; return source.get(i); }
        public Object[] toArray() { copied += size(); return source.toArray(); }
        public boolean add(E e) { return source.add(e); }
    }
    @SuppressWarnings("unchecked")
    static <E> Counted<E> count(Object target, String name) throws Exception {
        Field field = target.getClass().getDeclaredField(name);
        field.setAccessible(true);
        Counted<E> c = new Counted<>((List<E>)field.get(target));
        field.set(target, c);
        return c;
    }
    static void check(boolean b, String label) {
        checks++;
        if (!b) throw new AssertionError(label);
    }
    static TrainBlockRoute route(int n) {
        TrainBlockRoute route = new TrainBlockRoute();
        List<TrainFormation.Cell> cells = new ArrayList<>();
        for (int i = 1; i <= (int)Math.ceil(n * TrainBlockRoute.SPACING) + 2; i++)
            cells.add(new TrainFormation.Cell(-i, 64, 0));
        route.load(cells, n);
        return route;
    }
    // Same route-call order as moveLoadedCarts when all N carriages are loaded.
    // UUID lookup, entity movement, physics and network costs are explicitly excluded.
    static double routePass(TrainBlockRoute route, int n, TrainBlockRoute.Point head) {
        if (!route.readyFor(head, n)) return -1;
        double total = 0;
        for (int i = 1; i <= n; i++) total += route.target(head, i).x();
        return total;
    }
    // The three actual TrainFormation calls in a successful linkNewCart, without MC/ownership.
    static boolean linkFormationCalls(TrainFormation f, UUID id) {
        if (f.carts().contains(id)) return false;
        if (!f.add(id, new TrainFormation.Cell(0, 64, 0))) return false;
        sink = f.carts().size(); // seedTail's carriageCount argument
        return true;
    }
    static TrainFormation formation(int n) {
        TrainFormation f = new TrainFormation();
        List<UUID> ids = new ArrayList<>();
        Map<UUID, TrainFormation.Cell> stops = new HashMap<>();
        for (int i = 1; i <= n; i++) {
            UUID id = new UUID(0, i); ids.add(id);
            stops.put(id, new TrainFormation.Cell(-i, 64, 0));
        }
        f.load(ids, stops);
        return f;
    }
    static void deterministic() throws Exception {
        System.out.println("COUNT,n,route_segments_per_pass,segments_at_20_passes,link_copy_elements,repeated_link_copy_elements");
        for (int n : new int[]{1, 8, 16, 32, 64, 128, 256, 512, 1024}) {
            TrainBlockRoute r = route(n);
            Counted<TrainFormation.Cell> cells = count(r, "cells");
            double value = routePass(r, n, HEAD);
            long visits = cells.reads;
            long expected = (long)Math.ceil(1.35 * n);
            for (int i = 1; i <= n; i++) expected += (long)Math.ceil(1.35 * i);
            check(visits == expected, "exact straight route segment count " + n);
            cells.reads = 0;
            check(value == routePass(r, n, HEAD) && visits == cells.reads,
                    "unchanged stationary head repeats same full work " + n);
            TrainFormation f = formation(n);
            Counted<UUID> ids = count(f, "carts");
            check(linkFormationCalls(f, new UUID(1, n)), "append " + n);
            long copy = ids.copied;
            check(copy == 2L * n + 1, "two full snapshots per successful append " + n);
            ids.copied = 0;
            check(!linkFormationCalls(f, new UUID(1, n)), "duplicate reject " + n);
            check(ids.copied == n + 1, "duplicate still snapshots all IDs " + n);
            System.out.printf(Locale.ROOT, "COUNT,%d,%d,%d,%d,%d%n", n, visits, visits*20, copy, ids.copied);
        }
        TrainFormation f = new TrainFormation();
        Counted<UUID> ids = count(f, "carts");
        int n = 1024;
        for(int i = 0; i < n; i++) check(linkFormationCalls(f, new UUID(3, i)), "bulk append");
        check(ids.copied == (long)n*n, "building N-car formation copies N squared UUID slots");
        System.out.println("BULK,n="+n+",copied_elements="+ids.copied);
        TrainBlockRoute bounded = route(8192);
        check(bounded.cells().size() == 8192, "route retained size cap");
        check(!bounded.readyFor(HEAD, 8192), "unready route fallback, not quadratic target loop");
        System.out.println("PASS deterministic_checks="+checks+"; reflection counters only, not used for timing");
    }
    static final com.sun.management.ThreadMXBean ALLOC =
            (com.sun.management.ThreadMXBean)ManagementFactory.getThreadMXBean();
    static long bytes() { return ALLOC.getThreadAllocatedBytes(Thread.currentThread().threadId()); }
    static double median(double[] a) { Arrays.sort(a); return a[a.length/2]; }
    static void timing() {
        if (ALLOC.isThreadAllocatedMemorySupported()) ALLOC.setThreadAllocatedMemoryEnabled(true);
        System.out.println("TIMING,n,repetitions_per_sample,median_us_per_route_pass,median_allocated_bytes_per_route_pass");
        for (int n : new int[]{8, 16, 32, 64, 128, 256, 512, 1024}) {
            TrainBlockRoute r = route(n); // original ArrayList, no reflection counters
            long until = System.nanoTime() + 250_000_000L;
            int k = 0;
            while (System.nanoTime() < until) {
                sink = routePass(r, n, (k++ & 1) == 0 ? HEAD : new TrainBlockRoute.Point(0.6,64,0.5));
            }
            int reps = Math.max(12, Math.min(4000, (int)(2_000_000L / ((long)n*n))));
            double[] times = new double[7], allocation = new double[7];
            for (int sample = 0; sample < 7; sample++) {
                long startBytes = bytes(), start = System.nanoTime();
                double total = 0;
                for (int i = 0; i < reps; i++) total += routePass(r, n, HEAD);
                times[sample] = (System.nanoTime()-start) / (reps * 1000.0);
                allocation[sample] = (bytes()-startBytes) / (double)reps;
                sink = total;
                System.out.printf(Locale.ROOT,"SAMPLE,%d,%d,%.3f,%.1f%n", n,sample,times[sample],allocation[sample]);
            }
            System.out.printf(Locale.ROOT,"TIMING,%d,%d,%.3f,%.1f%n",n,reps,median(times),median(allocation));
        }
    }
    public static void main(String[] args) throws Exception {
        System.out.printf("ENV java=%s vm=%s os=%s arch=%s processors=%d gameExecuted=false%n",
                System.getProperty("java.version"),System.getProperty("java.vm.name"),
                System.getProperty("os.name"),System.getProperty("os.arch"),Runtime.getRuntime().availableProcessors());
        if(args.length > 0 && args[0].equals("timing")) timing(); else deterministic();
    }
}
