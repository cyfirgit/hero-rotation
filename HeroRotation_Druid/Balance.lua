--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroLib
local HL         = HeroLib
local Cache      = HeroCache
local Unit       = HL.Unit
local Player     = Unit.Player
local Target     = Unit.Target
local Pet        = Unit.Pet
local Spell      = HL.Spell
local MultiSpell = HL.MultiSpell
local Item       = HL.Item
-- HeroRotation
local HR         = HeroRotation

-- Azerite Essence Setup
local AE         = HL.Enum.AzeriteEssences
local AESpellIDs = HL.Enum.AzeriteEssenceSpellIDs

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Spells
if not Spell.Druid then Spell.Druid = {} end
Spell.Druid.Balance = {
  StreakingStars                        = Spell(272871),
  ArcanicPulsarBuff                     = Spell(287790),
  ArcanicPulsar                         = Spell(287773),
  StarlordBuff                          = Spell(279709),
  Starlord                              = Spell(202345),
  TwinMoons                             = Spell(279620),
  MoonkinForm                           = Spell(24858),
  SolarWrath                            = Spell(190984),
  BloodFury                             = Spell(20572),
  Berserking                            = Spell(26297),
  ArcaneTorrent                         = Spell(50613),
  LightsJudgment                        = Spell(255647),
  Fireblood                             = Spell(265221),
  AncestralCall                         = Spell(274738),
  WarriorofElune                        = Spell(202425),
  Innervate                             = Spell(29166),
  LivelySpirit                          = Spell(279642),
  Incarnation                           = Spell(102560),
  CelestialAlignment                    = Spell(194223),
  SunfireDebuff                         = Spell(164815),
  MoonfireDebuff                        = Spell(164812),
  StellarFlareDebuff                    = Spell(202347),
  StellarFlare                          = Spell(202347),
  LivelySpiritBuff                      = Spell(279646),
  FuryofElune                           = Spell(202770),
  ForceofNature                         = Spell(205636),
  Starfall                              = Spell(191034),
  Starsurge                             = Spell(78674),
  LunarEmpowermentBuff                  = Spell(164547),
  SolarEmpowermentBuff                  = Spell(164545),
  Sunfire                               = Spell(93402),
  Moonfire                              = Spell(8921),
  NewMoon                               = Spell(274281),
  HalfMoon                              = Spell(274282),
  FullMoon                              = Spell(274283),
  LunarStrike                           = Spell(194153),
  WarriorofEluneBuff                    = Spell(202425),
  ShootingStars                         = Spell(202342),
  NaturesBalance                        = Spell(202430),
  Barkskin                              = Spell(22812),
  Renewal                               = Spell(108238),
  SolarBeam                             = Spell(78675),
  ShiverVenomDebuff                     = Spell(301624),
  AzsharasFontofPowerBuff               = Spell(296962),
  BloodoftheEnemy                       = Spell(297108),
  MemoryofLucidDreams                   = Spell(298357),
  PurifyingBlast                        = Spell(295337),
  RippleInSpace                         = Spell(302731),
  ConcentratedFlame                     = Spell(295373),
  TheUnboundForce                       = Spell(298452),
  WorldveinResonance                    = Spell(295186),
  FocusedAzeriteBeam                    = Spell(295258),
  GuardianofAzeroth                     = Spell(295840),
  ReapingFlames                         = Spell(310690),
  RecklessForceBuff                     = Spell(302932),
  ConcentratedFlameBurn                 = Spell(295368),
  Thorns                                = Spell(236696)
};
local S = Spell.Druid.Balance;

-- Items
if not Item.Druid then Item.Druid = {} end
Item.Druid.Balance = {
  PotionofUnbridledFury            = Item(169299),
  PocketsizedComputationDevice     = Item(167555, {13, 14}),
  ShiverVenomRelic                 = Item(168905, {13, 14}),
  AzsharasFontofPower              = Item(169314, {13, 14}),
  ManifestoofMadness               = Item(174103, {13, 14})
};
local I = Item.Druid.Balance;

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
  I.PocketsizedComputationDevice:ID(),
  I.ShiverVenomRelic:ID(),
  I.AzsharasFontofPower:ID(),
  I.ManifestoofMadness:ID()
}

-- Rotation Var
local ShouldReturn; -- Used to get the return string
local EnemiesCount;

-- GUI Settings
local Everyone = HR.Commons.Everyone;
local Settings = {
  General = HR.GUISettings.General,
  Commons = HR.GUISettings.APL.Druid.Commons,
  Balance = HR.GUISettings.APL.Druid.Balance
};

