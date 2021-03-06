--todo: Block Flash when zilean has ult on yourself

IncludeFile("Lib\\TOIR_SDK.lua")

Zilean = class()

--Helper functions

local function PrintChat(msg)
    return __PrintTextGame("<b><font color='#f1c40f'>[Zilean logs] </font></b><font color='#ecf0f1'>" .. msg .. "</font>")
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

    immobileQ = 0

    gapclosing = 0

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

    Callback.Add("ProcessSpell", function(unit, spell) self:OnProcessSpell(unit, spell) end)

    --[[Callback.Add("RemoveBuff", function(unit, buff) self:OnRemoveBuff(unit, buff) end)
    Callback.Add("UpdateBuff", function(unit, buff, stacks) self:OnUpdateBuff(source, unit, buff, stacks) end) --]]


    self:MenuValueDefault()
end

function Zilean:GetQCirclePreCore(target) --NickyJhin credits
    local castPosX, castPosZ, unitPosX, unitPosZ, hitChance, _aoeTargetsHitCount = GetPredictionCore(target.Addr, 1, self.Q.delay, self.Q.width, self.Q.range, self.Q.speed, myHero.x, myHero.z, false, false, 1, 5, 5, 5, 5, 5)
    if target ~= nil then
        CastPosition = Vector(castPosX, target.y, castPosZ)
        HitChance = hitChance
        Position = Vector(unitPosX, target.y, unitPosZ)
        return CastPosition, HitChance, Position
    end
    return nil, 0, nil
end

function Zilean:CanMove(unit) --NickyJhin Credits
    if (unit.MoveSpeed < 50 or CountBuffByType(unit.Addr, 5) == 1 or CountBuffByType(unit.Addr, 21) == 1 or CountBuffByType(unit.Addr, 11) == 1 or CountBuffByType(unit.Addr, 29) == 1 or
            unit.HasBuff("recall") or CountBuffByType(unit.Addr, 30) == 1 or CountBuffByType(unit.Addr, 22) == 1 or CountBuffByType(unit.Addr, 8) == 1 or CountBuffByType(unit.Addr, 24) == 1
            or CountBuffByType(unit.Addr, 20) == 1 or CountBuffByType(unit.Addr, 18) == 1) then
        return false
    end
    return true
end

function Zilean:OnProcessSpell(unit, spell)
    if unit.IsMe and spell.Name == 'ZileanW' and gapclosing == 1 then
        gapclosing = 0
    end
end

--menu
function Zilean:MenuValueDefault()

    self.menu = "ApZilean"
    self.autoUlt = self:MenuSliderInt("AutoUlt if n% hp (0 = off)", 25)
    self.autoUltAllies = self:MenuBool("autoUltAllies", true)
    self.immobile = self:MenuBool("Auto2Q Immobile targets", true)
    self.autoQ = self:MenuSliderInt("Auto2Q (Q + W + Q) if n enemies", 3)
    self.flee = self:MenuKeyBinding("Flee", 90)
    self.bombtomouse = self:MenuKeyBinding("Q To Mouse", 84)
    self.antigap = self:MenuBool("Antigapcloser", true)
    --self.blockR = self:MenuBool("Block Flash when zilean has ult on yourself", true)
    self.supportMode = self:MenuBool("Support mode", true)
end

--[[function Zilean:OnUpdateBuff(source, unit, buff, stacks)
    if unit.IsMe and buff.name == "ChronoShift" then
    end
end
function Zilean:OnRemoveBuff(unit, buff)
    if unit.IsMe then
        self.blinks = true
    end
end
--]]




