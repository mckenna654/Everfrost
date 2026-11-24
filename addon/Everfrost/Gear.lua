local _, NS = ...
local G = {items={}, bags={}, carried={}, equipment={}, rolls={}, pending=true, enabled=true}
NS.Gear = G
local function public(v, kind) return NS.Public(v) and type(v)==kind end
local function itemAPI(name) return C_Item and C_Item[name] or _G[name] end
local function first(fn, ...)
 local r=NS.Call(fn,...); return r and r[1]
end
local slots = {
 INVTYPE_HEAD={1},INVTYPE_NECK={2},INVTYPE_SHOULDER={3},INVTYPE_CHEST={5},INVTYPE_ROBE={5},
 INVTYPE_WAIST={6},INVTYPE_LEGS={7},INVTYPE_FEET={8},INVTYPE_WRIST={9},INVTYPE_HAND={10},
 INVTYPE_FINGER={11,12},INVTYPE_TRINKET={13,14},INVTYPE_CLOAK={15},
 INVTYPE_WEAPON={16},INVTYPE_WEAPONMAINHAND={16},INVTYPE_2HWEAPON={16},
 INVTYPE_WEAPONOFFHAND={17},INVTYPE_SHIELD={17},INVTYPE_HOLDABLE={17},
 INVTYPE_RANGED={18},INVTYPE_RANGEDRIGHT={18},INVTYPE_THROWN={18},INVTYPE_RELIC={18},
}
local armorMax={MAGE=1,PRIEST=1,WARLOCK=1,ROGUE=2,DRUID=2,HUNTER=2,SHAMAN=2,PALADIN=3,WARRIOR=3}
-- At 40 Warriors and Paladins train plate, and Hunters and Shamans train mail.
local armorMaxAt40={HUNTER=3,SHAMAN=3,PALADIN=4,WARRIOR=4}
local function heaviestArmor(class, level)
 return level>=40 and armorMaxAt40[class] or armorMax[class] or 0
