package com.ericchiu.simplerail.entity;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import com.ericchiu.simplerail.SimpleRail;
import com.ericchiu.simplerail.registry.ModEntityDataSerializers;
import com.ericchiu.simplerail.registry.ModEntityTypes;

import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.StringTag;
import net.minecraft.nbt.Tag;
import net.minecraft.network.syncher.EntityDataAccessor;
import net.minecraft.network.syncher.EntityDataSerializers;
import net.minecraft.network.syncher.SynchedEntityData;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.damagesource.DamageSource;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.entity.vehicle.AbstractMinecart;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.Level;
import net.minecraft.world.phys.Vec3;

public class LocomotiveEntity extends AbstractMinecart {

  // 定義同步資料的 Key (DataParameter 改名為 EntityDataAccessor)
  private static final EntityDataAccessor<FacingDirection> FACING = 
    SynchedEntityData.defineId(LocomotiveEntity.class, ModEntityDataSerializers.FACING_DIRECTION.get());
  
  // (先預留 LINKABLE，目前以方向為主)
  private static final EntityDataAccessor<Boolean> LINKABLE = 
    SynchedEntityData.defineId(LocomotiveEntity.class, EntityDataSerializers.BOOLEAN);

  public LocomotiveEntity(EntityType<?> entityType, Level level) {
    super(entityType, level);
  }

  // 實作必填的抽象方法，告訴遊戲這是哪種原版類型的礦車
  @Override
  public AbstractMinecart.Type getMinecartType() {
    // 因為是火車頭，所以回傳 FURNACE 類型比較合適（原版的熔爐礦車也是不能載人的）
    return AbstractMinecart.Type.FURNACE;
  }

  // 指定破壞時掉落的物品
  @Override
  protected Item getDropItem() {
    return ModEntityTypes.LOCOMOTIVE_ITEM.get();
  }

  // 覆寫此方法，禁止任何實體 (包含玩家或動物) 乘坐此礦車
  @Override
  protected boolean canAddPassenger(Entity passenger) {
    return false;
  }

  // 攔截玩家右鍵互動，回傳 PASS 避免觸發原版礦車的乘坐邏輯
  @Override
  public InteractionResult interact(Player player, InteractionHand hand) {
    return InteractionResult.PASS;
  }

  // 實作 defineSynchedData，初始化同步資料的預設值
  @Override
  protected void defineSynchedData(SynchedEntityData.Builder builder) {
    super.defineSynchedData(builder);
    builder.define(FACING, FacingDirection.NORTH);
    builder.define(LINKABLE, true);
  }

  // 在每次 tick 時更新方向與產生粒子
  @Override
  public void tick() {
    super.tick();
    
    // 只在伺服器端計算邏輯，同步給客戶端
    if (!this.level().isClientSide) {
      this.updateFacingDirection();
      this.runLinkageManager();
    }
  }

  @Override
  public void destroy(DamageSource source) {
    super.destroy(source);
    // 當火車頭被摧毀時，斷開所有車廂的連結
    this.disconnectTrainFrom(0);
  }

  // 方向更新邏輯（根據移動向量判斷方向，並隨機產生煙霧粒子）
  private void updateFacingDirection() {
    Vec3 motion = this.getDeltaMovement();
    // 檢查是否在移動，如果沒有移動就不更新方向
    if (motion.x == 0 && motion.y == 0 && motion.z == 0) return;

    // 隨機產生煙霧粒子
    if (!this.onGround() && this.random.nextInt(4) == 0) {
      // 1.21.1 的 particle API
      this.level().addParticle(ParticleTypes.LARGE_SMOKE, 
          this.getX(), this.getY() + 1.5D, this.getZ(), 
          0.0D, 0.0D, 0.0D);
    }

    // 判斷移動向量並更新朝向
    FacingDirection currentFacing = this.entityData.get(FACING);
    if (motion.x > 0 && motion.z == 0 && currentFacing != FacingDirection.EAST) {
      this.entityData.set(FACING, FacingDirection.EAST);
    } else if (motion.x < 0 && motion.z == 0 && currentFacing != FacingDirection.WEST) {
      this.entityData.set(FACING, FacingDirection.WEST);
    } else if (motion.x == 0 && motion.z < 0 && currentFacing != FacingDirection.NORTH) {
      this.entityData.set(FACING, FacingDirection.NORTH);
    } else if (motion.x == 0 && motion.z > 0 && currentFacing != FacingDirection.SOUTH) {
      this.entityData.set(FACING, FacingDirection.SOUTH);
    } else if (motion.x > 0 && motion.z < 0 && currentFacing != FacingDirection.NORTH_EAST) {
      this.entityData.set(FACING, FacingDirection.NORTH_EAST);
    } else if (motion.x < 0 && motion.z < 0 && currentFacing != FacingDirection.NORTH_WEST) {
      this.entityData.set(FACING, FacingDirection.NORTH_WEST);
    } else if (motion.x > 0 && motion.z > 0 && currentFacing != FacingDirection.SOUTH_EAST) {
      this.entityData.set(FACING, FacingDirection.SOUTH_EAST);
    } else if (motion.x < 0 && motion.z > 0 && currentFacing != FacingDirection.SOUTH_WEST) {
      this.entityData.set(FACING, FacingDirection.SOUTH_WEST);
    }
  }

