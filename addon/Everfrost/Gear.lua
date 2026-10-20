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
 if not slots[item.loc] then item.unsupported=true; G.items[link]=item; return item end
 if not public(item.classID,"number") or not public(item.subclassID,"number") then return nil end
 local raw=first(itemAPI("GetItemStats"),link)
 item.stats=G.Normalize(raw)
 if not item.stats then return nil end
 -- Item eligibility is read only outside combat and cached with the item.
 local usable=NS.Call(itemAPI("IsUsableItem"),link)
 if usable and not NS.Public(usable[1]) then return nil end
 if usable and public(usable[1],"boolean") then item.usable=usable[1] end
 local unique=NS.Call(itemAPI("GetItemUniqueness"),link)
 if unique then
  if not NS.Public(unique[1]) or not NS.Public(unique[2]) then return nil end
  if public(unique[1],"number") and public(unique[2],"number") then item.unique,item.limit=unique[1],unique[2] end
 end
 G.items[link]=item; return item
end
local function unknown(reason) return {kind="unknown",reason=reason} end
local function greed(reason) return {kind="greed",reason=reason} end
function G.Eligible(item, context, p)
 if item.unsupported then return false,"Not equipment for this guide" end
 if item.level>context.level then return false,"Requires a higher level" end
 if item.usable==false then return false,"Item requirements are not met" end
 if item.classID==4 then
  local sub=item.subclassID
  if sub>=1 and sub<=4 and sub>(armorMax[context.class] or 0) then return false,"Armor type unavailable to your class at this level" end
  if sub==6 and context.class~="WARRIOR" and context.class~="PALADIN" and context.class~="SHAMAN" then return false,"Your class cannot use shields" end
  if sub>=7 and sub<=11 then
   local owner=({[7]="PALADIN",[8]="DRUID",[9]="SHAMAN"})[sub]
   if owner~=context.class then return false,"Class-specific equipment" end
  end
 elseif item.classID==2 then
  if not (weaponTypes[context.class] and weaponTypes[context.class][item.subclassID]) then return false,"Your class cannot use this weapon type" end
 end
 if p.shield and item.loc=="INVTYPE_2HWEAPON" then return false,"The tank guide requires a shield" end
 if context.daggers and item.classID==2 and (item.loc=="INVTYPE_WEAPON" or item.loc=="INVTYPE_WEAPONMAINHAND" or item.loc=="INVTYPE_WEAPONOFFHAND") and item.subclassID~=15 then return false,"Mutilate requires daggers" end
 return true
end
function G.Score(item, context, p)
 if not item or not item.stats then return nil end
 local s=item.stats; local w=p.weights
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
 if damageWeapon and s.dps<=0 then return nil end
 values.dps=damageWeapon and s.dps or 0
 -- Stat sticks do not get melee/ranged DPS credit for the wrong role.
 local score=0
 for key,weight in pairs(w) do
  local scale=key=="armor" and 0.02 or key=="dps" and 12 or 1
  score=score+(values[key] or 0)*weight*scale
 end
 -- AP equivalents follow the relevant primary stat rather than being omitted.
 if not caster then
  local ap=math.max(s.attack,p.kind=="ranged" and s.rangedAttack or 0)
  score=score+ap*(w.attack or (p.kind=="ranged" and w.agility or w.strength or w.agility or 1)/2)
 end
 local relevant
 if caster then relevant=values.spell+(p.kind=="healer" and values.healing or 0)+s.intellect+s.spirit+s.mp5+values.hit+values.crit+values.haste
 else relevant=s.strength+s.agility+s.attack+s.rangedAttack+values.dps+values.hit+values.crit+(s.expertise or 0)
  if p.kind=="tank" then relevant=relevant+s.stamina+s.armor+s.block+s.defense end
  if context.class=="PALADIN" then relevant=relevant+values.spell end
  if context.class=="HUNTER" or context.class=="PALADIN" or context.class=="SHAMAN" then relevant=relevant+s.intellect+s.spirit end
 end
 return score,relevant>0
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
  if item.unique and item.unique>0 and item.limit and item.limit>0 then
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
 if previous==nil or equipped[17]==nil then return unknown("Waiting for equipped weapon data") end
 if equipped[17] then
  local score=G.Score(equipped[17],context,p)
  if score==nil then return unknown("Waiting for equipped off-hand data") end
  previous=previous+score
 end
 local best,waiting
 for _,hand in ipairs({16,17}) do
  if fitsHand(item,hand,context,p) then
   local otherHand=hand==16 and 17 or 16
   for _,entry in ipairs(carried or {}) do
    -- Entries identify physical bag slots: one item cannot occupy both hands.
    -- A loot candidate is a separate copy and has no carried entry to exclude.
    if entry~=candidate then
     local partner=entry.item
     if not partner then waiting=true
     elseif fitsHand(partner,otherHand,context,p) then
      local main=hand==16 and item or partner
      local off=hand==17 and item or partner
      if validPair(main,off,equipped) then
       local score,relevant=G.Score(item,context,p)
       local partnerScore,partnerRelevant=G.Score(partner,context,p)
       if score==nil or partnerScore==nil then waiting=true
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
 if waiting then return unknown("Waiting for carried weapon/off-hand data") end
 if best then
  best.kind="greed"; best.reason="No estimated upgrade from the available weapon/off-hand pairs"; return best
 end
 return unknown("Carry a usable one-hand weapon and off-hand to compare with your two-hander")
