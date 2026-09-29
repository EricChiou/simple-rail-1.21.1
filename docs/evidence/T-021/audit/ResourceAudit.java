import com.google.gson.*;
import com.google.gson.stream.JsonReader;
import com.google.gson.stream.JsonToken;
import java.awt.image.BufferedImage;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.MessageDigest;
import java.util.*;
import java.util.zip.ZipFile;
import javax.imageio.ImageIO;

/** Standalone files/JSON/PNG audit. Minecraft archive is data only, never on the runtime classpath. */
public final class ResourceAudit {
    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().disableHtmlEscaping().create();
    private static final List<Map<String,Object>> checks = new ArrayList<>(), mappings = new ArrayList<>(), references = new ArrayList<>(), pngs = new ArrayList<>(), coverage = new ArrayList<>();
    private static final List<String> failures = new ArrayList<>();
    private static final Map<String,JsonObject> modelCache = new HashMap<>();
    private static final Map<String,Set<String>> edges = new TreeMap<>();
    private static Path oldRoot, target, evidence;
    private static ZipFile vanilla;

    public static void main(String[] args) throws Exception {
        oldRoot = Path.of(args[0]); target = Path.of(args[1]); evidence = Path.of(args[2]);
        JsonObject catalogue = json(Path.of("docs/evidence/T-004/catalogue.json"));
        Set<String> blocks = strings(catalogue.getAsJsonArray("blocks")), items = strings(catalogue.getAsJsonArray("items"));
        Set<String> cutout = new TreeSet<>();
        json(Path.of("docs/evidence/T-015/resources.json")).getAsJsonArray("railBlocks").forEach(block -> block.getAsJsonObject().getAsJsonArray("models").forEach(model -> cutout.add(model.getAsString())));
        check("29 cutout model contract", cutout.size() == 29);
        JsonArray map = JsonParser.parseString(Files.readString(Path.of("docs/evidence/T-009/resource-map.json"))).getAsJsonArray();
        int migrated = 0, deferred = 0, excluded = 0;
        Map<String,Integer> counts = new TreeMap<>();
        try (ZipFile archive = new ZipFile(args[3])) {
            vanilla = archive;
            JsonObject version;
            try (Reader reader = new InputStreamReader(archive.getInputStream(archive.getEntry("version.json")), StandardCharsets.UTF_8)) { version = JsonParser.parseReader(reader).getAsJsonObject(); }
            check("vanilla archive 1.21.1", version.get("id").getAsString().equals("1.21.1"));
            for (JsonElement element : map) {
                JsonObject row = element.getAsJsonObject();
                String path = row.get("oldPath").getAsString(), category = row.get("category").getAsString();
                String disposition;
                Map<String,Object> mapped = new LinkedHashMap<>();
                mapped.put("oldPath", path); mapped.put("logicalId", row.get("logicalId").getAsString()); mapped.put("oldSha256", hash(oldRoot.resolve(path)));
                if (path.startsWith("data/")) {
                    disposition = "deferred to T-022; not executed"; deferred++;
                    mapped.put("plannedTarget", row.get("candidatePath").getAsString());
                    check("T-022 data not migrated " + path, !Files.exists(target.resolve(row.get("candidatePath").getAsString())));
                } else if (path.equals("META-INF/mods.toml")) {
                    disposition = "legacy Forge metadata excluded; existing NeoForge template keeps D8 and gains logoFile"; excluded++;
                    mapped.put("target", "src/main/templates/META-INF/neoforge.mods.toml");
                    check("no copied Forge metadata", !Files.exists(target.resolve(path)));
                } else {
                    migrated++; counts.merge(category, 1, Integer::sum); disposition = "preserved same path/ID";
                    Path destination = target.resolve(path);
                    check("source has target " + path, Files.isRegularFile(destination));
                    mapped.put("target", path); mapped.put("targetSha256", hash(destination));
                    if (path.endsWith(".png")) {
                        check("PNG byte preservation " + path, Arrays.equals(Files.readAllBytes(oldRoot.resolve(path)), Files.readAllBytes(destination)));
                    } else if (path.endsWith(".json") || path.endsWith(".mcmeta")) {
                        JsonObject before = json(oldRoot.resolve(path)), after = json(destination);
                        JsonObject semantic = after.deepCopy();
                        if (category.equals("block model") && cutout.contains(destination.getFileName().toString().replace(".json", ""))) {
                            check("cutout " + path, after.has("render_type") && after.get("render_type").getAsString().equals("minecraft:cutout"));
                            semantic.remove("render_type"); disposition = "same path/ID; added minecraft:cutout only";
                        } else if (path.equals("pack.mcmeta")) {
                            before.getAsJsonObject("pack").remove("pack_format");
                            check("NeoForge optional-format metadata", !after.getAsJsonObject("pack").has("pack_format") && !after.getAsJsonObject("pack").has("supported_formats"));
                            disposition = "description preserved; removed obsolete format 6, NeoForge optional-format policy";
                        } else if (category.equals("language")) {
                            disposition = "same keys/values; duplicate _comment collapsed to its original last value";
                        }
                        check("only documented JSON changes " + path, semantic.equals(before));
                    }
                }
                mapped.put("disposition", disposition); mappings.add(mapped);
            }
            check("all 144 sources accounted", mappings.size() == 144 && migrated == 114 && deferred == 29 && excluded == 1);
            check("12 blockstates", counts.getOrDefault("blockstate", 0) == 12);
            check("40 block models", counts.getOrDefault("block model", 0) == 40);
            check("14 item models", counts.getOrDefault("item model", 0) == 14);
            check("44 textures", counts.getOrDefault("texture", 0) == 44);
            check("two language files", counts.getOrDefault("language", 0) == 2);
            List<Path> files;
            try (var stream = Files.walk(target)) { files = stream.filter(Files::isRegularFile).sorted().toList(); }
            check("115 product resource files incl new atlas", files.size() == 115);
            int jsonCount = 0;
            Set<String> spriteIds = atlasSprites();
            check("43 custom atlas sprites", spriteIds.size() == 43);
            for (Path file : files) {
                String path = target.relativize(file).toString().replace('\\', '/');
                if (path.endsWith(".png")) { decodePng(file, path); continue; }
                if (!path.endsWith(".json") && !path.endsWith(".mcmeta")) continue;
                jsonCount++; uniqueKeys(file);
                JsonObject object = json(file);
                if (path.contains("/blockstates/")) {
                    check("variants object " + path, object.has("variants"));
                    walkModels(path, object);
                } else if (path.contains("/models/")) {
                    String modelId = "simplerail:" + path.substring("assets/simplerail/models/".length()).replace(".json", "");
                    modelCache.put(modelId, object);
                    if (object.has("parent")) ref(modelId, "model", object.get("parent").getAsString());
                    if (object.has("textures")) object.getAsJsonObject("textures").entrySet().forEach(texture -> {
                        String value = texture.getValue().getAsString();
                        if (!value.startsWith("#")) ref(modelId, "texture", value);
                    });
                }
            }
            check("70 JSON/mcmeta parsed", jsonCount == 70);
            check("45 PNGs fully decoded including logo", pngs.size() == 45);
            for (String root : new TreeSet<>(modelCache.keySet())) {
                Model resolved = resolve(root, new LinkedHashSet<>());
                for (String alias : resolved.textures.keySet()) resolveTexture(root, alias, resolved.textures, new HashSet<>(), spriteIds);
                if (resolved.elements != null) for (JsonElement element : resolved.elements) {
                    JsonObject part = element.getAsJsonObject();
                    check("element from/to " + root, part.getAsJsonArray("from").size() == 3 && part.getAsJsonArray("to").size() == 3);
                    for (var face : part.getAsJsonObject("faces").entrySet()) {
                        String texture = face.getValue().getAsJsonObject().get("texture").getAsString();
                        if (texture.startsWith("#")) resolveTexture(root, texture.substring(1), resolved.textures, new HashSet<>(), spriteIds);
                        else ref(root, "texture", texture);
                    }
                }
            }
            Set<String> reachable = new HashSet<>();
            for (String item : items) {
                String root = item.replace("simplerail:", "simplerail:item/");
                check("registered item model " + item, exists(root, "model")); visit(root, reachable, new HashSet<>());
            }
            for (String block : blocks) walkRootModels(json(target.resolve(asset(block, "blockstates", ".json"))), reachable);
            Set<String> unusedItems = new TreeSet<>();
            for (String model : modelCache.keySet()) if (model.startsWith("simplerail:item/") && !reachable.contains(model)) unusedItems.add(model);
            check("only preserved extra item model unreachable", unusedItems.equals(Set.of("simplerail:item/oneway_reverse_rail")));
            checkLanguages(blocks);
            checkCoverage(blocks);
            check("no fake wrench blockstate registration", !blocks.contains("simplerail:wrench") && Files.exists(target.resolve("assets/simplerail/blockstates/wrench.json")));
            check("entity texture 96x64", pngs.stream().anyMatch(p -> p.get("path").equals("assets/simplerail/textures/entity/locomotive_cart.png") && p.get("width").equals(96) && p.get("height").equals(64)));
            check("logo 512x512", pngs.stream().anyMatch(p -> p.get("path").equals("logo.png") && p.get("width").equals(512) && p.get("height").equals(512)));
            write("resource-map.json", mappings); write("references.json", references); write("pngs.json", pngs); write("state-coverage.json", coverage);
            write("audit-results.json", Map.of("scope", "standalone JSON/PNG/path checks; no Minecraft codecs, model baking, atlas stitching or runtime registry", "checks", checks, "failures", failures, "passed", checks.stream().filter(c -> Boolean.TRUE.equals(c.get("passed"))).count(), "failed", failures.size(), "counts", counts, "sourceCount", 144, "migratedSourceCount", migrated, "deferredT022", deferred, "excludedForgeMetadata", excluded));
        }
        System.out.println("Resource audit: " + checks.size() + " checks, " + failures.size() + " failures; " + references.size() + " reference checks; 45 decoded PNGs.");
        for (String failure : failures) System.err.println(failure);
        if (!failures.isEmpty()) System.exit(1);
    }

