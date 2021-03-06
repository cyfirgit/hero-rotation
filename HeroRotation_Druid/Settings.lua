--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...;
-- HeroRotation
local HR = HeroRotation;
-- HeroLib
local HL = HeroLib;
-- File Locals
local GUI = HL.GUI;
local CreateChildPanel = GUI.CreateChildPanel;
local CreatePanelOption = GUI.CreatePanelOption;
local CreateARPanelOption = HR.GUI.CreateARPanelOption;
local CreateARPanelOptions = HR.GUI.CreateARPanelOptions;

--- ============================ CONTENT ============================
-- All settings here should be moved into the GUI someday.
HR.GUISettings.APL.Druid = {
  Commons = {
    UsePotions = true,
    UseTrinkets = true,
    TrinketDisplayStyle = "Suggested",
    EssenceDisplayStyle = "Suggested",
    -- {Display GCD as OffGCD, ForceReturn}
    GCDasOffGCD = {
      -- Abilities
    },
    -- {Display OffGCD as OffGCD, ForceReturn}
    OffGCDasOffGCD = {
      -- Racials
      Racials = true,
      -- Abilities
      SkullBash = true,
    }
  },
  Balance = {
    BarkskinHP = 50,
    RenewalHP = 40,
    ShowMoonkinFormOOC = true,
    ShowInnervate = true,
    UseSplashData = true,
    -- {Display GCD as OffGCD, ForceReturn}
    GCDasOffGCD = {
      MoonkinForm = true,
      CelestialAlignment = true, -- also does Incarnation!
      WarriorofElune = true,
      ForceofNature = true,
      FuryofElune = true,
      Starfall = false,
    },
    -- {Display OffGCD as OffGCD, ForceReturn}
    OffGCDasOffGCD = {
      SolarBeam = true,
      Renewal = true,
      Barkskin = true,
    }
  },
  Feral = {
    UseFABST = false,
    ThrashST = false,
    -- {Display GCD as OffGCD, ForceReturn}
    GCDasOffGCD = {
      CatForm = true,
      -- RegrowthHeal = true,
    },
    -- {Display OffGCD as OffGCD, ForceReturn}
    OffGCDasOffGCD = {
      --Abilities
      Prowl = true,
      TigersFury = true,
      Berserk = true,
      Incarnation = true,
    }
  },
  Guardian = {
    BarkskinHP = 50,
    LunarBeamHP = 50,
    SurvivalInstinctsHP = 30,
    FrenziedRegenHP = 70,
    BristlingFurRage = 50,
    UseRageDefensively = false,
    -- {Display GCD as OffGCD, ForceReturn}
    GCDasOffGCD = {
      FrenziedRegen = true,
      LunarBeam = true,
      Incarnation = false,
    },
    -- {Display OffGCD as OffGCD, ForceReturn}
    OffGCDasOffGCD = {
      Ironfur = true,
      Barkskin = true,
      SurvivalInstincts = true,
    }
  },
  Restoration = {
    UseSplashData = true,
    GCDasOffGCD = {
      Prowl = true,
    }
  },
};

HR.GUI.LoadSettingsRecursively(HR.GUISettings);

-- Child Panels
local ARPanel = HR.GUI.Panel;
local CP_Druid = CreateChildPanel(ARPanel, "Druid");
local CP_Balance = CreateChildPanel(CP_Druid, "Balance");
local CP_Feral = CreateChildPanel(CP_Druid, "Feral");
local CP_Guardian = CreateChildPanel(CP_Druid, "Guardian");
local CP_Restoration = CreateChildPanel(CP_Druid, "Restoration");

