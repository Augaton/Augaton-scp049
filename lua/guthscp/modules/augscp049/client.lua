local augscp049 = guthscp.modules.augscp049
local config049 = guthscp.configs.augscp049
scp049 = scp049 or {}

-- Colors
local color_bg = Color(80, 80, 80, 255)
local color_btn = Color(68, 68, 68, 255)
local color_btn_hover = Color(90, 90, 90, 255)
local color_text = Color(200, 200, 200, 255)
local color_header = Color(53, 53, 53, 255)
local color_header_hover = Color(65, 65, 65, 255)

function augscp049.ZombieMenu()
    if IsValid(SCPZombieMenu) then SCPZombieMenu:Remove() end

    local zombietypes = augscp049.GetZombieTypes049()
    local count = #zombietypes

    local w, h = ScrW() / 2.25, ScrH() / 2.25
    local targetY = ScrH() / 2 - h / 2
    local startY = targetY + 50 

    SCPZombieMenu = vgui.Create('DFrame')
    SCPZombieMenu:SetSize(w, h)
    SCPZombieMenu:SetPos(ScrH() / 2 - w / 2, startY)
    SCPZombieMenu:SetTitle('')
    SCPZombieMenu:MakePopup()
    SCPZombieMenu:SetDraggable(false)
    SCPZombieMenu:ShowCloseButton(false)
    SCPZombieMenu:CenterHorizontal()

    local animAlpha = 0
    local animY = startY

    SCPZombieMenu.Paint = function(self, w, h)
        animAlpha = Lerp(FrameTime() * 10, animAlpha, 255)
        animY = Lerp(FrameTime() * 10, animY, targetY)
        
        self:SetAlpha(animAlpha)
        self:SetPos(self:GetX(), animY)

        draw.RoundedBox(5, 0, 0, w, h, color_bg)
    end

    SCPZombieMenu.Think = function(self)
        if input.IsKeyDown(KEY_R) then
            self:Close()
        end
    end

    local CloseButton = vgui.Create('DButton', SCPZombieMenu)
    CloseButton:SetSize(w, h / 11.3)
    CloseButton:SetPos(0, 0)
    CloseButton:SetText('')
    CloseButton.CurrentColor = color_header
    CloseButton.Paint = function(self, w, h)
        draw.RoundedBoxEx(5, 0, 0, w, h, self.CurrentColor, true, true, false, false)
        draw.SimpleText(config049.translation_5, 'scp-sweps1', w / 2, h / 2, color_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    CloseButton.DoClick = function() SCPZombieMenu:Close() end
    CloseButton.OnCursorEntered = function(self) self.CurrentColor = color_header_hover end
    CloseButton.OnCursorExited = function(self) self.CurrentColor = color_header end

    local buttonW = w / 3.5
    local modelW, modelH = (ScrW() / 16) * 2.5, (ScrH() / 9) * 2.5
    local spacing_base = w / 5
    local usable_w = w - (spacing_base * 2)

    for k, v in ipairs(zombietypes) do
        local fraction = (count > 1) and ((k - 1) / (count - 1)) or 0.5
        local posX = spacing_base + (usable_w * fraction)

        -- Background Panel
        local bgPanel = vgui.Create('DPanel', SCPZombieMenu)
        bgPanel:SetSize(buttonW, modelH * 1.1)
        bgPanel:SetPos(posX - buttonW / 2, h / 1.925 - (modelH * 1.2 / 2))
        bgPanel.CurrentColor = color_btn
        bgPanel.Paint = function(self, w, h)
            draw.RoundedBox(5, 0, 0, w, h, self.CurrentColor)
        end

        -- Model
        local ZombieModel = vgui.Create('DModelPanel', SCPZombieMenu)
        ZombieModel:SetSize(modelW, modelH)
        ZombieModel:SetPos(posX - modelW / 2, h / 2.1 - modelH / 2)
        ZombieModel:SetModel(v.model)
        ZombieModel:SetFOV(45)
        
        -- Button
        local ZombieButton = vgui.Create('DButton', SCPZombieMenu)
        ZombieButton:SetSize(buttonW, h / 13)
        ZombieButton:SetPos(posX - buttonW / 2, h - h / 7.1)
        ZombieButton:SetText('')
        ZombieButton.Paint = function(self, w, h)
            draw.RoundedBox(5, 0, 0, w, h, bgPanel.CurrentColor)
            draw.SimpleText(v.name, 'scp-sweps1', w / 2, h / 2, color_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- Hover logic
        local function onHover() bgPanel.CurrentColor = color_btn_hover end
        local function offHover() bgPanel.CurrentColor = color_btn end

        ZombieButton.OnCursorEntered = onHover; ZombieButton.OnCursorExited = offHover
        ZombieModel.OnCursorEntered = onHover; ZombieModel.OnCursorExited = offHover
        
        -- Action
        local function click() 
            net.Start('scp049-change-zombie')
                net.WriteInt(k, 7)
            net.SendToServer()
            SCPZombieMenu:Close()
        end
        ZombieButton.DoClick = click
        ZombieModel.DoClick = click
    end
end