  // 給 Renderer 取用方向的 Getter
  public FacingDirection getFacingDirection() {
    return this.entityData.get(FACING);
  }

  // Linkage Manager
  // 理想距離（當車廂之間的距離超過這個值時，才會開始施加牽引力）
  private static final double IDEAL_CART_DISTANCE = 1.25D;
  // 死區距離（當車廂之間的距離介於 IDEAL_CART_DISTANCE - DEADZONE < distance < IDEAL_CART_DISTANCE + DEADZONE 時，不會施加牽引力，避免過度震動）
  private static final double DEADZONE = 0.1D;
  // 最大牽引力（當距離非常大時，牽引力不會無限制增大，這個值可以微調以達到想要的手感）
  private static final double MAX_PULL_STRENGTH = 1.0D;
  // 彈性係數
  private static final double PULL_STRENGTH_MULTIPLIER = 0.3D;
  // 礦車連結的最大距離（如果距離超過這個值，就斷開連結）
  private static final double MAX_SNAP_DISTANCE = 8.0D;
  
  // ==========================================
  // 火車資料封裝類別
  // ==========================================
  public static class TrainCar {
    public final UUID uuid;
    public AbstractMinecart entity; // 允許為 null，因為地圖讀取時實體可能還沒載入

    public TrainCar(UUID uuid, AbstractMinecart entity) {
      this.uuid = uuid;
      this.entity = entity;
    }
  }
  private final List<TrainCar> train = new ArrayList<>();

  private void runLinkageManager() {    
    // 每一 Tick 都執行牽引邏輯
    this.pullCarts();
  }

  // ==========================================
  // 核心演算法：彈簧向量牽引
  // ==========================================
  private void pullCarts() {
    if (this.train.isEmpty()) return;

    // 領導者 (第一節車廂的領導者就是火車頭自己)
    Entity leader = this;
    ServerLevel serverLevel = (ServerLevel) this.level();

    for (int i = 0; i < this.train.size(); i++) {
      TrainCar follower = this.train.get(i);

      // 1. 嘗試解析 Entity (如果剛讀檔，entity 會是 null)
      if (follower.entity == null) {
        Entity entityInWorld = serverLevel.getEntity(follower.uuid);
        if (entityInWorld instanceof AbstractMinecart cart) {
          follower.entity = cart; // 成功找到並綁定實體
        } else {
          // 如果找不到 (可能是區塊還沒載入)，就先跳過牽引，不要刪除它
          break; 
        }
      }
      
      // 如果跟隨的車廂被玩家打掉或消失了，從此處斷開連結
      AbstractMinecart followerEntity = follower.entity;
      if (followerEntity.isRemoved()) {
        this.disconnectTrainFrom(i);
        break;
      }

      // 2. 取得精確的浮點數向量 (Vec3)
      Vec3 leaderPos = leader.position();
      Vec3 followerPos = followerEntity.position();
      // 3. 計算兩車直線距離
      double distance = followerPos.distanceTo(leaderPos);

      // 斷鍊保護：距離異常(如傳送)時自動脫鉤
      if (distance > MAX_SNAP_DISTANCE) {
        this.disconnectTrainFrom(i);
        break;
      }

      // 計算誤差值
      double distanceError = distance - IDEAL_CART_DISTANCE;

      // 4. 如果距離被拉開 (超過理想距離)
      if (Math.abs(distanceError) > DEADZONE) {
        // 計算從後車指向前車的「方向向量」，並將長度單位化 (normalize)
        Vec3 pullDirection = leaderPos.subtract(followerPos).normalize();
        
        // 彈力計算 (PULL_STRENGTH_MULTIPLIER 是彈力常數)
        double pullStrength = distanceError * PULL_STRENGTH_MULTIPLIER;
        // 限制最大力量，避免推拉力道過猛導致脫軌 (使用 Mth.clamp 限制範圍)
        pullStrength = net.minecraft.util.Mth.clamp(pullStrength, -MAX_PULL_STRENGTH, MAX_PULL_STRENGTH);
        
        // 取得後車當前的速度
        Vec3 currentMotion = followerEntity.getDeltaMovement();
        
        // 因為我們是修改 DeltaMovement，遊戲底層的鐵軌判定會自動把這個力量修正為沿著鐵軌滑行
        // 如果 strength 為負 (距離過近，例如火車倒車)，會自動變成推力
        followerEntity.setDeltaMovement(currentMotion.add(pullDirection.scale(pullStrength)));
      }else {
        // 如果距離在完美範圍內，直接賦予與前車相同的速度，避免抽搐抖動
        followerEntity.setDeltaMovement(leader.getDeltaMovement());
      }

      // 下一節車廂的領導者，就是當前的這節車廂
      leader = followerEntity;
    }
  }