    private record Model(Map<String,String> textures, JsonArray elements) {}
    private static Model resolve(String id, Set<String> stack) throws Exception {
        id = canonical(id);
        if (id.startsWith("minecraft:builtin/")) return new Model(new LinkedHashMap<>(), null);
        if (!stack.add(id)) { check("no model inheritance cycle " + id, false); return new Model(new LinkedHashMap<>(), null); }
        JsonObject object = modelCache.get(id);
        if (object == null) {
            String path = asset(id, "models", ".json");
            if (id.startsWith("simplerail:")) object = json(target.resolve(path));
            else try (Reader reader = new InputStreamReader(vanilla.getInputStream(vanilla.getEntry(path)), StandardCharsets.UTF_8)) { object = JsonParser.parseReader(reader).getAsJsonObject(); }
        }
        Model parent = object.has("parent") ? resolve(object.get("parent").getAsString(), stack) : new Model(new LinkedHashMap<>(), null);
        Map<String,String> textures = new LinkedHashMap<>(parent.textures);
        if (object.has("textures")) object.getAsJsonObject("textures").entrySet().forEach(e -> textures.put(e.getKey(), e.getValue().getAsString()));
        stack.remove(id);
        return new Model(textures, object.has("elements") ? object.getAsJsonArray("elements") : parent.elements);
    }
    private static void resolveTexture(String model, String alias, Map<String,String> textures, Set<String> stack, Set<String> sprites) {
        if (!stack.add(alias)) { check("no texture alias cycle " + model + "#" + alias, false); return; }
        String value = textures.get(alias);
        check("texture alias resolved " + model + "#" + alias, value != null);
        if (value == null) return;
        if (value.startsWith("#")) resolveTexture(model, value.substring(1), textures, stack, sprites);
        else {
            ref(model, "texture", value);
            if (canonical(value).startsWith("simplerail:")) check("custom model texture in atlas " + value, sprites.contains(canonical(value)));
        }
    }
    private static Set<String> atlasSprites() throws Exception {
        JsonArray sources = json(target.resolve("assets/minecraft/atlases/blocks.json")).getAsJsonArray("sources");
        check("atlas additive sources, no replace field", sources.size() == 2 && !json(target.resolve("assets/minecraft/atlases/blocks.json")).has("replace"));
        Set<String> sprites = new TreeSet<>(), groups = new TreeSet<>();
        for (JsonElement entry : sources) {
            JsonObject source = entry.getAsJsonObject(); String directory = source.get("source").getAsString();
            check("namespaced atlas source " + directory, source.get("type").getAsString().equals("neoforge:namespaced_directory") && source.get("namespace").getAsString().equals("simplerail") && source.get("prefix").getAsString().equals(directory + "/"));
            groups.add(directory);
            Path folder = target.resolve("assets/simplerail/textures/" + directory);
            try (var files = Files.walk(folder)) { files.filter(p -> p.toString().endsWith(".png")).forEach(p -> sprites.add("simplerail:" + directory + "/" + folder.relativize(p).toString().replace('\\', '/').replace(".png", ""))); }
        }
        check("plural texture directories preserved", groups.equals(Set.of("blocks", "items")));
        return sprites;
    }
    private static void checkLanguages(Set<String> blocks) throws Exception {
        JsonObject en = json(target.resolve("assets/simplerail/lang/en_us.json")), zh = json(target.resolve("assets/simplerail/lang/zh_tw.json"));
        Set<String> required = new HashSet<>(Set.of("_comment", "itemGroup.simplerail.tab", "item.simplerail.wrench", "item.simplerail.locomotive_cart"));
        for (String block : blocks) required.add("block." + block.replace(':', '.'));
        check("15 language keys in both locales", en.keySet().equals(required) && zh.keySet().equals(required));
        for (String key : required) check("non-empty translation " + key, !en.get(key).getAsString().isBlank() && !zh.get(key).getAsString().isBlank());
    }
    private static void checkCoverage(Set<String> blocks) throws Exception {
        JsonObject contract = json(Path.of("docs/evidence/T-010/state-domains.json"));
        JsonObject domains = contract.getAsJsonObject("domains");
        for (JsonElement entry : contract.getAsJsonArray("blocks")) {
            JsonObject row = entry.getAsJsonObject(); String id = row.get("id").getAsString();
            if (!blocks.contains(id)) continue;
            JsonObject variants = json(target.resolve(asset(id, "blockstates", ".json"))).getAsJsonObject("variants");
            List<Map<String,String>> selectors = new ArrayList<>();
            for (String key : variants.keySet()) {
                Map<String,String> selector = selector(key); selectors.add(selector);
                for (var clause : selector.entrySet()) {
                    JsonElement type = row.getAsJsonObject("properties").get(clause.getKey());
                    check("variant property/value matches T-010 " + id + " " + clause, type != null && strings(domains.getAsJsonArray(type.getAsString())).contains(clause.getValue()));
                }
            }
            List<Map<String,String>> combinations = new ArrayList<>(); combinations.add(new LinkedHashMap<>());
            for (var property : row.getAsJsonObject("properties").entrySet()) {
                List<Map<String,String>> next = new ArrayList<>();
                for (var state : combinations) for (JsonElement value : domains.getAsJsonArray(property.getValue().getAsString())) {
                    Map<String,String> expanded = new LinkedHashMap<>(state); expanded.put(property.getKey(), value.getAsString()); next.add(expanded);
                }
                combinations = next;
            }
            int matches = 0, overlaps = 0; List<Map<String,String>> missing = new ArrayList<>();
            for (var state : combinations) {
                long count = selectors.stream().filter(s -> state.entrySet().containsAll(s.entrySet())).count();
                if (count > 0) matches++; else if (missing.size() < 4) missing.add(state);
                if (count > 1) overlaps++;
            }
            check("variant selectors have no overlapping match " + id, overlaps == 0);
            coverage.add(Map.of("id", id, "candidateDeclaredCombinations", combinations.size(), "matched", matches, "uncovered", combinations.size() - matches, "uncoveredExamples", missing, "plainT019SkeletonHasRequiredProperties", selectors.stream().allMatch(Map::isEmpty), "scope", "candidate domains only, not runtime; gaps retain OLD resource behavior and require feature/pack readiness decisions"));
        }
    }
    private static Map<String,String> selector(String key) {
        Map<String,String> result = new LinkedHashMap<>();
        if (!key.isEmpty()) for (String clause : key.split(",")) { String[] fields = clause.split("=", 2); result.put(fields[0], fields[1]); }
        return result;
    }
    private static void decodePng(Path file, String path) throws Exception {
        BufferedImage image = ImageIO.read(file.toFile()); check("PNG fully decoded " + path, image != null);
        if (image == null) return;
        int transparent = 0;
        for (int y = 0; y < image.getHeight(); y++) for (int x = 0; x < image.getWidth(); x++) if ((image.getRGB(x,y) >>> 24) == 0) transparent++;
        pngs.add(Map.of("path", path, "width", image.getWidth(), "height", image.getHeight(), "transparentPixels", transparent, "sha256", hash(file)));
    }
    private static void walkModels(String from, JsonElement element) {
        if (element.isJsonObject()) {
            JsonObject object = element.getAsJsonObject();
            if (object.has("model")) ref(from, "model", object.get("model").getAsString());
            for (String axis : List.of("x", "y")) if (object.has(axis)) check("quarter-turn rotation " + from, Math.floorMod(object.get(axis).getAsInt(), 360) % 90 == 0);
            object.entrySet().forEach(e -> walkModels(from, e.getValue()));
        } else if (element.isJsonArray()) element.getAsJsonArray().forEach(e -> walkModels(from, e));
    }
    private static void walkRootModels(JsonElement element, Set<String> reachable) {
        if (element.isJsonObject()) {
            JsonObject object = element.getAsJsonObject(); if (object.has("model")) visit(canonical(object.get("model").getAsString()), reachable, new HashSet<>());
            object.entrySet().forEach(e -> walkRootModels(e.getValue(), reachable));
        } else if (element.isJsonArray()) element.getAsJsonArray().forEach(e -> walkRootModels(e, reachable));
    }
    private static void visit(String at, Set<String> visited, Set<String> stack) {
        if (stack.contains(at)) { check("model graph acyclic " + at, false); return; }
        if (!visited.add(at)) return;
        stack.add(at); for (String next : edges.getOrDefault(at, Set.of())) visit(next, visited, stack); stack.remove(at);
    }
    private static void ref(String from, String kind, String id) {
        id = canonical(id); boolean found = exists(id, kind);
        references.add(Map.of("from", from, "kind", kind, "id", id, "exists", found)); check("resolved " + kind + " " + id + " from " + from, found);
        if (kind.equals("model")) edges.computeIfAbsent(from, ignored -> new TreeSet<>()).add(id);
    }
    private static boolean exists(String id, String kind) {
        if (id.startsWith("minecraft:builtin/")) return true;
        String path = asset(id, kind.equals("model") ? "models" : "textures", kind.equals("model") ? ".json" : ".png");
        return Files.isRegularFile(target.resolve(path)) || vanilla.getEntry(path) != null;
    }
    private static String canonical(String id) { return id.contains(":") ? id : "minecraft:" + id; }
    private static String asset(String id, String folder, String suffix) { String[] parts = canonical(id).split(":",2); return "assets/" + parts[0] + "/" + folder + "/" + parts[1] + suffix; }
    private static Set<String> strings(JsonArray array) { Set<String> result = new TreeSet<>(); array.forEach(v -> result.add(v.getAsString())); return result; }
    private static JsonObject json(Path path) throws IOException { return JsonParser.parseString(Files.readString(path, StandardCharsets.UTF_8)).getAsJsonObject(); }
    private static String hash(Path path) throws Exception { return HexFormat.of().withUpperCase().formatHex(MessageDigest.getInstance("SHA-256").digest(Files.readAllBytes(path))); }
    private static void check(String description, boolean passed) { checks.add(Map.of("check", description, "passed", passed)); if (!passed) failures.add(description); }
    private static void write(String file, Object value) throws IOException { Files.writeString(evidence.resolve(file), GSON.toJson(value)); }
    private static void uniqueKeys(Path file) throws IOException {
        try (JsonReader reader = new JsonReader(Files.newBufferedReader(file, StandardCharsets.UTF_8))) { scan(reader, file.toString()); check("strict JSON no trailing token " + file, reader.peek() == JsonToken.END_DOCUMENT); }
    }
    private static void scan(JsonReader reader, String path) throws IOException {
        switch (reader.peek()) {
            case BEGIN_OBJECT -> { reader.beginObject(); Set<String> keys = new HashSet<>(); while (reader.hasNext()) { String name = reader.nextName(); check("no duplicate JSON key " + path + "/" + name, keys.add(name)); scan(reader, path + "/" + name); } reader.endObject(); }
            case BEGIN_ARRAY -> { reader.beginArray(); while (reader.hasNext()) scan(reader, path + "[]"); reader.endArray(); }
            case STRING, NUMBER -> reader.nextString();
            case BOOLEAN -> reader.nextBoolean();
            case NULL -> reader.nextNull();
            default -> throw new IOException("Invalid JSON token at " + path);
        }
    }
}
