#!/usr/bin/env python3
"""Writes addon/Everfrost/TalentData.lua from the Icy Veins WoW Forever talent calculator data.

The data below was read on 2026-11-11 from each levelling guide's embedded calculator
(https://www.icy-veins.com/wow-forever/<spec>-<class>-leveling): one character per talent
point in the order the guide takes them, level 10 to 60, and each class's talent list
(https://www.icy-veins.com/wow-forever/<class>-talent-calculator). Re-read both and rerun
this script when the guides change their builds.
"""
import pathlib, re, sys

BUILDS = """
paladin holy yyyyyBBBzzFF3333377222aaaaa699AAdPPbefffffg11111e44
paladin protection yyyyyBBBzzFFiiiiijjjppoothhqnnnlwuuuuuvvvlmlllDDDHh
paladin retribution xxxxxzzBBBFFEDDHIIIDJJJKCLLLLLNOOOOO77444AA4488ccCC
hunter beast-mastery 000002255144677a7779dd9999ceeefeiiiiilllllmmwwwwwjj
hunter marksmanship iiiiilllllmmjjjpqqqqrrqssuuuuuv0000022551446s77a777
hunter survival iiiiiwwwwwzzAAADDDCCGGGGGLJJKKMMMMMNIFFlllllojjjkqq
mage arcane 0022277666aCC2266eddd4fggggghhh4ikkkkkllllljjmmrumC
mage fire 0022277666aCC2266dddkkkkkllllljjmmrummmsxwwwsyyysvz
mage frost CCBBBEEEBBJDDDDMMMDLPPHHHICKKORGNNNQQQQQF0033344666
warrior arms 22211553344467789997cbbddeedddgiiiiijjjjjqqqqqQyyaa
warrior fury iiiiikkkkklllqqoooootQssqppvvvx2221133554446yyqq777
warrior protection zzzzzCCCDDFFDEHJIIIHNNNMHOOOOOP222iiiiikkkkkqqqqqQ1
rogue assassination 1122233322c8855a9999gRRRRfffR9dAAAAAhhhjjmmmkkk66nn
rogue combat iihhhmmlllom66nrvvwwtuuuusssssxuwSS1122233322c8855a
rogue subtlety AAAAAEEEBBKKKJLGByyyNiiMFFFPPPPPQhhh1122233322c8855
priest discipline 11BBBBBiii00000555aaa55999d7effffgfgg7hkkkkkmmmmm78
priest holy 11BBBBBiiijjj22255555aaammmmnpmkkssrrrvuuwwxxxwwyw8
priest shadow 11BBBBBDDCCCGHHCEJIIIIIMMLKOOOOOP22255555aaaiiiKKzz
warlock affliction 111122222366999bbaaadjjjjjllnnnqaa30fffffg0eee55577
warlock demonology kkkkkoonnnrrmmmuuutqwxxxlyyyyyz111122222066999aaaaa
warlock destruction CCCCCFFFFFHAAGGKIIIJNNNMJOOOOOPJ1111jjjjjllnnnq00GG
druid balance 00000AAAAADDD554427223381111c1CCCCCdddeeeeefaaaaa99
druid feral gggggjjjiionnpprttqsvwwssyyyyyzuBBBBBCCCCC111115544
druid restoration 00000AAAAADDD55442722118CCHCCCGKGGGGLMMMJJJOOOOOP11
shaman elemental 111114445565000a8899cddd9eeeeefzzzzzAAADDGhhhhh00ii
shaman enhancement hhhhhkkkiionnnisllrrvvuutzzzzzAAArrrwwwwwx111112225
shaman restoration zzzzzAAAyyGyyyFJHHHHLKKKHMMMMMNFFEEEhhhhhIIIIIiiiii
"""

