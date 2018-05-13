--todo: menu
--todo: Ult logic
--todo: Misc: Auto2Q (Q + W + Q) if n enemies, bombtomouse, Block Flash when zilean has ult on yourself

IncludeFile("Lib\\TOIR_SDK.lua")

Zilean = class()

--Helper functions

local function PrintChat(msg)
    return __PrintTextGame("<b><font color='#f1c40f'>[Zilean logs] </font></b><font color='#ecf0f1'>" .. msg .. "</font>")
end

local function GetTarget(range)
    return GetEnemyChampCanKillFastest(range)
end

function OnLoad()
    if GetChampName(GetMyChamp()) == "Zilean" then
        PrintChat("You are welcome!) Good luck boy")
        Zilean:__init()
    else
        PrintChat("This script only supports Zilean, your current champ is: " .. GetChampName(GetMyChamp()))
    end
end

function Zilean:__init()
    SetLuaCombo(true)

    myHero = GetMyHero()

    comboStep = 0

    gapcloseStep = 0


    self.Q = Spell(_Q, 880)
    self.W = Spell(_W, 0)
    self.E = Spell(_E, 750)
    self.R = Spell(_R, 880)

    self.Q:SetSkillShot(0.3, math.huge, 212, false)
    self.W:SetActive()
    self.E:SetTargetted()
    self.R:SetTargetted()

    Callback.Add("Tick", function(...) self:OnTick(...) end)
end

function Zilean:ComboVombo()
    local target = GetTarget(901)


    if IsValidTarget(target, 900) == false or IsCasting(myHero) then return end
    --full combo
    if (CanCast(_Q) and CanCast(_W) and CanCast(_E) and comboStep == 0) then
        if (GetDistance(target) <= 750) then
            self.E:Cast(target)

            self.Q:Cast(target)

            comboStep = 1

        else
            --todo: give speed to our adc if support mode
            CastSpellTarget(myHero.Addr, _E)
        end

    --Combo without E
    elseif (CanCast(_Q) and CanCast(_W) and comboStep == 0) then
        self.Q:Cast(target)
        comboStep = 2

    --Lazy combo
    elseif (CanCast(_Q) and comboStep == 0) then
        self.Q:Cast(target)

    --merged steps
    elseif ((CanCast(_W) and comboStep == 1) or (CanCast(_W) and comboStep == 2) or (CanCast(_Q) == false and CanCast(_W) and comboStep == 0)) then
        self.W:Cast(myHero)
        self.Q:Cast(target)
        comboStep = 0

    elseif (CanCast(_E)) then
        self.E:Cast(target) --todo: boost our adc if support mode
    end
end


function Zilean:OnTick()
    if (IsDead(myHero.Addr)
            or myHero.IsRecall
            or IsTyping()
            or IsDodging())
            or not IsRiotOnTop() then return
    end

    if GetKeyPress(32) > 0 then
        self:ComboVombo()
    end
end