function Zilean:OnDrawMenu()
    if Menu_Begin(self.menu) then
        self.autoUlt = Menu_SliderInt("AutoUlt if n% hp (0 = off)", self.autoUlt, 0, 100, self.menu)
        self.autoUltAllies = Menu_Bool("autoUltAllies", self.autoUltAllies, self.menu)
        self.immobile = Menu_Bool("Auto2Q Immobile targets", self.immobile, self.menu)
        self.autoQ = Menu_SliderInt("Auto2Q (Q + W + Q) if n enemies", self.autoQ, 0, 5, self.menu)
        self.flee = Menu_KeyBinding("Flee", self.flee, self.menu)
        self.bombtomouse = Menu_KeyBinding("DoubleBomb to mouse", self.bombtomouse, self.menu)
        self.antigap = Menu_Bool("Antigapcloser", self.antigap, self.menu)
        --self.blockR = Menu_Bool("Block Flash when zilean has ult on yourself", self.blockR, self.menu)
        self.supportMode = Menu_Bool("Support mode", self.supportMode, self.menu)
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
    local target = GetAIHero(GetTargetOrb())



    if IsValidTarget(target, 900) == false or IsCasting(myHero) then return end
    --full combo
    if (CanCast(_Q) and CanCast(_W) and CanCast(_E) and comboStep == 0) then
        if (GetDistance(target) <= 750) then
            self.E:Cast(target.Addr)

            local CastPosition, HitChance, Position = self:GetQCirclePreCore(target)

            if not self:CanMove(target) then
                CastSpellToPos(target.x, target.z, _Q)
                comboStep = 1
            elseif HitChance >= 6 then
                CastSpellToPos(CastPosition.x, CastPosition.z, _Q)
                comboStep = 1
            end



            --self.Q:Cast(target)

            --comboStep = 1
        else
            if (self.supportMode) then
                for i, hero in pairs(GetAllyHeroes()) do
                    if hero ~= nil then
                        local ally = GetAIHero(hero)
                        if not ally.IsMe and not ally.IsDead and GetDistance(ally.Addr) <= self.E.range then
                            CastSpellTarget(ally.Addr, _E)
                        else
                            CastSpellTarget(myHero.Addr, _E)
                        end
                    else
                        CastSpellTarget(myHero.Addr, _E)
                    end
                end
            else
                CastSpellTarget(myHero.Addr, _E)
            end
        end
        --Combo without E
    elseif (CanCast(_Q) and CanCast(_W) and comboStep == 0) then
        local CastPosition, HitChance, Position = self:GetQCirclePreCore(target)

        if not self:CanMove(target) then
            CastSpellToPos(target.x, target.z, _Q)
            comboStep = 2
        elseif HitChance >= 6 then
            CastSpellToPos(CastPosition.x, CastPosition.z, _Q)
            comboStep = 2
        end

        --Lazy combo
    elseif (CanCast(_Q) and comboStep == 0) then
        local CastPosition, HitChance, Position = self:GetQCirclePreCore(target)

        if not self:CanMove(target) then
            CastSpellToPos(target.x, target.z, _Q)
        elseif HitChance >= 6 then
            CastSpellToPos(CastPosition.x, CastPosition.z, _Q)
        end
        --merged steps
    elseif ((CanCast(_W) and comboStep == 1) or (CanCast(_W) and comboStep == 2) or (CanCast(_Q) == false and CanCast(_W) and comboStep == 0)) then
        self.W:Cast(myHero.Addr)

        local CastPosition, HitChance, Position = self:GetQCirclePreCore(target)

        if not self:CanMove(target) then
            CastSpellToPos(target.x, target.z, _Q)
            comboStep = 0
        elseif HitChance >= 5 then
            CastSpellToPos(CastPosition.x, CastPosition.z, _Q)
            comboStep = 0
        end


    elseif (CanCast(_E)) then
        if (self.supportMode) then
            for i, hero in pairs(GetAllyHeroes()) do
                if hero ~= nil then
                    local ally = GetAIHero(hero)
                    if not ally.IsMe and not ally.IsDead and GetDistance(ally.Addr) <= self.E.range then
                        CastSpellTarget(ally.Addr, _E)
                    else
                        self.E:Cast(target.Addr)
                    end
                else
                    self.E:Cast(target.Addr)
                end
            end
        else
            self.E:Cast(target.Addr)
        end
    end
end

function Zilean:AntiGapCloser() --credits to NickyJhin

    for i, heros in pairs(GetEnemyHeroes()) do
        if heros ~= nil then
            local hero = GetAIHero(heros)
            local TargetDashing, CanHitDashing, DashPosition = vpred:IsDashing(hero, 0.09, 65, 2000, myHero, false)
            local myHeroPos = Vector(myHero.x, myHero.y, myHero.z)

            if DashPosition ~= nil then
                if GetDistance(DashPosition) < self.Q.range and CanCast(_Q) and CanCast(_W) then
                    CastSpellToPos(DashPosition.x, DashPosition.z, _Q)
                    gapclosing = 1
                    gapposition = DashPosition
                end
            end
            --end
        end
    end

    if (gapclosing == 1) then
        self.W:Cast(myHero.Addr)
        CastSpellToPos(gapposition.x, gapposition.z, _Q)
    end
end

function Zilean:misc()
    if (self.antigap) then self:AntiGapCloser() end

    --BombToMouse
    if (GetKeyPress(self.bombtomouse) > 0 and CanCast(_Q) and CanCast(_W)) then
        doubleCastpos = GetMousePos()

        CastSpellToPos(doubleCastpos.x, doubleCastpos.z, _Q)

        isDoubleCast = 1

    elseif (isDoubleCast == 1) then
        self.W:Cast(myHero.Addr)
        CastSpellTarget(doubleCastpos, _Q)
        isDoubleCast = 0
    end

    if (GetKeyPress(self.flee) > 0) then
        local mousePos = Vector(GetMousePos())
        MoveToPos(GetMousePosX(), GetMousePosZ())
        if (CanCast(_E)) then CastSpellTarget(myHero.Addr, _E) end
        if (CanCast(_W)) then CastSpellTarget(myHero.Addr, _W) end
    end

    if (self.immobile) then
        if (immobileQ == 1) then
            CastSpellTarget(myHero.Addr, _W)
            CastSpellToPos(immobilePos.x, immobilePos.z, _Q)
            immobileQ = 0
        else
            local t = GetEnemyHeroes()

            for k, v in pairs(t) do
                local enemy = GetAIHero(v)
                if enemy ~= 0 then
                    if GetDistance(enemy) < self.Q.range and self:CanMove(enemy) == false and self.Q:IsReady() and self.W:IsReady() then
                        CastSpellToPos(enemy.x, enemy.z, _Q)
                        immobileQ = 1
                        immobilePos = enemy
                    end
                end
            end
        end
    end

    --AutoUlt me and allies
    if (self.autoUlt and CanCast(_R)) then
        if (myHero.HP / myHero.MaxHP * 100 <= self.autoUlt) then
            if (CountEnemyChampAroundObject(myHero.Addr, 880)) then
                CastSpellTarget(myHero.Addr, _R)
            end
        end

        if (self.autoUltAllies and CanCast(_R)) then
            for i, hero in pairs(GetAllyHeroes()) do
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

        local target = GetAIHero(GetTargetOrb())

        if IsValidTarget(target, 900) then
            self.Q:Cast(target.Addr)

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