-- Variables
local VarAzSs = 0;
local VarAzAp = 0;
local VarSfTargets = 0;

HL:RegisterForEvent(function()
  VarAzSs = S.StreakingStars:AzeriteRank()
  VarAzAp = S.ArcanicPulsar:AzeriteRank()
  VarSfTargets = 4
  if (S.ArcanicPulsar:AzeriteEnabled()) then
    VarSfTargets = VarSfTargets + 1
  end
  if (S.Starlord:IsAvailable()) then
    VarSfTargets = VarSfTargets + 1
  end
  if (S.StreakingStars:AzeriteRank() > 2 and S.ArcanicPulsar:AzeriteEnabled()) then
    VarSfTargets = VarSfTargets + 1
  end
  if (not S.TwinMoons:IsAvailable()) then
    VarSfTargets = VarSfTargets - 1
  end
end, "PLAYER_REGEN_ENABLED")

local EnemyRanges = {40, 15, 8}
local function UpdateRanges()
  for _, i in ipairs(EnemyRanges) do
    HL.GetEnemies(i);
  end
end

local function num(val)
  if val then return 1 else return 0 end
end

local function bool(val)
  return val ~= 0
end

HL:RegisterForEvent(function()
  S.ConcentratedFlame:RegisterInFlight();
end, "LEARNED_SPELL_IN_TAB")
S.ConcentratedFlame:RegisterInFlight()

local function FutureAstralPower()
  local AstralPower=Player:AstralPower()
  if not Player:IsCasting() then
    return AstralPower
  else
    if Player:IsCasting(S.NewMoon) then
      return AstralPower + 10
    elseif Player:IsCasting(S.HalfMoon) then
      return AstralPower + 20
    elseif Player:IsCasting(S.FullMoon) then
      return AstralPower + 40
    elseif Player:IsCasting(S.StellarFlare) then
      return AstralPower + 8
    elseif Player:IsCasting(S.SolarWrath) then
      return AstralPower + 8
    elseif Player:IsCasting(S.LunarStrike) then
      return AstralPower + 12
    else
      return AstralPower
    end
  end
end

local function CaInc()
  return S.Incarnation:IsAvailable() and S.Incarnation or S.CelestialAlignment
end

local function AP_Check(spell)
  local APGen = 0
  local CurAP = Player:AstralPower()
  if spell == S.Sunfire or spell == S.Moonfire then 
    APGen = 3
  elseif spell == S.StellarFlare or spell == S.SolarWrath then
    APGen = 8
  elseif spell == S.Incarnation or spell == S.CelestialAlignment then
    APGen = 40
  elseif spell == S.ForceofNature then
    APGen = 20
  elseif spell == S.LunarStrike then
    APGen = 12
  end
  
  if S.ShootingStars:IsAvailable() then 
    APGen = APGen + 4
  end
  if S.NaturesBalance:IsAvailable() then
    APGen = APGen + 2
  end
  
  if CurAP + APGen < Player:AstralPowerMax() then
    return true
  else
    return false
  end
end

local function GetEnemiesCount(range)
  -- Unit Update - Update differently depending on if splash data is being used
  if HR.AoEON() then
    if Settings.Balance.UseSplashData then
      HL.GetEnemies(range, nil, true, Target)
      return Cache.EnemiesCount[range]
    else
      UpdateRanges()
      Everyone.AoEToggleEnemiesUpdate()
      return Cache.EnemiesCount[40]
    end
  else
    return 1
  end
end

local function DoTsUp()
  return (Target:DebuffP(S.MoonfireDebuff) and Target:DebuffP(S.Sunfire) and (not S.StellarFlare:IsAvailable() or Target:DebuffP(S.StellarFlareDebuff)))
end

local function EvaluateCycleSunfire250(TargetUnit)
  return (TargetUnit:DebuffRefreshableCP(S.SunfireDebuff)) and (AP_Check(S.Sunfire) and math.floor (TargetUnit:TimeToDie() / (2 * Player:SpellHaste())) * EnemiesCount >= math.ceil (math.floor (2 / EnemiesCount) * 1.5) + 2 * EnemiesCount and (EnemiesCount > 1 + num(S.TwinMoons:IsAvailable()) or TargetUnit:DebuffP(S.MoonfireDebuff)) and (not bool(VarAzSs) or Player:BuffDownP(CaInc()) or not Player:PrevGCDP(1, S.Sunfire)) and (Player:BuffRemainsP(CaInc()) > TargetUnit:DebuffRemainsP(S.SunfireDebuff) or Player:BuffDownP(CaInc())))