end
function G.Compare(item, equipped, context, carried, candidate)
 if not context or context.level<1 or context.level>NS.maxLevel then return unknown("Gear guide supports levels 1-30") end
 local p=NS.GearProfile(context.class,context.spec,context.role)
 if not p then return unknown("Select a talent tree to compare gear") end
 if not item then return unknown("Waiting for item data") end
 local eligible,reason=G.Eligible(item,context,p)
 if not eligible then return greed(reason) end
 local score,relevant=G.Score(item,context,p)
 if not score then return unknown("Weapon or item stats are unavailable") end
 if (slots[item.loc][1]==16 or slots[item.loc][1]==17) and equipped[16]==nil then
  return unknown("Waiting for equipped main-hand data")
 end
 if equipped[16] and equipped[16].loc=="INVTYPE_2HWEAPON" and
  (fitsHand(item,16,context,p) or fitsHand(item,17,context,p)) then
  return comparePair(item,equipped,context,p,carried,candidate)
 end
 if not relevant then return greed("No useful stats for your current specialization") end
 local choices=slots[item.loc]
 if item.loc=="INVTYPE_WEAPON" and context.dual then choices={16,17} end
 if item.loc=="INVTYPE_WEAPONOFFHAND" and not context.dual then return greed("Dual wield is not learned") end
 local best
 for _,slot in ipairs(choices) do
  local old=equipped[slot]
  -- false denotes a confirmed empty slot; nil is missing metadata.
  if old==nil then return unknown("Waiting for equipped item data") end
  if (slot==16 or slot==17) and equipped[16] and equipped[16].loc=="INVTYPE_2HWEAPON" and item.loc~="INVTYPE_2HWEAPON" then
   return unknown("Compare a complete one-hand/off-hand setup before replacing a two-handed weapon")
  end
  local oldScore=0
  if old then
   oldScore=G.Score(old,context,p)
   if oldScore==nil then return unknown("Equipped weapon stats are unavailable") end
  end
  local allowed=true
  if item.loc=="INVTYPE_2HWEAPON" then
   local off=equipped[17]
   if off==nil then return unknown("Waiting for off-hand item data") end
   local extra=0
   if off then
    extra=G.Score(off,context,p)
    if extra==nil then return unknown("Off-hand stats are unavailable") end
   end
   oldScore=oldScore+extra
  elseif slot==17 and p.shield and item.loc~="INVTYPE_SHIELD" then allowed=false end
  if item.unique and item.unique>0 and item.limit and item.limit>0 then
   local count=0
   for other=1,19 do
    local worn=equipped[other]
    if other~=slot and worn and worn.unique==item.unique then count=count+1 end
   end
   if count>=item.limit then allowed=false end
  end
  if old and old.link==item.link then allowed=false end
  if allowed and (not best or score-oldScore>best.delta) then best={kind="greed",score=score,previous=oldScore,delta=score-oldScore,slot=slot,source=p.source} end
 end
 if not best then return greed("Not a valid replacement for your current equipment") end
 best.kind=best.delta>0.01 and "need" or "greed"
 best.reason=best.kind=="need" and "Estimated stat upgrade" or "No estimated stat upgrade"
 return best
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
 G.items={}; G.bags={}; G.carried={}; G.equipment={}
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
 return true
end
function G.Evaluate(link)
 if G.pending or not G.enabled then return unknown(G.enabled and "Updates after combat or item data refresh" or "Gear highlights are disabled") end
 return G.Compare(G.ReadItem(link),G.equipment,G.context,G.carried)
end
