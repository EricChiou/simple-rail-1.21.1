import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonNull;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;
import com.google.gson.stream.JsonReader;
import com.google.gson.stream.JsonToken;
import java.io.IOException;
import java.io.StringReader;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Pattern;
import java.util.zip.ZipFile;

/** Independent file-contract audit. No Minecraft classes, launcher, registries or codecs. */
public final class DataAudit {
    private static final Gson JSON = new GsonBuilder().setPrettyPrinting().disableHtmlEscaping().create();
    private static final List<JsonObject> CHECKS = new ArrayList<>();
    private static final List<JsonObject> REFERENCES = new ArrayList<>();
    private static final List<JsonObject> RECIPES = new ArrayList<>();
    private static final List<JsonObject> LOOT = new ArrayList<>();
    private static int failed;
    private DataAudit() {}

    private static void check(boolean passed, String text) {
        JsonObject row = new JsonObject(); row.addProperty("passed", passed); row.addProperty("check", text); CHECKS.add(row);
        if (!passed) { failed++; System.err.println("FAIL: " + text); }
    }
    private static JsonElement value(JsonReader reader) throws IOException {
        return switch (reader.peek()) {
            case BEGIN_OBJECT -> {
                reader.beginObject(); JsonObject object = new JsonObject(); Set<String> keys = new HashSet<>();
                while (reader.hasNext()) { String key = reader.nextName(); if (!keys.add(key)) { throw new IOException("Duplicate JSON key: " + key); } object.add(key, value(reader)); }
                reader.endObject(); yield object;
            }
            case BEGIN_ARRAY -> {
                reader.beginArray(); JsonArray array = new JsonArray(); while (reader.hasNext()) { array.add(value(reader)); } reader.endArray(); yield array;
            }
            case STRING -> new JsonPrimitive(reader.nextString());
            case NUMBER -> new JsonPrimitive(new BigDecimal(reader.nextString()));
            case BOOLEAN -> new JsonPrimitive(reader.nextBoolean());
            case NULL -> { reader.nextNull(); yield JsonNull.INSTANCE; }
            default -> throw new IOException("Unexpected JSON token " + reader.peek());
        };
    }
    private static JsonElement parse(String text) throws IOException {
        try (JsonReader reader = new JsonReader(new StringReader(text.replaceFirst("^\\uFEFF", "")))) {
            reader.setLenient(false); JsonElement parsed = value(reader);
            if (reader.peek() != JsonToken.END_DOCUMENT) { throw new IOException("Trailing JSON content"); } return parsed;
        }
    }
    private static JsonObject read(Path path) throws IOException { return parse(Files.readString(path)).getAsJsonObject(); }
    private static Set<String> registry(Path path, String expression) throws IOException {
        Set<String> ids = new LinkedHashSet<>(); var matcher = Pattern.compile(expression).matcher(Files.readString(path));
        while (matcher.find()) { ids.add("simplerail:" + matcher.group(1)); } return ids;
    }
    private static void reference(String file, String id, String kind, boolean found) {
        JsonObject row = new JsonObject(); row.addProperty("file", file); row.addProperty("id", id); row.addProperty("registry", kind); row.addProperty("resolved", found); REFERENCES.add(row);
        check(found, file + " resolves " + kind + " " + id);
    }
    private static List<Path> files(Path path) throws IOException {
        try (var stream = Files.walk(path)) { return stream.filter(Files::isRegularFile).sorted().toList(); }
    }
    private static Set<String> members(JsonObject tag) {
        Set<String> result = new LinkedHashSet<>(); tag.getAsJsonArray("values").forEach(v -> result.add(v.getAsString())); return result;
    }
    private static void write(Path root, String file, Object object) throws IOException { Files.writeString(root.resolve(file), JSON.toJson(object) + "\n"); }