end
local weaponTypes={
 WARRIOR={[0]=true,[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true,[10]=true,[13]=true,[15]=true,[16]=true,[18]=true},
 PALADIN={[0]=true,[1]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true},
 HUNTER={[0]=true,[1]=true,[2]=true,[3]=true,[6]=true,[7]=true,[8]=true,[10]=true,[13]=true,[15]=true,[16]=true,[18]=true},
 ROGUE={[0]=true,[2]=true,[3]=true,[4]=true,[7]=true,[13]=true,[15]=true,[16]=true,[18]=true},
 PRIEST={[4]=true,[10]=true,[15]=true,[19]=true},MAGE={[7]=true,[10]=true,[15]=true,[19]=true},
 WARLOCK={[7]=true,[10]=true,[15]=true,[19]=true},DRUID={[4]=true,[5]=true,[6]=true,[10]=true,[13]=true,[15]=true},
 SHAMAN={[0]=true,[1]=true,[4]=true,[5]=true,[10]=true,[13]=true,[15]=true},
}
local stats={
 strength={"ITEM_MOD_STRENGTH_SHORT"},agility={"ITEM_MOD_AGILITY_SHORT"},intellect={"ITEM_MOD_INTELLECT_SHORT"},
 stamina={"ITEM_MOD_STAMINA_SHORT"},spirit={"ITEM_MOD_SPIRIT_SHORT"},armor={"RESISTANCE0_NAME","ITEM_MOD_ARMOR_SHORT"},
 spell={"ITEM_MOD_SPELL_POWER_SHORT","ITEM_MOD_SPELL_POWER","ITEM_MOD_SPELL_DAMAGE_DONE_SHORT","ITEM_MOD_SPELL_DAMAGE_DONE"},
 healing={"ITEM_MOD_SPELL_HEALING_DONE_SHORT","ITEM_MOD_SPELL_HEALING_DONE"},
 mp5={"ITEM_MOD_POWER_REGEN0_SHORT","ITEM_MOD_MANA_REGENERATION_SHORT"},
 attack={"ITEM_MOD_ATTACK_POWER_SHORT","ITEM_MOD_ATTACK_POWER","ITEM_MOD_MELEE_ATTACK_POWER_SHORT"},
 rangedAttack={"ITEM_MOD_RANGED_ATTACK_POWER_SHORT","ITEM_MOD_RANGED_ATTACK_POWER"},
 dps={"ITEM_MOD_DAMAGE_PER_SECOND_SHORT"},
 hit={"ITEM_MOD_HIT_RATING_SHORT","ITEM_MOD_HIT_RATING"},crit={"ITEM_MOD_CRIT_RATING_SHORT","ITEM_MOD_CRIT_RATING"},
 haste={"ITEM_MOD_HASTE_RATING_SHORT","ITEM_MOD_HASTE_RATING"},
 expertise={"ITEM_MOD_EXPERTISE_RATING_SHORT","ITEM_MOD_EXPERTISE_RATING"},
 defense={"ITEM_MOD_DEFENSE_SKILL_RATING_SHORT","ITEM_MOD_DEFENSE_SKILL_RATING"},
 block={"ITEM_MOD_BLOCK_RATING_SHORT","ITEM_MOD_BLOCK_RATING","ITEM_MOD_BLOCK_VALUE_SHORT","ITEM_MOD_BLOCK_VALUE"},
 dodge={"ITEM_MOD_DODGE_RATING_SHORT","ITEM_MOD_DODGE_RATING"},parry={"ITEM_MOD_PARRY_RATING_SHORT","ITEM_MOD_PARRY_RATING"},
}
local schoolKeys={holy="HOLY",fire="FIRE",nature="NATURE",frost="FROST",shadow="SHADOW",arcane="ARCANE"}
local function maximum(raw, keys)
 local value=0
 for _,key in ipairs(keys) do
  local v=raw[key]
  if not NS.Public(v) then return nil end
  if public(v,"number") then
   if v~=v or v==math.huge or v==-math.huge then return nil end
   value=math.max(value,v)
  end
 end
 return value
end
function G.Normalize(raw)
 if not public(raw,"table") then return nil end
 local out={}
 for key,names in pairs(stats) do
  out[key]=maximum(raw,names); if out[key]==nil then return nil end
 end
 for key,token in pairs(schoolKeys) do
  out[key]=maximum(raw,{"ITEM_MOD_"..token.."_DAMAGE_SHORT","ITEM_MOD_"..token.."_DAMAGE"})
  if out[key]==nil then return nil end
 end
 -- Classic exposes separate spell/melee/ranged rating tokens on some clients.
 for _,key in ipairs({"hit","crit","haste"}) do
  local upper=key:upper()
  for _,kind in ipairs({"SPELL","MELEE","RANGED"}) do
   local v=maximum(raw,{"ITEM_MOD_"..upper.."_"..kind.."_RATING_SHORT","ITEM_MOD_"..upper.."_"..kind.."_RATING"})
   if v==nil then return nil end
   out[key..kind]=v
  end
 end
 return out
end
-- "Equip:" effects written out on the tooltip, for clients whose item stats leave them out:
-- "Increases damage and healing done by magical spells and effects by up to 12." and its kin.
-- Each pattern gives the stat it adds to. English wording only; other languages keep whatever
-- the client's item stats report. Percentage lines count one point per percent, the same way
-- the client's own item stats report them. "Use:" and "Chance on hit:" effects, and any "Equip:"
-- line none of these patterns read, are recorded as effects Everfrost cannot score.
local equipEffects={
 {"damage and healing done by magical spells and effects by up to (%d+)","spell"},
 {"healing done by spells and effects by up to (%d+)","healing"},
 {"damage done by (%a+) spells and effects by up to (%d+)","school"},
 {"spell power by (%d+)","spell"},
 {"%+(%d+) ranged attack power","rangedAttack"},
 {"ranged attack power by (%d+)","rangedAttack"},
 {"%+(%d+) attack power","attack"},
 {"attack power by (%d+)","attack"},
 {"restores (%d+) mana per 5 sec","mp5"},
 {"chance to hit with spells by (%d+)%%","hitSPELL"},
 {"critical strike with spells by (%d+)%%","critSPELL"},
 {"chance to hit by (%d+)%%","hit"},
 {"critical strike by (%d+)%%","crit"},
 {"chance to dodge an attack by (%d+)%%","dodge"},
 {"chance to parry an attack by (%d+)%%","parry"},
 {"chance to block attacks with a shield by (%d+)%%","block"},
 {"block value of your shield by (%d+)","block"},
 {"increased defense %+(%d+)","defense"},
 {"defense rating by (%d+)","defense"},
 {"defense by (%d+)","defense"},
}
-- Returns the stats read from "Equip:" lines, and the kinds of effect that cannot be scored
-- ({use=true, proc=true, equip=true}); either is nil when there is nothing to report.
function G.EquipEffects(link)
 local data=first(C_TooltipInfo and C_TooltipInfo.GetHyperlink,link)
 if not public(data,"table") or not public(data.lines,"table") then return nil end
 local found,unscored={},{}
 for _,line in ipairs(data.lines) do
  local text=public(line,"table") and line.leftText
  if public(text,"string") then
   text=text:lower()
   if text:find("^use:") then unscored.use=true
   elseif text:find("^chance on hit:") then unscored.proc=true
   elseif text:find("^equip:") then
    local matched=false
    for _,effect in ipairs(equipEffects) do
     local a,b=text:match(effect[1])
     if a then
      local key,amount=effect[2],tonumber(b or a)
      if key=="school" then key=schoolKeys[a] and a or nil end
      if key and amount then found[key]=(found[key] or 0)+amount; matched=true end
      break
     end
    end
    if not matched then unscored.equip=true end
   end
  end
 end
 return next(found) and found or nil,next(unscored) and unscored or nil
end
function G.ReadItem(link)
 if not public(link,"string") then return nil end
 if G.items[link] then return G.items[link] end
 if InCombatLockdown() then return nil end
 local info=NS.Call(itemAPI("GetItemInfo"),link)
 if not info or not public(info[1],"string") then
  local id=tonumber(link:match("item:(%d+)"))
  if id then NS.Call(C_Item and C_Item.RequestLoadItemDataByID,id) end
  return nil
 end
 for _,i in ipairs({5,9,12,13}) do
  if not NS.Public(info[i]) then return nil end
 end
 if not public(info[9],"string") or not public(info[5],"number") then return nil end
 local item={link=link,id=tonumber(link:match("item:(%d+)")),name=info[1],level=info[5],loc=info[9],classID=info[12],subclassID=info[13]}
 item.sellPrice=public(info[11],"number") and info[11] or 0
 -- Cosmetic rarity metadata is cached outside combat, independently of scoring.
 item.color={1,1,1}
 local quality=info[3]
 if public(quality,"number") and quality>=0 and quality<=8 and quality==math.floor(quality) then
  item.quality=quality
  local color=NS.Call(itemAPI("GetItemQualityColor"),quality)
  local valid=color~=nil
  if color then
   for i=1,3 do
    if not public(color[i],"number") or not (color[i]>=0 and color[i]<=1) then valid=false; break end
   end
  end
  if valid then item.color={color[1],color[2],color[3]} end
 end
 if not slots[item.loc] then item.unsupported=true; G.items[link]=item; return item end
 if not public(item.classID,"number") or not public(item.subclassID,"number") then return nil end
 local raw=first(itemAPI("GetItemStats"),link)
 item.stats=G.Normalize(raw)
 if not item.stats then return nil end
 -- The larger of the two readings, so an effect the client already reports is never counted twice.
 local effects,unscored=G.EquipEffects(link)
 item.unscored=unscored
 if effects then
  for key,amount in pairs(effects) do
   if amount>(item.stats[key] or 0) then item.stats[key]=amount; item.fromTooltip=true end
  end
 end
 -- IsUsableItem checks an item's use action, not whether it is equipment.
 -- Native Forever bags expose separate Use and Equip actions. Class/level
 -- restrictions are checked below; do not reject passive gear with no use action.
 local usable=NS.Call(itemAPI("IsEquippableItem"),link)
 if usable and not NS.Public(usable[1]) then return nil end
 if usable and public(usable[1],"boolean") then item.usable=usable[1] end
 local unique=NS.Call(itemAPI("GetItemUniqueness"),link)
 if unique then
  if not NS.Public(unique[1]) or not NS.Public(unique[2]) then return nil end
  if public(unique[1],"number") and public(unique[2],"number") then
   item.unique,item.limit=unique[1],unique[2]
   -- Plain Unique-Equipped items report category -1: they only limit copies of themselves.
   if item.unique==-1 and item.id then item.unique=-item.id; item.limit=math.max(item.limit,1) end
  end
 end
 G.items[link]=item; return item
end
-- Every result has a kind ("need" = an upgrade worth a Need roll, "greed" = anything else that
-- was judged, "unknown" = not judged) and a verdict tier:
--   clear      upgrade of at least NS.gearTiers.clear (or fills an empty slot)
--   minor      upgrade of at least NS.gearTiers.minor
--   sidegrade  within NS.gearTiers.minor either way
--   spec       not an upgrade for you, but one for another focus or talent tree of your class
--   unusable   your class, level or setup cannot use it
--   downgrade  worse, or nothing your spec uses
--   unknown    not scored (no tree, missing data, or an effect that cannot be scored)
-- The percentage is the score difference over the replaced item's score (at least 1 point).
NS.gearTiers={clear=0.10,minor=0.03}
local function unknown(reason) return {kind="unknown",verdict="unknown",reason=reason} end
-- Only these results can change when item data finishes loading.
local function waiting(reason) return {kind="unknown",verdict="unknown",reason=reason,waiting=true} end
local function greed(reason,verdict) return {kind="greed",verdict=verdict or "downgrade",reason=reason} end
-- specLimited: only this spec's setup rules it out, so another spec or focus may still want it.
local function unusable(reason,specLimited) local r=greed(reason,"unusable"); r.specLimited=specLimited or nil; return r end
function G.Eligible(item, context)
 if item.unsupported then return false,"Not equipment for this guide" end
 if item.level>context.level then return false,"Requires a higher level" end
 if item.usable==false then return false,"Item requirements are not met" end
 if item.classID==4 then
  local sub=item.subclassID
  if sub>=1 and sub<=4 and sub>heaviestArmor(context.class,context.level) then return false,"Armour type unavailable to your class at this level" end
  if sub==6 and context.class~="WARRIOR" and context.class~="PALADIN" and context.class~="SHAMAN" then return false,"Your class cannot use shields" end
  if sub>=7 and sub<=11 then
   local owner=({[7]="PALADIN",[8]="DRUID",[9]="SHAMAN"})[sub]
   if owner~=context.class then return false,"Class-specific equipment" end
  end
 elseif item.classID==2 then
  if not (weaponTypes[context.class] and weaponTypes[context.class][item.subclassID]) then return false,"Your class cannot use this weapon type" end
 end
 -- Two-handers stay eligible for shield specs: Compare weighs them against the weapon and
 -- shield they would displace, then refuses to call them an upgrade (see shieldBlocked).
 if context.daggers and item.classID==2 and (item.loc=="INVTYPE_WEAPON" or item.loc=="INVTYPE_WEAPONMAINHAND" or item.loc=="INVTYPE_WEAPONOFFHAND") and item.subclassID~=15 then return false,"Mutilate requires daggers",true end
 return true
end
-- The amounts a profile actually credits, including its school and rating aliases.
local function effective(item, p)
 local s=item.stats
 local caster=p.kind=="caster" or p.kind=="healer"
 local ratingKind=caster and "SPELL" or p.kind=="ranged" and "RANGED" or "MELEE"
 local values={}
 for key,value in pairs(s) do values[key]=value end
 values.spell=s.spell+(p.school and s[p.school] or 0)
 if p.schools then for school,share in pairs(p.schools) do values.spell=values.spell+(s[school] or 0)*share end end
 -- General spell power also heals; never count aliases or damage+healing twice.
 values.healing=math.max(s.healing,s.spell)
 for _,key in ipairs({"hit","crit","haste"}) do values[key]=math.max(s[key],s[key..ratingKind] or 0) end
 local ranged=item.loc=="INVTYPE_RANGED" or item.loc=="INVTYPE_RANGEDRIGHT" or item.loc=="INVTYPE_THROWN"
 local weapon=item.classID==2
 local damageWeapon=weapon and ((p.kind=="ranged" and ranged) or (not caster and p.kind~="ranged" and not ranged))
 values.dps=damageWeapon and s.dps or 0
 -- Stat sticks do not get melee/ranged DPS credit for the wrong role.
 -- A wand is a caster's Shoot damage. No guide ranks it, so DPS earns a small fixed credit.
 values.wand=caster and item.classID==2 and item.subclassID==19 and s.dps or 0
 return values,damageWeapon
end
-- Armour counts for every spec. A profile that ranks Armour scores it as one of its stats, at
-- this rate times its weight. For the rest it is extra credit at the plain rate, reported apart
-- from the stats so a result can say when armour, not a stat, decided it. Armour pieces and
-- shields only: a weapon's armour is never credited.
NS.gearArmorRate=0.1
local function armorCredit(item, w)
 if item.classID~=4 then return 0,0 end
 local amount=item.stats.armor*NS.gearArmorRate
 if w.armor then return amount*w.armor,0 end
 return 0,amount
end
function G.Score(item, context, p)
 if not item or not item.stats then return nil end
 local s=item.stats; local w=p.weights
 local caster=p.kind=="caster" or p.kind=="healer"
 local values,damageWeapon=effective(item,p)
 if damageWeapon and s.dps<=0 then return nil end
 local score=0
 for key,weight in pairs(w) do
  if key~="armor" then score=score+(values[key] or 0)*weight*(key=="dps" and 12 or 1) end
 end
 local ranked,extra=armorCredit(item,w)
 score=score+ranked+extra
 score=score+values.wand
 -- AP equivalents follow the relevant primary stat rather than being omitted.
 -- A profile that ranks Attack Power itself already scored it in the loop above.
 if not caster and not w.attack then
  local ap=math.max(s.attack,p.kind=="ranged" and s.rangedAttack or 0)
  local primary=math.max(w.strength or 0,w.agility or 0)
  score=score+ap*(primary>0 and primary or 1)/2
 end
 local relevant
 if caster then relevant=values.spell+(p.kind=="healer" and values.healing or 0)+s.intellect+s.spirit+s.mp5+values.hit+values.crit+values.haste+values.wand
 else relevant=s.strength+s.agility+s.attack+s.rangedAttack+values.dps+values.hit+values.crit+(s.expertise or 0)
  if p.kind=="tank" then relevant=relevant+s.stamina+s.armor+s.block+s.defense+s.dodge+s.parry end
  if context.class=="PALADIN" then relevant=relevant+values.spell end
  if context.class=="HUNTER" or context.class=="PALADIN" or context.class=="SHAMAN" then relevant=relevant+s.intellect+s.spirit end
 end
 return score,relevant>0,extra
end
local function fitsHand(item, hand, context, p)
 if not item or not G.Eligible(item,context,p) then return false end
 if hand==16 then return item.loc=="INVTYPE_WEAPON" or item.loc=="INVTYPE_WEAPONMAINHAND" end
 if p.shield then return item.loc=="INVTYPE_SHIELD" end
 return item.loc=="INVTYPE_SHIELD" or item.loc=="INVTYPE_HOLDABLE" or
  (context.dual and (item.loc=="INVTYPE_WEAPON" or item.loc=="INVTYPE_WEAPONOFFHAND"))
end
local function validPair(main, off, equipped)
 -- Test each exposed limit against the final loadout, including both new items.
 for _,item in ipairs({main,off}) do
  if item.unique and item.unique~=0 and item.limit and item.limit>0 then
   local count=0
   for _,other in ipairs({main,off}) do if other.unique==item.unique then count=count+1 end end
   for slot=1,19 do
    local worn=equipped[slot]
    if slot~=16 and slot~=17 and worn and worn.unique==item.unique then count=count+1 end
   end
   if count>item.limit then return false end
  end
 end
 return true
end
local function comparePair(item, equipped, context, p, carried, candidate)
 local previous=G.Score(equipped[16],context,p)
 if previous==nil or equipped[17]==nil then return waiting("Waiting for equipped weapon data") end
 if equipped[17] then
  local score=G.Score(equipped[17],context,p)
  if score==nil then return waiting("Waiting for equipped off-hand data") end
  previous=previous+score
 end
 local best,partnerPending
 for _,hand in ipairs({16,17}) do
  if fitsHand(item,hand,context,p) then
   local otherHand=hand==16 and 17 or 16
   for _,entry in ipairs(carried or {}) do
    -- Entries identify physical bag slots: one item cannot occupy both hands.
    -- A loot candidate is a separate copy and has no carried entry to exclude.
    if entry~=candidate then
     local partner=entry.item
     if not partner then partnerPending=true
     elseif fitsHand(partner,otherHand,context,p) then
      local main=hand==16 and item or partner
      local off=hand==17 and item or partner
      if validPair(main,off,equipped) then
       local score,relevant=G.Score(item,context,p)
       local partnerScore,partnerRelevant=G.Score(partner,context,p)
       if score==nil or partnerScore==nil then partnerPending=true
       elseif relevant or partnerRelevant then
        local delta=score+partnerScore-previous
        if not best or delta>best.delta then
         best={score=score+partnerScore,previous=previous,delta=delta,slot=hand,
          companion=partner.link,companionName=partner.name or partner.link,companionSlot=otherHand,
          combined=true,source=p.source}
        end
       end
      end
     end
    end
   end
  end
 end
 if best and best.delta>0.01 then
  best.kind="need"; best.reason="Estimated upgrade only when equipped together"; return best
 end
 if partnerPending then return waiting("Waiting for carried weapon/off-hand data") end
 if best then
  best.kind="greed"; best.reason="No estimated upgrade from the available weapon/off-hand pairs"; return best
 end
 return unknown("Carry a usable one-hand weapon and off-hand to compare with your two-hander")
end
-- Armor gained by wearing item instead of old; false means a confirmed empty slot.
local function armorGain(item, old)
 if item.classID~=4 or (old and old.classID~=4) then return 0 end
 return item.stats.armor-(old and old.stats.armor or 0)
end
-- Sorts a judged result into its verdict tier from the score difference.
local function settle(result)
 if result.kind=="unknown" or result.delta==nil then return result end
 local tiers=NS.gearTiers
 local pct=result.delta/math.max(result.previous or 0,1)
 result.pct=pct
 if result.kind=="need" then
  if result.empty or pct>=tiers.clear then result.verdict="clear"
  elseif pct>=tiers.minor then result.verdict="minor"
  else result.kind="greed"; result.verdict="sidegrade" end
 else
  result.verdict=pct>-tiers.minor and "sidegrade" or "downgrade"
 end
 return result
end
-- The most important stat that favours each item, in the words a new player would use.
local function explain(result, item, old, p)
 if result.armorOnly or result.combined then return nil end
 if old==false then return result.kind=="need" and "Better because that slot is empty." or nil end
 if not old or not old.stats then return nil end
 local mine,theirs=effective(item,p),effective(old,p)
 local gain,top,loss
 for rank,group in ipairs(p.order) do
  for key in group:gmatch("%S+") do
   if not gain and (mine[key] or 0)>(theirs[key] or 0)+0.001 then gain=key; top=rank==1 end
   if not loss and (theirs[key] or 0)>(mine[key] or 0)+0.001 then loss=key end
  end
 end
 local labels=NS.gearStatLabels
 if result.kind=="need" then
  if gain then return "Better because it has more "..labels[gain]..(top and ", your top priority." or ".") end
  if mine.wand>theirs.wand then return "Better because it has a stronger wand attack." end
 elseif result.verdict=="sidegrade" then
  if gain and loss then return "More "..labels[gain]..", but less "..labels[loss].."." end
  return "About the same as your current item."
 else
  if loss then return "Your current item has more "..labels[loss].."." end
  if theirs.wand>mine.wand then return "Your current wand attacks harder." end
 end
 return nil
end
local function compare(item, equipped, context, carried, candidate, profile)
 if not context or context.level<1 or context.level>NS.maxLevel then return unknown("Gear guide supports levels 1-"..NS.maxLevel) end
 local p=profile or NS.GearProfile(context.class,context.spec,context.role,context.level)
 if not p then return unknown("Select a talent tree to compare gear") end
 if not item then return waiting("Waiting for item data") end
 local eligible,reason,specLimited=G.Eligible(item,context,p)
 if not eligible then return unusable(reason,specLimited) end
 if p.shield and (item.loc=="INVTYPE_HOLDABLE" or item.loc=="INVTYPE_WEAPONOFFHAND") then
  return unusable((p.specName or "Your spec").." keeps a shield in the off-hand",true)
 end
 local score,relevant,armorExtra=G.Score(item,context,p)
 if not score then return unknown("Weapon or item stats are unavailable") end
 if (slots[item.loc][1]==16 or slots[item.loc][1]==17) and equipped[16]==nil then
  return waiting("Waiting for equipped main-hand data")
 end
 if equipped[16] and equipped[16].loc=="INVTYPE_2HWEAPON" and
  (fitsHand(item,16,context,p) or fitsHand(item,17,context,p)) then
  return comparePair(item,equipped,context,p,carried,candidate)
 end
 local noUsefulStats="No useful stats for your current specialisation"
 -- An item whose only worth is an effect Everfrost cannot read is left for you to judge.
 if not relevant and item.unscored then return unknown("Its special effect can't be scored; compare it yourself") end
 -- Armor pieces continue without useful stats: more armor can still decide a tie below.
 if not relevant and not (item.classID==4 and item.stats.armor>0) then return greed(noUsefulStats) end
 local choices=slots[item.loc]
 if item.loc=="INVTYPE_WEAPON" and context.dual then choices={16,17} end
 if item.loc=="INVTYPE_WEAPONOFFHAND" and not context.dual then return unusable("Dual wield is not learned") end
 local best
 for _,slot in ipairs(choices) do
  local old=equipped[slot]
  -- false denotes a confirmed empty slot; nil is missing metadata.
  if old==nil then return waiting("Waiting for equipped item data") end
  if (slot==16 or slot==17) and equipped[16] and equipped[16].loc=="INVTYPE_2HWEAPON" and item.loc~="INVTYPE_2HWEAPON" then
   return unknown("Compare a complete one-hand/off-hand setup before replacing a two-handed weapon")
  end
  local oldScore,oldRelevant,oldArmor=0,false,0
  if old then
   oldScore,oldRelevant,oldArmor=G.Score(old,context,p)
   if oldScore==nil then return unknown("Equipped weapon stats are unavailable") end
  end
  local allowed=true
  if item.loc=="INVTYPE_2HWEAPON" then
   local off=equipped[17]
   if off==nil then return waiting("Waiting for off-hand item data") end
   local extra,_,offArmor=0,nil,0
   if off then
    extra,_,offArmor=G.Score(off,context,p)
    if extra==nil then return unknown("Off-hand stats are unavailable") end
   end
   oldScore=oldScore+extra; oldArmor=oldArmor+(offArmor or 0)
  elseif slot==17 and p.shield and item.loc~="INVTYPE_SHIELD" then allowed=false end
  if item.unique and item.unique~=0 and item.limit and item.limit>0 then
   local count=0
   for other=1,19 do
    local worn=equipped[other]
    if other~=slot and worn and worn.unique==item.unique then count=count+1 end
   end
   if count>=item.limit then allowed=false end
  end
  if old and old.link==item.link then allowed=false end
  if allowed and (not best or score-oldScore>best.delta) then
   local displaces=item.loc=="INVTYPE_2HWEAPON" and equipped[17]
   best={kind="greed",score=score,previous=oldScore,delta=score-oldScore,slot=slot,source=p.source,
    oldRelevant=oldRelevant,armorGain=armorGain(item,old),old=old,
    -- The part of the difference that comes from armour credit rather than from stats.
    armorCredit=armorExtra-oldArmor,
    -- A two-hander also displaces the off-hand, so one stat cannot explain the result.
    plain=not displaces,displacesShield=displaces and displaces.loc=="INVTYPE_SHIELD" or nil,
    empty=old==false and not displaces or nil,
    -- Rings and trinkets: the best result replaces the weaker of the two worn.
    slotNote=(item.loc=="INVTYPE_FINGER" or item.loc=="INVTYPE_TRINKET") and equipped[choices[1]] and equipped[choices[2]]
     and (item.loc=="INVTYPE_FINGER" and "Compared with the weaker of your two rings." or "Compared with the weaker of your two trinkets.") or nil,
    oldUnscored=old and old.unscored or nil}
  end
 end
 if not best then return unusable("Not a valid replacement for your current equipment") end
 local statDelta=best.delta-best.armorCredit
 if relevant and best.delta>0.01 then
  best.kind="need"
  if statDelta>0.01 then
   best.reason="Estimated stat upgrade"; best.generic=true
  elseif statDelta>=-0.01 and best.armorGain>0 then
   best.armorOnly=true
   best.reason=string.format("More armour, no useful stats lost (+%.0f Armour)",best.armorGain)
  else
   best.reason=string.format("More armour (+%.0f) outweighs the stats it gives up",best.armorGain)
  end
 -- An item with no useful stats can only replace another one, and only when nothing is lost
 -- on stats: Stamina cannot stand in for lost Strength, however much armour comes with it.
 elseif best.armorGain>0 and statDelta>=-0.01 and (relevant or not best.oldRelevant) then
  best.kind="need"; best.armorOnly=true
  best.reason=string.format("More armour, no useful stats lost (+%.0f Armour)",best.armorGain)
 elseif not relevant then return greed(noUsefulStats)
 else
  best.reason="No estimated stat upgrade"; best.generic=true
 end
 settle(best)
 -- A shield spec never trades its shield for a two-hander, however the numbers fall.
 if p.shield and item.loc=="INVTYPE_2HWEAPON" and best.kind=="need" then
  best.kind="greed"; best.verdict="downgrade"; best.shieldBlocked=true; best.generic=nil; best.armorOnly=nil
  best.reason=(p.specName or "Your spec").." needs a shield, so a two-hander is never an upgrade"
 end
 if best.plain then best.why=explain(best,item,best.old,p)
 elseif best.displacesShield then best.why="Compared with your main hand and shield together, including the shield's armour and block."
 else best.why="Compared with your main hand and off-hand together." end
 return best
end
-- Other ways this class could use the item: the spec's other focuses, then its other talent
-- trees at their default focus. Cached until the context or focus changes.
function G.Alternatives(context)
 if not context then return {} end
 local cache=G.alternatives
 if cache and cache.context==context and cache.focus==G.focus then return cache.list end
 local list={}
 local current=NS.GearProfile(context.class,context.spec,context.role,context.level)
 if current and not current.starter then
  local seen={[current]=true}
  local focus=NS.gearFocus[context.class] and NS.gearFocus[context.class][context.spec]
  for _,choice in ipairs(focus and focus.list or {}) do
   if not seen[choice.profile] then
    seen[choice.profile]=true
    list[#list+1]={profile=choice.profile,label=choice.label,bestFor=choice.profile.bestFor,context=context,sameSpec=true}
   end
  end
  for spec=1,3 do
   local p=NS.gearProfiles[context.class] and NS.GearFocusProfile(context.class,spec,nil)
   if p and spec~=context.spec and not seen[p] then
    seen[p]=true
    local other={}
    for key,value in pairs(context) do other[key]=value end
    other.spec=spec; other.role=nil; other.daggers=false
    list[#list+1]={profile=p,label=p.specName,bestFor=p.bestFor,context=other}
   end
  end
 end
 G.alternatives={context=context,focus=G.focus,list=list}
 return list
end
-- The one evaluation engine: bags, tooltips, loot rolls, quest rewards and merchants all call
-- this. profile is optional and scores for that profile instead of the active one; without it,
-- a result that is no upgrade for you is checked against the class's other focuses and trees.
function G.Compare(item, equipped, context, carried, candidate, profile)
 local result=settle(compare(item,equipped,context,carried,candidate,profile))
 local v=result.verdict
 -- Procs and on-use effects are reported, never given an invented score.
 if item and item.unscored and result.kind~="unknown" then result.unscored=item.unscored end
 if profile==nil and not result.combined and (v=="sidegrade" or v=="downgrade" or (v=="unusable" and result.specLimited)) then
  -- Another focus of your own spec is named before another talent tree.
  local best
  for _,alt in ipairs(G.Alternatives(context)) do
   if best and best.alt.sameSpec and not alt.sameSpec then break end
   local r=settle(compare(item,equipped,alt.context,carried,candidate,alt.profile))
   if r.kind=="need" and (not best or (r.pct or 0)>(best.result.pct or 0)) then best={alt=alt,result=r} end
  end
  if best then
   result.verdict="spec"; result.altLabel=best.alt.label; result.altBestFor=best.alt.bestFor
  end
 end
 return result
end
-- Records the scoring focus (a key from NS.GearFocusChoices, or nil for the default) and rescans.
function G.SetFocus(key)
 if type(key)~="string" then key=nil end
 if G.focus==key then return end
 G.focus=key; G.alternatives=nil
 G.Rescan()
end
-- Recompute every comparison on the next frame (deferred until combat ends).
function G.Rescan()
 G.pending=true
 if G.Schedule then G.Schedule() end
end
function G.SetContext(class, spec, level, role, known)
 if InCombatLockdown() then G.pending=true; return end
 local dual=first(IsPlayerSpell or (C_SpellBook and C_SpellBook.IsSpellKnown),674)
 dual=public(dual,"boolean") and dual or false
 local daggers=class=="ROGUE" and spec==1 and known and known.Mutilate~=nil or false
 local old=G.context
 if not old or old.class~=class or old.spec~=spec or old.level~=level or old.role~=role or old.dual~=dual or old.daggers~=daggers then
  G.context={class=class,spec=spec,level=level,role=role,dual=dual,daggers=daggers}
  G.pending=true
  if G.Schedule then G.Schedule() end
 end
end
function G.Refresh()
 if InCombatLockdown() then G.pending=true; return false end
 G.enabled=not EverfrostDB or EverfrostDB.gear~=false
 -- G.items stays: an item link's stats never change, and rescans are frequent.
 G.bags={}; G.carried={}; G.equipment={}
 -- Turned off: skip every item read; painting with no results clears old glows.
 if not G.enabled then
  G.pending=false
  if G.Paint then G.Paint() end
  if G.OnRefreshed then G.OnRefreshed() end
  return true
 end
 for slot=1,19 do
  local result=NS.Call(GetInventoryItemLink,"player",slot)
  if result and NS.Public(result[1]) then
   if result[1]==nil then G.equipment[slot]=false else G.equipment[slot]=G.ReadItem(result[1]) end
  end
 end
 local container=C_Container or {}
 local size=container.GetContainerNumSlots or GetContainerNumSlots
 local getLink=container.GetContainerItemLink or GetContainerItemLink
 -- Carried bags only: never compare bank, reagent bank or other characters.
 for bag=0,4 do
  G.bags[bag]={}
  local n=first(size,bag)
  if public(n,"number") then
   for slot=1,n do
    local link=first(getLink,bag,slot)
    if public(link,"string") then
     local entry={link=link,item=G.ReadItem(link)}
     G.bags[bag][slot]=entry; G.carried[#G.carried+1]=entry
    end
   end
  end
 end
 -- Read every carried item before comparing, so partners in later slots/bags count.
 for _,entry in ipairs(G.carried) do entry.result=G.Compare(entry.item,G.equipment,G.context,G.carried,entry) end
 G.pending=false
 if G.Paint then G.Paint() end
 if G.OnRefreshed then G.OnRefreshed() end
 return true
end
local armorSlots={1,3,5,6,7,8,9,10,15}
-- Only a slot the game confirms empty counts, so unread equipment never raises a false alarm.
function G.EmptySlots()
 if not G.enabled or G.pending or not next(G.equipment) then return false,0 end
 local count=0
 for _,slot in ipairs(armorSlots) do if G.equipment[slot]==false then count=count+1 end end
 return G.equipment[16]==false,count
end
function G.Evaluate(link)
 if not G.enabled then return unknown("Gear highlights are disabled") end
 if G.pending then return waiting("Updates after combat or item data refresh") end
 return G.Compare(G.ReadItem(link),G.equipment,G.context,G.carried)
end