MAPS = {
"paladin": """
holy=3:spiritual-focus:5,O:divine-strength:5,2:healing-light:3,7:reverence:2,4:improved-seals:5,8:purifying-power:2,b:divine-favor:1,a:illumination:5,A:holy-conduit:2,c:divine-precision:2,9:infusion-of-light:2,6:oath-of-light:1,e:consecrated-ground:2,d:holy-shock:1,P:boundless-light:2,f:holy-power:5,g:lights-vigil:1
protection=1:divine-intellect:5,i:redoubt:5,j:precision:3,k:guardians-favor:2,p:sacred-duty:2,t:templars-bulwark:1,s:improved-hammer-of-justice:3,o:shield-specialization:2,h:toughness:5,q:swift-judgement:1,n:improved-righteous-fury:3,l:anticipation:5,0:stoicism:2,w:holy-shield:1,u:reckoning:5,v:iron-creed:3,m:shieldsworn:1
retribution=x:deflection:5,y:benediction:5,z:improved-judgement:2,B:conviction:3,D:sanctified-judgement:3,C:vindication:3,5:unyielding-faith:2,E:seal-of-command:1,F:pursuit-of-justice:2,G:eye-for-an-eye:2,H:sacred-arbiter:1,I:two-handed-weapon-specialization:3,Q:turn-evil:2,K:repentance:1,J:vengeance:3,L:champion-of-the-light:5,N:unsealed-wrath:1
""",
"hunter": """
beast-mastery=0:deadly-aspects:5,1:endurance-training:5,2:focused-fire:2,3:improved-aspect-of-the-monkey:3,5:improved-revive-pet:2,4:pathfinding:2,6:bestial-swiftness:1,7:unleashed-fury:5,8:improved-mend-pet:2,9:ferocity:5,a:summon-hawk:1,b:spirit-bond:2,c:intimidation:1,d:bestial-discipline:2,e:frenzy:5,f:bestial-wrath:1
marksmanship=g:hawk-eye:3,h:improved-concussive-shot:5,i:lethal-attacks:5,j:improved-stings:3,k:efficiency:5,l:careful-aim:5,m:rapid-killing:2,n:improved-arcane-shot:5,o:lone-wolf:1,p:trueshot-aura:1,q:mortal-shots:5,r:rapid-recuperation:2,s:barrage:3,t:scatter-shot:1,u:ranged-weapon-specialization:5,v:sniper-shot:1
survival=w:improved-tracking:5,x:deflection:5,y:entrapment:5,z:savage-strikes:2,A:survivalist:5,B:improved-wing-clip:3,C:clever-traps:2,D:surefooted:3,E:deterrence:1,F:survival-tactics:2,G:predators-edge:5,H:counterattack:1,I:resourcefulness:2,J:expose-prey:2,K:survivalists-discipline:2,L:strider-kick:1,M:lightning-reflexes:5,N:lacerating-strikes:1
""",
"mage": """
arcane=0:wand-specialization:2,2:improved-channeling:5,3:arcane-resilience:3,4:arcane-subtlety:2,5:magic-absorption:2,6:arcane-concentration:5,7:missile-barrage:2,8:arcane-geometry:2,9:arcane-impact:3,a:arcane-blast:1,b:arcane-shielding:2,c:improved-counterspell:2,d:arcane-meditation:3,e:arcane-wrath:1,f:presence-of-mind:1,g:arcane-mind:5,h:arcane-instability:3,i:arcane-power:1
fire=k:incineration:5,l:accelerant:5,m:ignite:5,n:flame-throwing:2,o:impact:3,p:burning-soul:3,q:improved-flamestrike:3,r:pyroblast:1,j:improved-fire-blast:2,s:improved-scorch:3,t:improved-fire-ward:2,u:heating-up:1,v:master-of-elements:3,w:critical-mass:3,x:blast-wave:1,y:fire-power:3,z:combustion:1
frost=A:frost-warding:2,B:improved-frostbolt:5,C:precision:3,D:ice-shards:5,E:frostbite:3,F:improved-frost-nova:2,G:permafrost:3,H:frost-channeling:3,I:improved-blizzard:3,J:ice-lance:1,K:arctic-reach:2,L:ice-block:1,M:shatter:3,N:improved-cone-of-cold:3,O:cold-snap:1,P:fingers-of-frost:2,Q:winters-chill:5,R:ice-barrier:1
""",
"warrior": """
arms=0:improved-heroic-strike:3,1:deflection:5,2:improved-rend:3,3:improved-charge:2,4:improved-tactical-mastery:3,5:improved-overpower:2,6:anger-management:1,7:deep-wounds:3,8:spearing-strike:1,9:two-handed-weapon-specialization:3,a:impale:2,b:bloodthrill:2,c:sweeping-strikes:1,d:weaponmaster:5,e:improved-slam:2,f:improved-hamstring:3,g:mortal-strike:1
fury=h:booming-voice:5,i:cruelty:5,j:lingering-rage:5,k:unbridled-wrath:5,l:furious-precision:3,m:piercing-howl:1,n:blood-craze:3,q:enrage:5,o:dual-wield-specialization:5,Q:reckless-swings:1,r:improved-execute:2,s:improved-berserker-rage:2,t:death-wish:1,w:gore-drinker:2,u:improved-intercept:2,p:improved-whirlwind:2,v:flurry:3,x:bloodthirst:1
protection=y:improved-bloodrage:2,z:shield-specialization:5,A:iron-will:5,B:anticipation:5,C:improved-revenge:3,D:improved-thunder-clap:3,E:last-stand:1,F:master-of-defense:2,G:improved-disarm:3,H:defiance:3,I:improved-sunder-armor:3,J:vanguard:1,K:improved-shield-bash:2,L:improved-shield-wall:2,M:concussion-blow:1,N:focused-rage:3,O:bastion:5,P:shield-slam:1
""",
"rogue": """
assassination=0:improved-gouge:3,1:remorseless-attacks:2,2:malice:5,3:ruthlessness:3,7:improved-expose-armor:2,5:improved-slice-and-dice:3,4:vigor:2,c:blood-splatter:1,8:lethality:2,9:vile-poisons:5,a:cold-blood:1,b:improved-poisons:5,R:relentless-strikes:5,g:venom:1,e:improved-kidney-shot:2,f:seal-fate:3,d:mutilate:1
combat=h:coup-de-grace:3,i:efficient-strikes:2,j:lightning-reflexes:5,k:puncturing-wounds:3,l:deflection:3,m:precision:3,p:improved-sprint:2,n:endurance:2,o:riposte:1,6:composure:2,q:improved-kick:2,r:flawless-execution:1,v:weapon-expertise:2,w:aggression:3,S:dual-wield-specialization:2,t:blade-flurry:1,u:hack-and-slash:5,s:flash-of-steel:5,x:adrenaline-rush:1
subtlety=B:setup:3,z:master-of-deception:3,A:opportunity:5,L:dirty-deeds:2,y:camouflage:3,E:improved-ambush:3,D:dirty-tricks:2,F:initiative:3,J:premeditation:1,K:serrated-blades:3,C:elusiveness:2,G:ghostly-strike:1,O:quick-getaway:2,I:heightened-senses:2,M:preparation:1,N:hemorrhage:1,P:boot-knife:5,Q:death-mark:1
""",
"priest": """
discipline=0:power-in-light:5,1:wand-specialization:2,2:twin-disciplines:5,3:silent-resolve:3,4:holy-precision:3,5:mental-strength:5,6:martyrdom:2,7:mental-agility:3,8:inner-focus:1,9:improved-power-word-shield:3,a:meditation:3,b:improved-inner-fire:3,c:improved-mana-burn:2,d:soul-warding:1,e:penance:1,f:renewed-hope:5,g:divine-aegis:3,h:power-infusion:1
holy=i:twilight-focus:3,j:improved-renew:3,k:holy-specialization:5,l:spell-warding:5,m:divine-fury:5,n:holy-nova:1,o:blessed-recovery:3,p:inspiration:3,q:holy-reach:2,r:improved-healing:3,s:searing-light:2,t:holy-binding:1,u:litany-of-light:2,v:spirit-of-redemption:1,w:spiritual-guidance:5,x:spiritual-healing:3,y:prayer-of-mending:1
shadow=z:shadow-focus:5,A:blackout:5,B:spirit-tap:5,C:improved-mind-blast:5,D:improved-shadow-word-pain:2,E:shadow-reach:2,F:improved-psychic-scream:2,G:mind-flay:1,H:improved-mind-flay:2,I:dark-inspiration:5,J:vampiric-embrace:1,K:shadow-weaving:3,L:silence:1,M:devouring-contagion:2,N:early-demise:2,O:darkness:5,P:shadowform:1
""",
"warlock": """
affliction=0:improved-life-tap:2,1:suppression:5,2:improved-corruption:5,3:grim-reach:2,4:soul-harvest:2,5:improved-drains:3,6:improved-bane-of-agony:2,7:fel-concentration:3,8:amplify-curse:1,9:pandemic:3,a:malevolence:5,b:nightfall:2,c:curse-of-exhaustion:1,d:siphon-life:1,e:soul-siphon:3,f:shadow-mastery:5,g:wrack:1
demonology=h:improved-health-funnel:2,i:improved-imp:3,j:demonic-embrace:5,k:unholy-power:5,l:demonic-aegis:2,m:improved-voidwalker:3,n:fel-vitality:3,o:demonic-energies:2,p:improved-sayaad:3,q:demonic-sacrifice:1,r:master-summoner:2,s:decimation:2,t:fel-domination:1,u:demonic-brand:3,v:improved-felhunter:3,w:soul-link:1,x:demonic-knowledge:3,y:master-demonologist:5,z:demonic-pact:1
destruction=A:destructive-reach:2,B:improved-shadow-bolt:5,C:bane:5,D:molten-skin:5,E:cataclysm:3,F:aftermath:5,G:ruin:5,H:shadowburn:1,I:intensity:3,J:agonizing-flames:3,K:conflagrate:1,L:pyroclasm:2,M:bane-of-havoc:1,N:fire-and-brimstone:3,O:shadow-and-flame:5,P:incinerate:1
""",
"druid": """
balance=0:improved-wrath:5,1:genesis:5,2:moonglow:3,3:improved-moonfire:2,4:natures-majesty:2,5:natures-reach:2,6:improved-entangling-roots:3,7:natures-splendor:1,8:insect-swarm:1,9:vengeance:5,a:improved-starfire:5,b:overgrowth:2,c:natures-grace:1,d:eclipse:3,e:moonfury:5,f:moonkin-form:1
feral=g:ferocity:5,h:furor:5,i:feral-swiftness:2,j:feral-instinct:3,k:brutal-impact:2,l:thick-hide:3,m:shredding-attacks:3,n:savage-fury:2,o:feral-charge:1,p:sharpened-claws:2,s:predatory-strikes:3,r:lacerate:1,q:predatory-discipline:1,t:blood-frenzy:2,v:leader-of-the-pack:1,w:natural-instinct:2,y:rend-and-tear:5,x:natural-reaction:5,z:primal-bite:1,u:shifting-power:1
restoration=A:natures-focus:5,B:heart-of-the-wild:5,C:naturalist:5,D:reflection:3,E:natural-shapeshifter:3,F:subtlety:3,G:gift-of-nature:5,H:bloom:1,I:tranquil-spirit:5,J:improved-rejuvenation:3,K:swiftmend:1,L:natures-swiftness:1,M:living-spirit:3,N:improved-tranquility:2,O:improved-regrowth:5,P:wild-growth:1
""",
"shaman": """
elemental=0:convection:5,1:concussion:5,2:elemental-devastation:3,3:reverberation:5,4:elemental-alacrity:3,5:call-of-flame:3,6:elemental-focus:1,7:elemental-warding:3,8:trial-by-fire:2,9:eye-of-the-storm:3,a:earthbound:1,b:elemental-reach:2,c:call-of-thunder:1,d:lightning-overload:3,e:elemental-fury:5,f:lightning-mastery:1
enhancement=g:earths-grasp:2,h:thundering-strikes:5,i:ancestral-knowledge:5,j:guardian-totems:2,k:mental-dexterity:3,m:improved-lightning-shield:3,n:elemental-weapons:3,o:shamanistic-focus:1,p:anticipation:3,q:toughness:5,r:flurry:5,s:stormstrike:1,l:improved-ghost-wolf:2,t:spirit-weapons:1,u:mental-quickness:2,v:improved-stormstrike:2,w:maelstrom-weapon:5,x:rage-of-the-farseer:1
restoration=y:improved-healing-wave:5,z:tidal-focus:5,A:mindfulness:3,B:natural-grace:3,C:totemic-focus:5,D:improved-reincarnation:2,E:ancestral-healing:3,F:healing-focus:3,G:water-shield:1,H:tidal-mastery:5,I:restorative-totems:5,J:mana-tide-totem:1,K:healing-way:3,L:natures-swiftness:1,M:purification:5,N:riptide:1
""",
}
ORDER = ["paladin","hunter","mage","warrior","rogue","priest","warlock","druid","shaman"]
SMALL = {"of","the","and","for","de","in"}
POSSESSIVE = {"lights":"Light's","guardians":"Guardian's","templars":"Templar's","predators":"Predator's",
              "survivalists":"Survivalist's","winters":"Winter's","natures":"Nature's","earths":"Earth's"}
