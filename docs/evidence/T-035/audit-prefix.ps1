$ErrorActionPreference='Stop'
$e=Join-Path (Get-Location) 'docs/evidence/T-035'
$checks=@();function Check([string]$name,[bool]$pass){$script:checks += [ordered]@{name=$name;pass=$pass}}
$before=Get-Content -Raw -Encoding UTF8 ($e+'/inputs-before.json')|ConvertFrom-Json
$changed=@($before|Where-Object {(Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256})
$allowed=(Join-Path (Get-Location) 'src/main/java/com/ericchiu/simplerail/registry/ModItems.java').Replace('/','\')
Check 'Only ModItems changed among prior product/Gradle/resource inputs' ($changed.Count -eq 1 -and $changed[0].path -eq $allowed)
$new=@(Get-ChildItem src -Recurse -File|Where-Object {$before.path -notcontains $_.FullName})
Check 'Only Wrench production file added' ($new.Count -eq 1 -and $new[0].Name -eq 'Wrench.java')
$wrench=Get-Content -Raw -Encoding UTF8 src/main/java/com/ericchiu/simplerail/item/Wrench.java
Check 'Client success before server access; non-server safe pass' ($wrench.IndexOf('if (level.isClientSide)') -lt $wrench.IndexOf('server.getBlockState(pos)') -and $wrench.Contains('return InteractionResult.SUCCESS') -and $wrench.Contains('return InteractionResult.PASS'))
Check 'Server consumes action without item mutation' ($wrench.Contains('return InteractionResult.CONSUME') -and $wrench -notmatch '\.shrink\(|hurtAndBreak|setCount|setDamage')
Check 'Rail gate uses clicked-cell AABB and no cart' ($wrench.Contains('state.is(ModTags.RAILS)') -and $wrench.Contains('getEntitiesOfClass(AbstractMinecart.class, new AABB(pos)).isEmpty()'))
Check 'Machines are independent of rail occupancy gate' ($wrench.Contains('if (state.is(ModTags.MACHINES))') -and $wrench.IndexOf('if (state.is(ModTags.MACHINES))') -gt $wrench.IndexOf('rotate(state, "direction")'))
Check 'Actual property instances resolved by StateDefinition name' ($wrench.Contains('getStateDefinition().getProperty("reverse")') -and $wrench.Contains('getStateDefinition().getProperty("level")') -and $wrench.Contains('getStateDefinition().getProperty(name)') -and $wrench -notmatch 'BooleanProperty.create|IntegerProperty.create|EnumProperty.create')
Check 'Boolean reverse type guard' ($wrench.Contains('property instanceof BooleanProperty reverse'))
Check 'Level range 0-9 and wrap 9 to 0' ($wrench.Contains('property instanceof IntegerProperty level') -and $wrench.Contains('getPossibleValues().size() == 10') -and $wrench.Contains('getPossibleValues().contains(0)') -and $wrench.Contains('getPossibleValues().contains(9)') -and $wrench.Contains('current >= 9 ? 0 : current + 1'))
Check 'Direction/facing type, horizontal and possible-value guards' ($wrench.Contains('enumeration.getValueClass() == Direction.class') -and $wrench.Contains('current.getAxis().isHorizontal()') -and $wrench.Contains('current.getClockWise()') -and $wrench.Contains('direction.getPossibleValues().contains(next)'))
Check 'Source-compatible U-09 same-initial-state writes explicitly retained' ($wrench.Contains('writeChange(server, pos, state, toggleReverse(state))') -and $wrench.Contains('writeChange(server, pos, state, cycleLevel(state))') -and $wrench.Contains('writeChange(server, pos, state, rotate(state, "direction"))') -and $wrench.Contains('writeChange(server, pos, state, rotate(state, "facing"))'))
Check 'No-op skips write; updates use flag 3' ($wrench.Contains('if (changed != initial)') -and $wrench.Contains('level.setBlock(pos, changed, Block.UPDATE_ALL)'))
Check 'HOE abilities retained without implementing tilling' ($wrench.Contains('ItemAbilities.DEFAULT_HOE_ACTIONS.contains(ability)') -and $wrench -notmatch 'extends HoeItem')
Check 'No config/BE/NBT/network/linking/neighbor-cell/sound implementation' ($wrench -notmatch 'CommonConfig|CompoundTag|BlockEntity|LinkageManager|linkNewCart|getSecondPos|sendParticles|playSound|SubscribeEvent|Mixin')
$reg=Get-Content -Raw -Encoding UTF8 src/main/java/com/ericchiu/simplerail/registry/ModItems.java
$oldReg=Get-Content -Raw -Encoding UTF8 ($e+'/before/ModItems.java')
$pattern='register(?:SimpleItem|Item|SimpleBlockItem)\("([^"]+)"'
$a=([regex]::Matches($reg,$pattern)|ForEach-Object {$_.Groups[1].Value}) -join ','
$b=([regex]::Matches($oldReg,$pattern)|ForEach-Object {$_.Groups[1].Value}) -join ','
Check 'All 13 item IDs and order preserved' ($a -eq $b -and ([regex]::Matches($reg,$pattern)).Count -eq 13)
Check 'Same wrench ID uses typed Wrench factory' ($reg.Contains('ITEMS.registerItem("wrench", Wrench::new,'))
Check 'Wrench stack 1/common/fire resistant properties unchanged' ($reg.Contains('new Item.Properties().stacksTo(1).rarity(Rarity.COMMON).fireResistant()'))
$rails=Get-Content -Raw -Encoding UTF8 src/main/resources/data/simplerail/tags/block/rails.json|ConvertFrom-Json
$machines=Get-Content -Raw -Encoding UTF8 src/main/resources/data/simplerail/tags/block/machines.json|ConvertFrom-Json
Check 'Unchanged rails nine/machines two block tags, replace false' ($rails.values.Count -eq 9 -and $machines.values.Count -eq 2 -and -not $rails.replace -and -not $machines.replace)
$matrix=@();foreach($reverse in @($false,$true)){$matrix+=[ordered]@{property='reverse';initial=$reverse;isolatedNext=(-not $reverse);gate='rails and clicked cell empty';gameResult=$null}}
foreach($n in 0..9){$matrix+=[ordered]@{property='level';initial=$n;isolatedNext=(($n+1)%10);gate='rails empty, or machines regardless of cart';gameResult=$null}}
foreach($property in @('direction','facing')){foreach($d in @('north','east','south','west','up','down')){$next=switch($d){north{'east'}east{'south'}south{'west'}west{'north'}default{$d}};$matrix+=[ordered]@{property=$property;initial=$d;isolatedNext=$next;gate=$(if($property -eq 'direction'){'rails and clicked cell empty'}else{'machines regardless of cart'});gameResult=$null}}}
$matrix|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 ($e+'/operation-matrix.json')
Check '24 isolated property rows, no fabricated game result' ($matrix.Count -eq 24 -and @($matrix|Where-Object {$null -ne $_.gameResult}).Count -eq 0)
@([ordered]@{case='U09-rail';initial='reverse=false,level=9,direction=north';sourceCompatibleFinal='reverse=false,level=9,direction=east';writes=3;decision='Pending user decision; not fixed';oldStatus='Source-inferred / untested';gameResult=$null},[ordered]@{case='U09-machine';initial='facing=north,level=9';sourceCompatibleFinal='facing=north,level=0';writes=2;decision='Pending user decision; not fixed';oldStatus='Source-inferred / untested';gameResult=$null})|ConvertTo-Json|Set-Content -Encoding UTF8 ($e+'/U09-source-reproduction.json')
$contracts=@(
 @('high_speed_rail','none','implemented rail'),@('holding_rail','direction','implemented rail'),@('oneway_rail','reverse','implemented rail'),@('eject_rail','reverse','implemented rail'),@('destory_rail','none','implemented rail'),
 @('timer_holding_rail','level,direction','placeholder; T-038 pending'),@('cross_rail','none','placeholder; T-066 pending'),@('y_cross_rail','direction','placeholder; T-068 pending'),@('y_cross_right_rail','direction','placeholder; T-070 pending'),@('train_dispenser','facing','placeholder; T-044 pending'),@('signal_timer','level','placeholder; T-041 pending'))
$contracts|ForEach-Object {[ordered]@{id=('simplerail:'+$_[0]);requiredWrenchProperties=$_[1];currentScope=$_[2];gameResult=$null}}|ConvertTo-Json|Set-Content -Encoding UTF8 ($e+'/property-tag-map.json')
Check 'All 11 blocks mapped, future owners explicitly pending' ($contracts.Count -eq 11)