end

local function EvaluateCycleMoonfire313(TargetUnit)
  return (TargetUnit:DebuffRefreshableCP(S.MoonfireDebuff)) and (AP_Check(S.Moonfire) and math.floor (TargetUnit:TimeToDie() / (2 * Player:SpellHaste())) * EnemiesCount >= 6 and (not bool(VarAzSs) or Player:BuffDownP(CaInc()) or not Player:PrevGCDP(1, S.Moonfire)) and (Player:BuffRemainsP(CaInc()) > TargetUnit:DebuffRemainsP(S.MoonfireDebuff) or Player:BuffDownP(CaInc())))
end

local function EvaluateCycleStellarFlare348(TargetUnit)
  return (TargetUnit:DebuffRefreshableCP(S.StellarFlareDebuff)) and (AP_Check(S.StellarFlare) and math.floor (TargetUnit:TimeToDie() / (2 * Player:SpellHaste())) >= 5 and (not bool(VarAzSs) or Player:BuffDownP(CaInc()) or not Player:PrevGCDP(1, S.StellarFlare)) and not Player:IsCasting(S.StellarFlare))
end

local function Precombat()
  -- flask
  -- food
  -- augmentation
  -- snapshot_stats
  -- variable,name=az_ss,value=azerite.streaking_stars.rank
  if (true) then
    VarAzSs = S.StreakingStars:AzeriteRank()
  end
  -- variable,name=az_ap,value=azerite.arcanic_pulsar.rank
  if (true) then
    VarAzAp = S.ArcanicPulsar:AzeriteRank()
  end
  -- variable,name=sf_targets,value=4
  if (true) then
    VarSfTargets = 4
  end
  -- variable,name=sf_targets,op=add,value=1,if=azerite.arcanic_pulsar.enabled
  if (S.ArcanicPulsar:AzeriteEnabled()) then
    VarSfTargets = VarSfTargets + 1
  end
  -- variable,name=sf_targets,op=add,value=1,if=talent.starlord.enabled
  if (S.Starlord:IsAvailable()) then
    VarSfTargets = VarSfTargets + 1
  end
  -- variable,name=sf_targets,op=add,value=1,if=azerite.streaking_stars.rank>2&azerite.arcanic_pulsar.enabled
  if (S.StreakingStars:AzeriteRank() > 2 and S.ArcanicPulsar:AzeriteEnabled()) then
    VarSfTargets = VarSfTargets + 1
  end
  -- variable,name=sf_targets,op=sub,value=1,if=!talent.twin_moons.enabled
  if (not S.TwinMoons:IsAvailable()) then
    VarSfTargets = VarSfTargets - 1
  end
  -- moonkin_form
  if S.MoonkinForm:IsCastableP() and Player:BuffDownP(S.MoonkinForm) then
    if HR.Cast(S.MoonkinForm, Settings.Balance.GCDasOffGCD.MoonkinForm) then return "moonkin_form 39"; end
  end
  -- use_item,name=azsharas_font_of_power
  if I.AzsharasFontofPower:IsEquipReady() and Settings.Commons.UseTrinkets then
    if HR.Cast(I.AzsharasFontofPower, nil, Settings.Commons.TrinketDisplayStyle) then return "azsharas_font_of_power precombat"; end
  end
  -- potion,dynamic_prepot=1
  if I.PotionofUnbridledFury:IsReady() and Settings.Commons.UsePotions then
    if HR.CastSuggested(I.PotionofUnbridledFury) then return "battle_potion_of_intellect 42"; end
  end
  -- solar_wrath
  if S.SolarWrath:IsCastableP() and (not Player:PrevGCDP(1, S.SolarWrath) and not Player:PrevGCDP(2, S.SolarWrath)) then
    if HR.Cast(S.SolarWrath, nil, nil, 40) then return "solar_wrath 43"; end
  end
  -- solar_wrath
  if S.SolarWrath:IsCastableP() and (Player:PrevGCDP(1, S.SolarWrath) and not Player:PrevGCDP(2, S.SolarWrath)) then
    if HR.Cast(S.SolarWrath, nil, nil, 40) then return "solar_wrath 44"; end
  end
  -- starsurge
  if S.Starsurge:IsReadyP() then
    if HR.Cast(S.Starsurge, nil, nil, 40) then return "starsurge 45"; end
  end
end