FIX = {"improved-sayaad":"Improved Sayaad","eye-for-an-eye":"Eye for an Eye","two-handed-weapon-specialization":"Two-Handed Weapon Specialization"}

def title(slug):
    if slug in FIX: return FIX[slug]
    words = slug.split("-")
    out = []
    for i, w in enumerate(words):
        if w in POSSESSIVE: out.append(POSSESSIVE[w])
        elif i and w in SMALL: out.append(w)
        else: out.append(w.capitalize())
    return " ".join(out)

def main():
    builds = {}
    for line in BUILDS.strip().splitlines():
        cls, spec, picks = line.split()
        builds.setdefault(cls, []).append((spec, picks))
    lines = ["local _, NS = ...",
             "-- Generated by scripts/talent-data.py from the Icy Veins WoW Forever levelling guides",
             "-- (talent calculators read 2026-11-11). Do not edit by hand: change the script and rerun it.",
             "-- names: one letter per talent, as the calculator numbers them. builds: one letter per talent",
             "-- point, in the order the guide spends them from level 10 to level 60.",
             "NS.talentData = {"]
    for cls in ORDER:
        names, limit = {}, {}
        for row in MAPS[cls].strip().splitlines():
            tree, items = row.split("=")
            for item in items.split(","):
                key, slug, most = item.split(":")
                assert key not in names, (cls, key)
                names[key] = title(slug); limit[key] = int(most)
        specs = builds[cls]
        assert len(specs) == 3, cls
        lines.append(f" {cls.upper()} = {{")
        lines.append("  names = {" + ", ".join(f'["{k}"]="{names[k]}"' for k in sorted(names)) + "},")
        lines.append("  ranks = {" + ", ".join(f'["{k}"]={limit[k]}' for k in sorted(limit)) + "},")
        lines.append("  builds = {")
        for spec, picks in specs:
            assert len(picks) == 51, (cls, spec, len(picks))
            for key in set(picks):
                assert key in names, (cls, spec, key)
                assert picks.count(key) <= limit[key], (cls, spec, key, picks.count(key), limit[key])
            lines.append(f'   "{picks}", -- {spec}')
        lines.append("  },")
        lines.append(" },")
    lines.append("}")
    target = pathlib.Path(__file__).resolve().parent.parent / "addon" / "Everfrost" / "TalentData.lua"
    target.write_text("\n".join(lines) + "\n")
    print("wrote", target, sum(len(b) for b in builds.values()), "builds")

if __name__ == "__main__":
    sys.exit(main())