CreateARPanelOptions(CP_Druid, "APL.Druid.Commons");
CreatePanelOption("CheckButton", CP_Druid, "APL.Druid.Commons.UsePotions", "Show Potions", "Enable this if you want the addon to show you when to use potions.");
CreatePanelOption("CheckButton", CP_Druid, "APL.Druid.Commons.UseTrinkets", "Use Trinkets", "Use Trinkets as part of the rotation");
CreatePanelOption("Dropdown", CP_Druid, "APL.Druid.Commons.TrinketDisplayStyle", {"Main Icon", "Suggested", "Cooldown"}, "Trinket Display Style", "Define which icon display style to use for Trinkets.");
CreatePanelOption("Dropdown", CP_Druid, "APL.Druid.Commons.EssenceDisplayStyle", {"Main Icon", "Suggested", "Cooldown"}, "Essence Display Style", "Define which icon display style to use for active Azerite Essences.");

--Feral
CreatePanelOption("CheckButton", CP_Feral, "APL.Druid.Feral.UseFABST", "Use Focused Azerite Beam ST", "Suggest Focused Azerite Beam usage during single target combat.");
CreatePanelOption("CheckButton", CP_Feral, "APL.Druid.Feral.ThrashST", "Use Thrash on Single Target", "Suggest Thrash while Clearcasting during single target combat.");
CreateARPanelOptions(CP_Feral, "APL.Druid.Feral");

--Balance
CreatePanelOption("CheckButton", CP_Balance, "APL.Druid.Balance.UseSplashData", "Use Splash Data for AoE", "For AoE purposes, only count enemies previously hit by AoE abilities.");
CreatePanelOption("Slider", CP_Balance, "APL.Druid.Balance.BarkskinHP", {0, 100, 1}, "Barkskin HP", "Set the Barkskin HP threshold.");
CreatePanelOption("Slider", CP_Balance, "APL.Druid.Balance.RenewalHP", {0, 100, 1}, "Renewal HP", "Set the Renewal HP threshold.");
CreatePanelOption("CheckButton", CP_Balance, "APL.Druid.Balance.ShowMoonkinFormOOC", "Show Moonkin Form Out of Combat", "Enable this if you want the addon to show you the Moonkin Form reminder out of combat.");
CreatePanelOption("CheckButton", CP_Balance, "APL.Druid.Balance.ShowInnervate", "Show Innervate in Rotation", "Enable this if you would like the addon to suggest when to use Innervate.");
CreateARPanelOptions(CP_Balance, "APL.Druid.Balance");

--Guardian
CreateARPanelOptions(CP_Guardian, "APL.Druid.Guardian");
CreatePanelOption("CheckButton", CP_Guardian, "APL.Druid.Guardian.UseRageDefensively", "Use Rage Defensively", "Only suggest Maul if not actively tanking or about to cap rage.");
CreatePanelOption("Slider", CP_Guardian, "APL.Druid.Guardian.BarkskinHP", {0, 100, 1}, "Barkskin HP", "Set the Barkskin HP threshold.");
CreatePanelOption("Slider", CP_Guardian, "APL.Druid.Guardian.LunarBeamHP", {0, 100, 1}, "Lunar Beam HP", "Set the Lunar Beam HP threshold.");
CreatePanelOption("Slider", CP_Guardian, "APL.Druid.Guardian.FrenziedRegenHP", {0, 100, 1}, "Frenzied Regeneration HP", "Set the Frenzied Regeneration HP threshold.");
CreatePanelOption("Slider", CP_Guardian, "APL.Druid.Guardian.SurvivalInstinctsHP", {0, 100, 1}, "Survival Instincts HP", "Set the Survival Instincts HP threshold.");
CreatePanelOption("Slider", CP_Guardian, "APL.Druid.Guardian.BristlingFurRage", {0, 100, 1}, "Bristling Fur Rage", "Set the Bristling Fur Rage threshold.");

-- Restoration
CreatePanelOption("CheckButton", CP_Restoration, "APL.Druid.Restoration.UseSplashData", "Use Splash Data for AoE", "For AoE purposes, only count enemies previously hit by AoE abilities.");
CreateARPanelOptions(CP_Restoration, "APL.Druid.Restoration");