  // ==========================================
  // 連結與脫鉤用的 APIs
  // ==========================================
  private static final String TRAIN_TAG_PREFIX = SimpleRail.MODID + ":locomotive:";

  // 從礦車的 Tag 中解析出火車頭的 UUID，如果沒有找到就回傳 null
  public static UUID getLocotiveUuid(String tag) {
    if (!tag.startsWith(TRAIN_TAG_PREFIX)) return null;
    try {
      return UUID.fromString(tag.substring(TRAIN_TAG_PREFIX.length()));
    } catch (IllegalArgumentException e) {
      return null;
    }
  }

  // 連結 API
  public boolean linkNewCart(AbstractMinecart cart) {
    if (!this.entityData.get(LINKABLE)) return false;

    // 避免自己連結自己
    if (cart == this) return false;
    // 避免重複連結
    for (TrainCar c : this.train) {
      if (c.uuid.equals(cart.getUUID())) return false;
    }

    // 將 UUID 與實體一起包裝並加入陣列
    this.train.add(new TrainCar(cart.getUUID(), cart));
    // 將被連結的礦車加上 Tag
    cart.getTags().removeIf(tag -> tag.startsWith(TRAIN_TAG_PREFIX));
    cart.addTag(this.getTag());
    return true;
  }

  // 脫鉤 API
  public void unlinkCart(AbstractMinecart cart) {
    for (int i = 0; i < this.train.size(); i++) {
      if (this.train.get(i).uuid.equals(cart.getUUID())) {
        this.disconnectTrainFrom(i);
        break;
      }
    }
  }

  private void disconnectTrainFrom(int index) {
    if (index >= 0 && index < this.train.size()) {
      // 斷開連結時，移除礦車的 Tag
      for (int i = index; i < this.train.size(); i++) {
        AbstractMinecart cart = this.train.get(i).entity;
        if (cart != null) cart.removeTag(this.getTag());
      }
      
      this.train.subList(index, this.train.size()).clear();
    }
  }

  private String getTag() {
    return TRAIN_TAG_PREFIX + this.getUUID().toString();
  }

  // 回傳火車最後一節車廂的實體，如果沒有車廂就回傳火車頭自己
  public AbstractMinecart getLastCart() {
    if (this.train.isEmpty()) return this;
    
    // 從陣列尾端往前找，找到第一個已經載入的實體
    for (int i = this.train.size() - 1; i >= 0; i--) {
      if (this.train.get(i).entity != null) {
        return this.train.get(i).entity;
      }
    }
    return this;
  }

  // ==========================================
  // NBT 存檔與讀檔
  // ==========================================
  private static final String FACING_KEY = "LocomotiveFacing";
  private static final String TRAIN_UUIDS_KEY = "TrainUUIDs";

  @Override
  protected void readAdditionalSaveData(CompoundTag nbt) {
    super.readAdditionalSaveData(nbt);
    
    if (nbt.contains(FACING_KEY)) {
      this.entityData.set(FACING, FacingDirection.valueOf(nbt.getString(FACING_KEY)));
    }

    // 讀檔時，只先存入 UUID，Entity 設為 null (因為其他車廂可能還沒被遊戲生成出來)
    this.train.clear();
    if (nbt.contains(TRAIN_UUIDS_KEY, Tag.TAG_LIST)) {
      ListTag listTag = nbt.getList(TRAIN_UUIDS_KEY, Tag.TAG_STRING);
      for (int i = 0; i < listTag.size(); i++) {
        UUID uuid = UUID.fromString(listTag.getString(i));
        this.train.add(new TrainCar(uuid, null));
      }
    }
  }

  @Override
  protected void addAdditionalSaveData(CompoundTag nbt) {
    super.addAdditionalSaveData(nbt);
    
    nbt.putString(FACING_KEY, this.entityData.get(FACING).name());

    // 存檔時，只抽出 UUID 儲存
    ListTag listTag = new ListTag();
    for (TrainCar car : this.train) {
      listTag.add(StringTag.valueOf(car.uuid.toString()));
    }
    nbt.put(TRAIN_UUIDS_KEY, listTag);
  }
}