--- ======= ACTION LISTS =======
local function APL()
  EnemiesCount = GetEnemiesCount(15)
  HL.GetEnemies(40) -- To populate Cache.Enemies[40] for CastCycles

  -- Moonkin Form OOC, if setting is true
  if S.MoonkinForm:IsCastableP() and Player:BuffDownP(S.MoonkinForm) and Settings.Balance.ShowMoonkinFormOOC then
    if HR.Cast(S.MoonkinForm) then return "moonkin_form ooc"; end
  end
  
  -- call precombat
  if not Player:AffectingCombat() and Everyone.TargetIsValid() then
    local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
  end
  
  if Everyone.TargetIsValid() then
    -- Defensives
    if S.Renewal:IsCastableP() and Player:HealthPercentage() <= Settings.Balance.RenewalHP then
      if HR.Cast(S.Renewal, Settings.Balance.OffGCDasOffGCD.Renewal) then return "renewal defensive"; end
    end
    if S.Barkskin:IsCastableP() and Player:HealthPercentage() <= Settings.Balance.BarkskinHP then
      if HR.Cast(S.Barkskin, Settings.Balance.OffGCDasOffGCD.Barkskin) then return "barkskin defensive"; end
    end
    -- Interrupt
    local ShouldReturn = Everyone.Interrupt(40, S.SolarBeam, Settings.Balance.OffGCDasOffGCD.SolarBeam, false); if ShouldReturn then return ShouldReturn; end
    -- potion,if=buff.celestial_alignment.remains>13|buff.incarnation.remains>16.5
    if I.PotionofUnbridledFury:IsReady() and Settings.Commons.UsePotions and (Player:BuffRemainsP(S.CelestialAlignment) > 13 or Player:BuffRemainsP(S.Incarnation) > 16.5) then
      if HR.CastSuggested(I.PotionofUnbridledFury) then return "battle_potion_of_intellect 57"; end
    end
    -- berserking,if=buff.ca_inc.up
    if S.Berserking:IsCastableP() and HR.CDsON() and (Player:BuffP(CaInc())) then
      if HR.Cast(S.Berserking, Settings.Commons.OffGCDasOffGCD.Racials) then return "berserking 65"; end
    end
    -- use_item,name=azsharas_font_of_power,if=!buff.ca_inc.up,target_if=dot.moonfire.ticking&dot.sunfire.ticking&(!talent.stellar_flare.enabled|dot.stellar_flare.ticking)
    if I.AzsharasFontofPower:IsEquipReady() and Settings.Commons.UseTrinkets and (Player:BuffDownP(CaInc()) and DoTsUp())then
      if HR.Cast(I.AzsharasFontofPower, nil, Settings.Commons.TrinketDisplayStyle) then return "azsharas_font_of_power 73" end
    end
    -- guardian_of_azeroth,if=(!talent.starlord.enabled|buff.starlord.up)&!buff.ca_inc.up,target_if=dot.moonfire.ticking&dot.sunfire.ticking&(!talent.stellar_flare.enabled|dot.stellar_flare.ticking)
    if S.GuardianofAzeroth:IsCastableP() and ((not S.Starlord:IsAvailable() or Player:BuffP(S.StarlordBuff)) and Player:BuffDownP(CaInc()) and DoTsUp()) then
      if HR.Cast(S.GuardianofAzeroth, nil, Settings.Commons.EssenceDisplayStyle) then return "guardian_of_azeroth 94" end
    end
    -- use_item,effect_name=cyclotronic_blast,if=!buff.ca_inc.up,target_if=dot.moonfire.ticking&dot.sunfire.ticking&(!talent.stellar_flare.enabled|dot.stellar_flare.ticking)
    if Everyone.CyclotronicBlastReady() and Settings.Commons.UseTrinkets and DoTsUp() then
      if HR.Cast(I.PocketsizedComputationDevice, nil, Settings.Commons.TrinketDisplayStyle, 40) then return "cyclotronic_blast 117" end
    end
    -- use_item,name=shiver_venom_relic,if=!buff.ca_inc.up&!buff.bloodlust.up,target_if=dot.shiver_venom.stack>=5
    if I.ShiverVenomRelic:IsEquipReady() and Settings.Commons.UseTrinkets and (Player:BuffDownP(CaInc()) and not Player:HasHeroism() and Target:DebuffStackP(S.ShiverVenomDebuff) >= 5) then
      if HR.Cast(I.ShiverVenomRelic, nil, Settings.Commons.TrinketDisplayStyle, 50) then return "shiver_venom_relic 105"; end
    end
    -- use_item,name=manifesto_of_madness,if=buff.ca_inc.remains>10|buff.ca_inc.remains>4&buff.arcanic_pulsar.stack>6|fight_remains<21
    if I.ManifestoofMadness:IsEquipReady() and (Player:BuffRemainsP(CaInc()) > 10 or Player:BuffRemainsP(CaInc()) > 4 and Player:BuffStackP(S.ArcanicPulsarBuff) > 6 or HL.BossFilteredFightRemains("<", 21)) then
      if HR.Cast(I.ManifestoofMadness, nil, Settings.Commons.TrinketDisplayStyle) then return "manifesto_of_madness"; end
    end
    -- blood_of_the_enemy,if=cooldown.ca_inc.remains>30
    if S.BloodoftheEnemy:IsCastableP() and (CaInc():CooldownRemainsP() > 30) then
      if HR.Cast(S.BloodoftheEnemy, nil, Settings.Commons.EssenceDisplayStyle, 12) then return "blood_of_the_enemy"; end
    end
    -- memory_of_lucid_dreams,if=!buff.ca_inc.up&(astral_power<25|cooldown.ca_inc.remains>30),target_if=dot.sunfire.remains>10&dot.moonfire.remains>10&(!talent.stellar_flare.enabled|dot.stellar_flare.remains>10)
    if S.MemoryofLucidDreams:IsCastableP() and (Player:BuffDownP(CaInc()) and (Player:AstralPower() < 25 or CaInc():CooldownRemainsP() > 30) and DoTsUp()) then
      if HR.Cast(S.MemoryofLucidDreams, nil, Settings.Commons.EssenceDisplayStyle) then return "memory_of_lucid_dreams 149" end
    end
    -- purifying_blast
    if S.PurifyingBlast:IsCastableP() then
      if HR.Cast(S.PurifyingBlast, nil, Settings.Commons.EssenceDisplayStyle, 40) then return "purifying_blast"; end
    end
    -- ripple_in_space
    if S.RippleInSpace:IsCastableP() then
      if HR.Cast(S.RippleInSpace, nil, Settings.Commons.EssenceDisplayStyle) then return "ripple_in_space"; end
    end
    -- concentrated_flame,if=(!buff.ca_inc.up|stack=2)&!action.concentrated_flame_missile.in_flight,target_if=!dot.concentrated_flame_burn.ticking
    if S.ConcentratedFlame:IsCastableP() and ((Player:BuffDownP(CaInc()) or S.ConcentratedFlame:ChargesP() == 2) and not S.ConcentratedFlame:InFlight() and Target:DebuffDownP(S.ConcentratedFlameBurn)) then
      if HR.Cast(S.ConcentratedFlame, nil, Settings.Commons.EssenceDisplayStyle, 40) then return "concentrated_flame"; end
    end
    -- the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<5,target_if=dot.moonfire.ticking&dot.sunfire.ticking&(!talent.stellar_flare.enabled|dot.stellar_flare.ticking)
    if S.TheUnboundForce:IsCastableP() and ((Player:BuffP(S.RecklessForceBuff) or Player:BuffStackP(S.RecklessForceBuff) < 5)and DoTsUp()) then
      if HR.Cast(S.TheUnboundForce, nil, Settings.Commons.EssenceDisplayStyle, 40) then return "the_unbound_force 172" end
    end
    -- worldvein_resonance,if=!buff.ca_inc.up,target_if=dot.moonfire.ticking&dot.sunfire.ticking&(!talent.stellar_flare.enabled|dot.stellar_flare.ticking)
    if S.WorldveinResonance:IsCastableP() and (Player:BuffDownP(CaInc()) and DoTsUp()) then
      if HR.Cast(S.WorldveinResonance, nil, Settings.Commons.EssenceDisplayStyle) then return "worldvein_resonance"; end
    end
    -- reaping_flames,if=!buff.ca_inc.up
    if S.ReapingFlames:IsCastableP() and (Player:BuffDownP(CaInc())) then
      local ShouldReturn = Everyone.ReapingFlamesCast(Settings.Commons.EssenceDisplayStyle); if ShouldReturn then return ShouldReturn; end
    end
    -- focused_azerite_beam,if=(!variable.az_ss|!buff.ca_inc.up),target_if=dot.moonfire.ticking&dot.sunfire.ticking&(!talent.stellar_flare.enabled|dot.stellar_flare.ticking)
    if S.FocusedAzeriteBeam:IsCastableP() and ((not bool(VarAzSs) or Player:BuffDownP(CaInc())) and DoTsUp()) then
      if HR.Cast(S.FocusedAzeriteBeam, nil, Settings.Commons.EssenceDisplayStyle) then return "focused_azerite_beam 193" end
    end
    -- thorns
    if S.Thorns:IsCastableP() then
      if HR.Cast(S.Thorns, nil, Settings.Commons.EssenceDisplayStyle) then return "thorns"; end
    end
    -- use_items,slots=trinket1,if=!trinket.1.has_proc.any|buff.ca_inc.up|fight_remains<20
    -- use_items,slots=trinket2,if=!trinket.2.has_proc.any|buff.ca_inc.up|fight_remains<20
    -- use_items
    local TrinketToUse = HL.UseTrinkets(OnUseExcludes)
    if TrinketToUse then
      if HR.Cast(TrinketToUse, nil, Settings.Commons.TrinketDisplayStyle) then return "Generic use_items for " .. TrinketToUse:Name(); end
    end
    -- warrior_of_elune
    if S.WarriorofElune:IsCastableP() then
      if HR.Cast(S.WarriorofElune, Settings.Balance.GCDasOffGCD.WarriorofElune) then return "warrior_of_elune 108"; end
    end
    -- innervate,if=azerite.lively_spirit.enabled&(cooldown.incarnation.remains<2|cooldown.celestial_alignment.remains<12)
    if S.Innervate:IsCastableP() and Settings.Balance.ShowInnervate and (S.LivelySpirit:AzeriteEnabled() and (S.Incarnation:CooldownRemainsP() < 2 or S.CelestialAlignment:CooldownRemainsP() < 12)) then
      if HR.Cast(S.Innervate) then return "innervate 110"; end
    end
    -- force_of_nature,if=(variable.az_ss&!buff.ca_inc.up|!variable.az_ss&(buff.ca_inc.up|cooldown.ca_inc.remains>30))&ap_check
    if S.ForceofNature:IsCastableP() and ((bool(VarAzSs) and Player:BuffDownP(CaInc()) or not bool(VarAzSs) and (Player:BuffP(CaInc()) or CaInc():CooldownRemainsP() > 30)) and AP_Check(S.ForceofNature)) then
      if HR.Cast(S.ForceofNature, Settings.Balance.GCDasOffGCD.ForceofNature, nil, 40) then return "force_of_nature 1111"; end
    end
    -- incarnation,if=!buff.ca_inc.up&(buff.memory_of_lucid_dreams.up|((cooldown.memory_of_lucid_dreams.remains>20|!essence.memory_of_lucid_dreams.major)&ap_check))&(buff.memory_of_lucid_dreams.up|ap_check),target_if=dot.sunfire.remains>8&dot.moonfire.remains>12&(dot.stellar_flare.remains>6|!talent.stellar_flare.enabled)
    if S.Incarnation:IsCastableP() and (Player:BuffDownP(CaInc()) and (Player:BuffP(S.MemoryofLucidDreams) or ((S.MemoryofLucidDreams:CooldownRemainsP() > 20 or not Spell:MajorEssenceEnabled(AE.MemoryofLucidDreams)) and AP_Check(S.Incarnation))) and (Player:BuffP(S.MemoryofLucidDreams) or AP_Check(S.Incarnation)) and (Target:DebuffRemainsP(S.SunfireDebuff) > 8 and Target:DebuffRemainsP(S.MoonfireDebuff) > 12 and (Target:DebuffRemainsP(S.StellarFlareDebuff) > 6 or not S.StellarFlare:IsAvailable()))) then
      if HR.Cast(S.Incarnation, Settings.Balance.GCDasOffGCD.CelestialAlignment) then return "incarnation 228" end
    end
    -- celestial_alignment,if=!buff.ca_inc.up&(!talent.starlord.enabled|buff.starlord.up)&(buff.memory_of_lucid_dreams.up|((cooldown.memory_of_lucid_dreams.remains>20|!essence.memory_of_lucid_dreams.major)&ap_check))&(!azerite.lively_spirit.enabled|buff.lively_spirit.up),target_if=(dot.sunfire.remains>2&dot.moonfire.ticking&(dot.stellar_flare.ticking|!talent.stellar_flare.enabled))
    if S.CelestialAlignment:IsCastableP() and (Player:BuffDownP(CaInc()) and (not S.Starlord:IsAvailable() or Player:BuffP(S.StarlordBuff)) and (Player:BuffP(S.MemoryofLucidDreams) or ((S.MemoryofLucidDreams:CooldownRemainsP() > 20 or not Spell:MajorEssenceEnabled(AE.MemoryofLucidDreams)) and AP_Check(S.CelestialAlignment))) and (not S.LivelySpirit:AzeriteEnabled() or Player:BuffP(S.LivelySpiritBuff)) and (Target:DebuffRemainsP(S.SunfireDebuff) > 2 and Target:DebuffP(S.MoonfireDebuff) and (Target:DebuffP(S.StellarFlareDebuff) or not S.StellarFlare:IsAvailable()))) then
      if HR.Cast(S.CelestialAlignment, Settings.Balance.GCDasOffGCD.CelestialAlignment) then return "celestial_alignment 253" end
    end
    -- fury_of_elune,if=(buff.ca_inc.up|cooldown.ca_inc.remains>30)&solar_wrath.ap_check
    if S.FuryofElune:IsCastableP() and ((Player:BuffP(CaInc()) or CaInc():CooldownRemainsP() > 30) and AP_Check(S.SolarWrath)) then
      if HR.Cast(S.FuryofElune, Settings.Balance.GCDasOffGCD.FuryofElune, nil, 40) then return "fury_of_elune 146"; end
    end
    -- cancel_buff,name=starlord,if=buff.starlord.remains<3&!solar_wrath.ap_check
    -- if (Player:BuffRemainsP(S.StarlordBuff) < 3 and not bool(solar_wrath.ap_check)) then
      -- if HR.Cancel(S.StarlordBuff) then return ""; end
    -- end
    -- starfall,if=(!solar_wrath.ap_check|(buff.starlord.stack<3|buff.starlord.remains>=8)&(fight_remains+1)*spell_targets>cost%2.5)&spell_targets>=variable.sf_targets
    if S.Starfall:IsReadyP() then
      local FightRemains = HL.FightRemains(40)
      if ((not AP_Check(S.SolarWrath) or (Player:BuffStackP(S.StarlordBuff) < 3 or Player:BuffRemainsP(S.StarlordBuff) >= 8) and (FightRemains + 1) * EnemiesCount > S.Starfall:Cost() % 2.5) and EnemiesCount >= VarSfTargets) then
        if HR.Cast(S.Starfall, Settings.Balance.GCDasOffGCD.Starfall) then return "starfall 164"; end
      end
    end
    -- starsurge,if=((talent.starlord.enabled&(buff.starlord.stack<3|buff.starlord.remains>=5&buff.arcanic_pulsar.stack<8)|!talent.starlord.enabled&(buff.arcanic_pulsar.stack<8|buff.ca_inc.up))&buff.solar_empowerment.stack<3&buff.lunar_empowerment.stack<3&buff.reckless_force_counter.stack<19|buff.reckless_force.up)&spell_targets.starfall<variable.sf_targets&(!variable.az_ss|!buff.ca_inc.up|!prev.starsurge)|fight_remains<=execute_time*astral_power%40|!solar_wrath.ap_check
    if S.Starsurge:IsReadyP() and (((S.Starlord:IsAvailable() and (Player:BuffStackP(S.StarlordBuff) < 3 or Player:BuffRemainsP(S.StarlordBuff) >= 5 and Player:BuffStackP(S.ArcanicPulsarBuff) < 8) or not S.Starlord:IsAvailable() and (Player:BuffStackP(S.ArcanicPulsarBuff) < 8 or Player:BuffP(CaInc()))) and Player:BuffStackP(S.SolarEmpowermentBuff) < 3 and Player:BuffStackP(S.LunarEmpowermentBuff) < 3 and Player:BuffStackP(S.RecklessForceBuff) < 19 or Player:BuffDownP(S.RecklessForceBuff)) and EnemiesCount < VarSfTargets and (not VarAzSs or Player:BuffDownP(CaInc()) or not Player:PrevGCDP(1, S.Starsurge)) or HL.BossFilteredFightRemains("<", S.Starsurge:ExecuteTime() * Player:AstralPower() % 40) or not AP_Check(S.SolarWrath)) then
      if HR.Cast(S.Starsurge, nil, nil, 40) then return "starsurge 188"; end
    end
    -- sunfire,if=buff.ca_inc.up&buff.ca_inc.remains<gcd.max&variable.az_ss&dot.moonfire.remains>remains
    if S.Sunfire:IsCastableP() and (Player:BuffP(CaInc()) and Player:BuffRemainsP(CaInc()) < Player:GCD() and bool(VarAzSs) and Target:DebuffRemainsP(S.MoonfireDebuff) > Target:DebuffRemainsP(S.SunfireDebuff)) then
      if HR.Cast(S.Sunfire, nil, nil, 40) then return "sunfire 222"; end
    end
    -- moonfire,if=buff.ca_inc.up&buff.ca_inc.remains<gcd.max&variable.az_ss
    if S.Moonfire:IsCastableP() and (Player:BuffP(CaInc()) and Player:BuffRemainsP(CaInc()) < Player:GCD() and bool(VarAzSs)) then
      if HR.Cast(S.Moonfire, nil, nil, 40) then return "moonfire 238"; end
    end
    -- sunfire,target_if=refreshable,if=ap_check&floor(target.time_to_die%(2*spell_haste))*spell_targets>=ceil(floor(2%spell_targets)*1.5)+2*spell_targets&(spell_targets>1+talent.twin_moons.enabled|dot.moonfire.ticking)&(!variable.az_ss|!buff.ca_inc.up|!prev.sunfire)&(buff.ca_inc.remains>remains|!buff.ca_inc.up)
    if S.Sunfire:IsCastableP() then
      if HR.CastCycle(S.Sunfire, 40, EvaluateCycleSunfire250) then return "sunfire 308" end
    end
    -- moonfire,target_if=refreshable,if=ap_check&floor(target.time_to_die%(2*spell_haste))*spell_targets>=6&(!variable.az_ss|!buff.ca_inc.up|!prev.moonfire)&(buff.ca_inc.remains>remains|!buff.ca_inc.up)
    if S.Moonfire:IsCastableP() then
      if HR.CastCycle(S.Moonfire, 40, EvaluateCycleMoonfire313) then return "moonfire 343" end
    end
    -- stellar_flare,target_if=refreshable,if=ap_check&floor(target.time_to_die%(2*spell_haste))>=5&(!variable.az_ss|!buff.ca_inc.up|!prev.stellar_flare)
    if S.StellarFlare:IsCastableP() then
      if HR.CastCycle(S.StellarFlare, 40, EvaluateCycleStellarFlare348) then return "stellar_flare 360" end
    end
    -- new_moon,if=ap_check
    if S.NewMoon:IsCastableP() and (AP_Check(S.NewMoon)) then
      if HR.Cast(S.NewMoon, nil, nil, 40) then return "new_moon 361"; end
    end
    -- half_moon,if=ap_check
    if S.HalfMoon:IsCastableP() and (AP_Check(S.HalfMoon)) then
      if HR.Cast(S.HalfMoon, nil, nil, 40) then return "half_moon 363"; end
    end
    -- full_moon,if=ap_check
    if S.FullMoon:IsCastableP() and (AP_Check(S.FullMoon)) then
      if HR.Cast(S.FullMoon, nil, nil, 40) then return "full_moon 365"; end
    end
    -- lunar_strike,if=buff.solar_empowerment.stack<3&(ap_check|buff.lunar_empowerment.stack=3)&((buff.warrior_of_elune.up|buff.lunar_empowerment.up|spell_targets>=2&!buff.solar_empowerment.up)&(!variable.az_ss|!buff.ca_inc.up)|variable.az_ss&buff.ca_inc.up&prev.solar_wrath)
    if S.LunarStrike:IsCastableP() and (Player:BuffStackP(S.SolarEmpowermentBuff) < 3 and (AP_Check(S.LunarStrike) or Player:BuffStackP(S.LunarEmpowermentBuff) == 3) and ((Player:BuffP(S.WarriorofEluneBuff) or Player:BuffP(S.LunarEmpowermentBuff) or EnemiesCount >= 2 and Player:BuffDownP(S.SolarEmpowermentBuff)) and (not bool(VarAzSs) or Player:BuffDownP(CaInc())) or bool(VarAzSs) and Player:BuffP(CaInc()) and Player:PrevGCDP(1, S.SolarWrath))) then
      if HR.Cast(S.LunarStrike, nil, nil, 40) then return "lunar_strike 367"; end
    end
    -- solar_wrath,if=variable.az_ss<3|!buff.ca_inc.up|!prev.solar_wrath
    if S.SolarWrath:IsCastableP() and (VarAzSs < 3 or Player:BuffDownP(CaInc()) or not Player:PrevGCDP(1, S.SolarWrath)) then
      if HR.Cast(S.SolarWrath, nil, nil, 40) then return "solar_wrath 393"; end
    end
    -- sunfire
    if S.Sunfire:IsCastableP() then
      if HR.Cast(S.Sunfire, nil, nil, 40) then return "sunfire 399"; end
    end
  end
end

local function Init()
  HL.RegisterNucleusAbility(164815, 8, 6)               -- Sunfire DoT
  HL.RegisterNucleusAbility(191037, 15, 6)              -- Starfall
  HL.RegisterNucleusAbility(194153, 8, 6)               -- Lunar Strike
end

HR.SetAPL(102, APL, Init)