    public static void main(String[] args) throws Exception {
        Path oldRoot = Path.of(args[0]); Path target = Path.of(args[1]); Path evidence = Path.of(args[2]);
        Path javaRoot = Path.of("src/main/java/com/ericchiu/simplerail/registry");
        Set<String> blockIds = registry(javaRoot.resolve("ModBlocks.java"), "register(?:Simple)?Block\\(\"([^\"]+)\"");
        Set<String> itemIds = registry(javaRoot.resolve("ModItems.java"), "register(?:Simple)?(?:Item|BlockItem)\\(\"([^\"]+)\"");
        check(blockIds.size() == 11 && itemIds.size() == 13, "source registry skeleton: 11 blocks and 13 items");
        List<Path> dataFiles = files(target.resolve("data")); check(dataFiles.size() == 29, "29 data files exactly");
        for (Path file : dataFiles) { read(file); check(true, "strict JSON without duplicate keys or trailing content " + target.relativize(file)); }
        check(!Files.exists(target.resolve("data/simplerail/recipes")) && !Files.exists(target.resolve("data/simplerail/loot_tables")), "no legacy plural data directories");
        Set<String> results = new LinkedHashSet<>();
        try (ZipFile vanilla = new ZipFile(args[3])) {
            JsonObject version = parse(new String(vanilla.getInputStream(vanilla.getEntry("version.json")).readAllBytes(), StandardCharsets.UTF_8)).getAsJsonObject();
            check(version.get("id").getAsString().equals("1.21.1"), "vanilla archive version is 1.21.1 (ZIP only)");
            for (Path oldFile : files(oldRoot.resolve("data/simplerail/recipes"))) {
                String name = oldFile.getFileName().toString(); String id = "simplerail:" + name.replace(".json", "");
                JsonObject old = read(oldFile); JsonObject actual = read(target.resolve("data/simplerail/recipe/" + name));
                JsonObject expected = old.deepCopy(); JsonObject result = expected.getAsJsonObject("result"); result.add("id", result.remove("item"));
                check(actual.equals(expected), "recipe preserves entire OLD payload except result key " + id);
                check(actual.get("type").getAsString().equals("minecraft:crafting_shaped"), "shaped recipe type " + id);
                JsonObject output = actual.getAsJsonObject("result"); String outputId = output.get("id").getAsString();
                int count = output.get("count").getAsInt(); results.add(outputId);
                reference(name, outputId, "item", itemIds.contains(outputId));
                check(outputId.equals(id) && count == (id.equals("simplerail:destory_rail") ? 3 : 1), "recipe output identity and quantity " + id);
                check(count <= (id.equals("simplerail:wrench") ? 1 : 64), "output within T-019 stack limit " + id);
                JsonArray pattern = actual.getAsJsonArray("pattern"); JsonObject keys = actual.getAsJsonObject("key");
                check(pattern.size() > 0 && pattern.size() <= 3, "pattern height <= 3 " + id);
                Set<String> used = new LinkedHashSet<>(); int width = pattern.get(0).getAsString().length();
                for (JsonElement row : pattern) {
                    String cells = row.getAsString(); check(cells.length() == width && width > 0 && width <= 3, "rectangular pattern width <= 3 " + id);
                    for (char cell : cells.toCharArray()) { if (cell != ' ') { used.add(String.valueOf(cell)); } }
                }
                check(!used.isEmpty() && used.equals(keys.keySet()), "all pattern symbols bound; no unused key " + id);
                for (var key : keys.entrySet()) {
                    check(key.getKey().length() == 1 && !key.getKey().equals(" "), "single non-space ingredient symbol " + id);
                    JsonObject ingredient = key.getValue().getAsJsonObject(); check(ingredient.keySet().equals(Set.of("item")), "ingredient keeps item field " + id);
                    String material = ingredient.get("item").getAsString(); String[] parts = material.split(":", 2);
                    boolean found = parts[0].equals("minecraft") && vanilla.getEntry("assets/minecraft/models/item/" + parts[1] + ".json") != null;
                    reference(name, material, "vanilla item model/source proxy (not runtime registry)", found);
                }
                JsonObject row = new JsonObject(); row.addProperty("id", id); row.add("pattern", pattern); row.add("ingredients", keys); row.add("result", output); RECIPES.add(row);
            }
            check(RECIPES.size() == 13 && results.equals(itemIds), "all 13 registered item identities have exactly one recipe");
            JsonObject vanillaRails = parse(new String(vanilla.getInputStream(vanilla.getEntry("data/minecraft/tags/block/rails.json")).readAllBytes(), StandardCharsets.UTF_8)).getAsJsonObject();
            Set<String> merged = members(vanillaRails);
            JsonObject extension = read(target.resolve("data/minecraft/tags/block/rails.json")); merged.addAll(members(extension));
            check(merged.containsAll(members(vanillaRails)) && merged.size() == members(vanillaRails).size() + 9, "minecraft:rails additive membership preserves vanilla (static union)");
        }
        Set<String> lootIds = new LinkedHashSet<>();
        for (Path oldFile : files(oldRoot.resolve("data/simplerail/loot_tables"))) {
            String suffix = oldRoot.resolve("data/simplerail/loot_tables").relativize(oldFile).toString().replace('\\','/');
            String id = "simplerail:" + suffix.replace(".json", ""); boolean cart = suffix.equals("blocks/locomotive_cart.json");
            JsonObject old = read(oldFile); JsonObject expected = old.deepCopy();
            if (cart) { expected.getAsJsonArray("pools").get(0).getAsJsonObject().remove("conditions"); }
            JsonObject actual = read(target.resolve("data/simplerail/loot_table/" + suffix));
            check(actual.equals(expected), "loot preserves OLD payload" + (cart ? " except incompatible explosion condition " : " ") + id);
            check(actual.get("type").getAsString().equals(cart ? "minecraft:entity" : "minecraft:block"), "loot context identity preserved " + id);
            JsonArray pools = actual.getAsJsonArray("pools"); check(pools.size() == 1, "one loot pool " + id);
            JsonObject pool = pools.get(0).getAsJsonObject(); check(pool.get("rolls").getAsInt() == 1, "one loot roll " + id);
            JsonArray entries = pool.getAsJsonArray("entries"); check(entries.size() == 1, "one loot entry " + id);
            JsonObject entry = entries.get(0).getAsJsonObject(); String item = entry.get("name").getAsString();
            check(entry.get("type").getAsString().equals("minecraft:item") && item.equals("simplerail:" + oldFile.getFileName().toString().replace(".json", "")), "loot item/pool identity " + id);
            reference(suffix, item, "item", itemIds.contains(item));
            if (!cart) { reference(suffix, item, "block", blockIds.contains(item)); }
            boolean validContext = cart ? !pool.has("conditions") : pool.getAsJsonArray("conditions").size() == 1 && pool.getAsJsonArray("conditions").get(0).getAsJsonObject().get("condition").getAsString().equals("minecraft:survives_explosion");
            check(validContext, "known condition params fit fixed BLOCK/ENTITY context source " + id);
            lootIds.add(id); JsonObject row = new JsonObject(); row.addProperty("id", id); row.addProperty("type", actual.get("type").getAsString()); row.addProperty("item", item); row.addProperty("attachment", cart ? "no automatic consumer; future T-048 Java destroy is sole planned drop path" : "default block loot identity"); LOOT.add(row);
        }
        check(lootIds.size() == 12 && !blockIds.contains("simplerail:locomotive_cart"), "11 block loot tables + extra cart table; no cart block");
        Set<String> rails = new LinkedHashSet<>(blockIds); rails.remove("simplerail:train_dispenser"); rails.remove("simplerail:signal_timer");
        for (String relative : List.of("simplerail/tags/block/rails.json", "simplerail/tags/block/machines.json", "simplerail/tags/item/wrench.json", "minecraft/tags/block/rails.json")) {
            Path file = target.resolve("data/" + relative); JsonObject actual = read(file);
            String oldRelative = relative.replace("/tags/block/", "/tags/blocks/").replace("/tags/item/", "/tags/items/");
            check(actual.equals(read(oldRoot.resolve("data/" + oldRelative))), "tag payload unchanged " + relative);
            check(!actual.get("replace").getAsBoolean(), "tag additive replace=false " + relative);
            Set<String> expected = relative.contains("wrench") ? Set.of("simplerail:wrench") : relative.contains("machines") ? Set.of("simplerail:train_dispenser", "simplerail:signal_timer") : rails;
            Set<String> values = members(actual); check(values.equals(expected) && values.size() == actual.getAsJsonArray("values").size(), "exact tag membership without duplicates " + relative);
            for (String member : values) { reference(relative, member, relative.contains("/item/") ? "item" : "block", (relative.contains("/item/") ? itemIds : blockIds).contains(member)); }
        }
        String tags = Files.readString(javaRoot.resolve("ModTags.java"));
        check(Pattern.compile("TagKey<Item> WRENCH = TagKey.create\\(\\s*Registries.ITEM,", Pattern.MULTILINE).matcher(tags).find(), "WRENCH identity declared with item registry");
        check(Pattern.compile("TagKey<Block> (RAILS|MACHINES) = TagKey.create\\(\\s*Registries.BLOCK,", Pattern.MULTILINE).matcher(tags).results().count() == 2, "RAILS/MACHINES identities declared with block registry");
        check(!tags.contains("net.minecraft.client") && !tags.contains("registerConfig") && !tags.contains("DeferredRegister"), "tag keys introduce no client classes/config/registry objects");
        JsonObject report = new JsonObject(); report.addProperty("scope", "strict file/source contracts only; no Minecraft codec/context execution/reload/game"); report.addProperty("passed", CHECKS.size() - failed); report.addProperty("failed", failed); report.addProperty("dataFiles", dataFiles.size()); report.addProperty("references", REFERENCES.size()); report.add("checks", JSON.toJsonTree(CHECKS));
        write(evidence, "audit-results.json", report); write(evidence, "references.json", REFERENCES); write(evidence, "recipes.json", RECIPES); write(evidence, "loot-responsibility.json", LOOT);
        System.out.printf("Data contract audit: %d passed, %d failed; 13 recipes, 12 loot, 4 tags, %d references%n", CHECKS.size() - failed, failed, REFERENCES.size());
        if (failed > 0) { System.exit(1); }
    }
}
