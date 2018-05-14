--todo: Block Flash when zilean has ult on yourself

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

    vpred = VPrediction(true)

    myHero = GetMyHero()

    comboStep = 0

    isDoubleCast = 0

    self.Q = Spell(_Q, 880)
    self.W = Spell(_W, 0)
    self.E = Spell(_E, 750)
    self.R = Spell(_R, 880)

    self.Q:SetSkillShot(0.3, math.huge, 212, false)
    self.W:SetActive()
    self.E:SetTargetted()
    self.R:SetTargetted()


    Callback.Add("Tick", function(...) self:OnTick(...) end)
    Callback.Add("DrawMenu", function(...) self:OnDrawMenu(...) end)

    self:MenuValueDefault()
end

--menu
function Zilean:MenuValueDefault()

    self.menu = "ApZilean"
    self.autoUlt = self:MenuSliderInt("AutoUlt if n% hp (0 = off)", 20)
    self.autoUltAllies = self:MenuBool("autoUltAllies", true)
    self.autoQ = self:MenuSliderInt("Auto2Q (Q + W + Q) if n enemies", 3)
    self.bombtomouse = self:MenuKeyBinding("DoubleBomb to mouse", 90)
    self.blockR = self:MenuBool("Block Flash when zilean has ult on yourself", true)
end


function Zilean:OnDrawMenu()
    if Menu_Begin(self.menu) then
            self.autoUlt = Menu_SliderInt("AutoUlt if n% hp (0 = off)", self.autoUlt, 0, 100, self.menu)
            self.autoUltAllies = Menu_Bool("autoUltAllies", self.autoUltAllies, self.menu)
            self.autoQ = Menu_SliderInt("Auto2Q (Q + W + Q) if n enemies", self.autoQ, 0, 5, self.menu)
            self.bombtomouse = Menu_KeyBinding("DoubleBomb to mouse", self.bombtomouse, self.menu)
            self.blockR = Menu_Bool("Block Flash when zilean has ult on yourself", self.blockR, self.menu)

        Menu_End()
    end
end

function Zilean:MenuBool(stringKey, bool)
    return ReadIniBoolean(self.menu, stringKey, bool)
end

function Zilean:MenuSliderInt(stringKey, valueDefault)
    return ReadIniInteger(self.menu, stringKey, valueDefault)
end

function Zilean:MenuSliderFloat(stringKey, valueDefault)
    return ReadIniFloat(self.menu, stringKey, valueDefault)
end

function Zilean:MenuComboBox(stringKey, valueDefault)
    return ReadIniInteger(self.menu, stringKey, valueDefault)
end

function Zilean:MenuKeyBinding(stringKey, valueDefault)
    return ReadIniInteger(self.menu, stringKey, valueDefault)
end

--endmenu

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

function Zilean:misc()
    --BombToMouse
    if (GetKeyPress(self.bombtomouse) > 0  and self.bombtomouse and CanCast(_Q) and CanCast(_W)) then
        doubleCastpos = GetMousePos()

        CastSpellToPos(doubleCastpos.x, doubleCastpos.z, _Q)

        isDoubleCast = 1

    elseif(isDoubleCast == 1) then
        self.W:Cast(myHero)
        CastSpellTarget(doubleCastpos, _Q)
        isDoubleCast = 0
    end

    --AutoUlt me and allies
    if (self.autoUlt and CanCast(_R)) then
        if (myHero.HP / myHero.MaxHP * 100 <= self.autoUlt) then
            if (CountEnemyChampAroundObject(myHero.Addr, 880)) then
                CastSpellTarget(myHero.Addr, _R)
            end
        end

        if (self.autoUltAllies and CanCast(_R)) then
            for i,hero in pairs(GetAllyHeroes()) do
                if hero ~= nil then
                    local ally = GetAIHero(hero)
                    if not ally.IsMe and not ally.IsDead and GetDistance(ally.Addr) <= self.R.range then
                        if ally.HP / ally.MaxHP * 100 <= self.autoUlt and CountEnemyChampAroundObject(ally.Addr, 880) then
                            CastSpellTarget(ally.Addr, _R)
                        end
                    end
                end
            end
        end
    end


    if (GetKeyPress(32) == 0 and self.autoQ and CountEnemyChampAroundObject(myHero.Addr, 880) >= self.autoQ and CanCast(_Q) and CanCast(_W)) then

        local target = GetTarget(880)

        if IsValidTarget(target, 900) then
            target = GetAIHero(target)

            self.Q:Cast(target)

            doubleCastpos = target.Addr

            isDoubleCast = 1

        end
    end
end


function Zilean:OnTick()
    if (IsDead(myHero.Addr)
            or myHero.IsRecall
            or IsTyping()
            or IsDodging())
            or not IsRiotOnTop() then return
    end

    self:misc()

    if GetKeyPress(32) > 0 then
        self:ComboVombo()
    end
end



