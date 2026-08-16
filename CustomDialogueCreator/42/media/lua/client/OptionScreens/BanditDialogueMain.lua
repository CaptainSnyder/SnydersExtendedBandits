-- Custom Dialogue Creator: per-clan custom dialogue editor screen.
-- Opened from BanditClanMain via the "Custom Dialogue" button.

require "BanditDialogueCustom"

BanditDialogueMain = ISPanel:derive("BanditDialogueMain")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6

local TRIGGERS = {
    { key = "SPOTTED",  label = "When Spotting Player" },
    { key = "HIT",      label = "When Taking Damage" },
    { key = "BREACH",   label = "When Breaching a Door" },
    { key = "RELOADING",label = "When Reloading" },
    { key = "CAR",      label = "When Spotting a Vehicle" },
    { key = "DEATH",    label = "When Dying" },
    { key = "DEAD",     label = "When Dead (post-death)" },
    { key = "BURN",     label = "When On Fire" },
    { key = "RANDOM",   label = "Random Dialogue (ambient, no trigger)" },
}

-- Trim and strip newlines only, unlike BanditUtils.SanitizeString which
-- replaces all whitespace (including spaces) with underscores - fine for
-- single-word identifiers, wrong for free-form dialogue sentences.
local function sanitizeDialogueText(str)
    if not str then return "" end
    str = str:gsub("[\r\n]", " ")
    str = str:match("^%s*(.-)%s*$")
    return str
end

local function triggerLabel(key)
    for _, t in ipairs(TRIGGERS) do
        if t.key == key then return t.label end
    end
    return key
end

function BanditDialogueMain:initialise()
    ISPanel.initialise(self)
    self:buildUI()
end

function BanditDialogueMain:buildUI()
    self:clearChildren()

    local topY = 50
    local leftX = UI_BORDER_SPACING

    local lbl = ISLabel:new(leftX, topY, BUTTON_HGT, "Custom Dialogue Lines", 1, 1, 1, 1, UIFont.Medium, false)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)

    local listY = topY + BUTTON_HGT + 8
    local listHeight = 220

    self.list = ISScrollingListBox:new(leftX, listY, self.width - (UI_BORDER_SPACING * 2), listHeight)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = BUTTON_HGT + 4
    self.list.selected = 0
    self.list.font = UIFont.Small
    self.list.doDrawItem = BanditDialogueMain.drawListItem
    self.list.target = self
    self.list.onmousedown = BanditDialogueMain.onRowSelected
    self:addChild(self.list)

    self:refreshList()

    local formY = listY + listHeight + UI_BORDER_SPACING

    self.deleteBtn = ISButton:new(leftX, formY, 160, BUTTON_HGT, "Delete Selected", self, BanditDialogueMain.onClick)
    self.deleteBtn.internal = "DELETE"
    self.deleteBtn:initialise()
    self.deleteBtn:instantiate()
    if BanditCompatibility.GetGameVersion() >= 42 then
        self.deleteBtn:enableCancelColor()
    end
    self:addChild(self.deleteBtn)

    self.clearBtn = ISButton:new(leftX + 160 + UI_BORDER_SPACING, formY, 160, BUTTON_HGT, "New Dialogue (clear form)", self, BanditDialogueMain.onClick)
    self.clearBtn.internal = "CLEAR"
    self.clearBtn:initialise()
    self.clearBtn:instantiate()
    self:addChild(self.clearBtn)

    formY = formY + BUTTON_HGT + UI_BORDER_SPACING

    lbl = ISLabel:new(leftX, formY, BUTTON_HGT, "Add Dialogue", 1, 1, 1, 1, UIFont.Medium, false)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)
    formY = formY + BUTTON_HGT + 8

    lbl = ISLabel:new(leftX, formY, BUTTON_HGT, "Trigger:", 1, 1, 1, 1, UIFont.Small, false)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)

    self.triggerCombo = ISComboBox:new(leftX + 90, formY, 220, BUTTON_HGT, self)
    self.triggerCombo:initialise()
    for _, t in ipairs(TRIGGERS) do
        self.triggerCombo:addOption(t.label)
    end
    self.triggerCombo.selected = 1
    self.triggerCombo.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    self:addChild(self.triggerCombo)

    self.chanceEntry = ISTextEntryBox:new("30", leftX + 90 + 220 + UI_BORDER_SPACING, formY, 60, BUTTON_HGT)
    self.chanceEntry:initialise()
    self.chanceEntry:instantiate()
    self.chanceEntry:setOnlyNumbers(true)
    self.chanceEntry.tooltip = "Chance (0-100) this line is used when the trigger fires, instead of the default dialogue."
    self:addChild(self.chanceEntry)

    lbl = ISLabel:new(leftX + 90 + 220 + UI_BORDER_SPACING, formY - FONT_HGT_SMALL - 2, BUTTON_HGT, "Chance %", 0.7, 0.7, 0.7, 1, UIFont.Small, false)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)

    formY = formY + BUTTON_HGT + 8

    lbl = ISLabel:new(leftX, formY, BUTTON_HGT, "Text:", 1, 1, 1, 1, UIFont.Small, false)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)

    self.textEntry = ISTextEntryBox:new("", leftX + 90, formY, self.width - leftX - 90 - UI_BORDER_SPACING, BUTTON_HGT)
    self.textEntry:initialise()
    self.textEntry:instantiate()
    self:addChild(self.textEntry)

    formY = formY + BUTTON_HGT + 8

    self.addBtn = ISButton:new(leftX, formY, 160, BUTTON_HGT, "Add Dialogue", self, BanditDialogueMain.onClick)
    self.addBtn.internal = "ADD"
    self.addBtn:initialise()
    self.addBtn:instantiate()
    if BanditCompatibility.GetGameVersion() >= 42 then
        self.addBtn:enableAcceptColor()
    end
    self:addChild(self.addBtn)

    self.back = ISButton:new(self.width - 160 - UI_BORDER_SPACING, self.height - UI_BORDER_SPACING - BUTTON_HGT, 160, BUTTON_HGT, "Back", self, BanditDialogueMain.onClick)
    self.back.internal = "BACK"
    self.back:initialise()
    self.back:instantiate()
    self:addChild(self.back)
end

function BanditDialogueMain:drawListItem(y, item, alt)
    local a = 0.9
    if self.selected == item.index then
        self:drawRect(0, y, self:getWidth(), self.itemheight, 0.3, 0.7, 0.35, 0.15)
    end

    local data = item.item
    local trigLabel = triggerLabel(data.trigger)
    self:drawText(trigLabel .. "  (" .. tostring(data.chance) .. "%)", 6, y + 2, 0.9, 0.9, 0.2, a, self.font)
    self:drawText(tostring(data.text), 6, y + 2 + FONT_HGT_SMALL, 1, 1, 1, a, self.font)

    return y + self.itemheight
end

function BanditDialogueMain:refreshList()
    self.list:clear()
    BanditDialogueCustom.Load()
    local entries = BanditDialogueCustom.GetFromClan(self.cid)
    for id, data in pairs(entries) do
        local d = { id = id, trigger = data.general.trigger, text = data.general.text, chance = data.general.chance }
        self.list:addItem(data.general.text, d)
    end
end

function BanditDialogueMain:onRowSelected(item)
    if not item or not item.id then return end
    self.editingId = item.id

    for i, t in ipairs(TRIGGERS) do
        if t.key == item.trigger then
            self.triggerCombo.selected = i
        end
    end
    self.chanceEntry:setText(tostring(item.chance))
    self.textEntry:setText(item.text)
    self.addBtn:setTitle("Update Dialogue")
end

function BanditDialogueMain:clearForm()
    self.editingId = nil
    self.triggerCombo.selected = 1
    self.chanceEntry:setText("30")
    self.textEntry:setText("")
    self.addBtn:setTitle("Add Dialogue")
    self.list.selected = 0
end

function BanditDialogueMain:onClick(button)
    if button.internal == "ADD" then
        local text = sanitizeDialogueText(self.textEntry:getText())
        if text and text ~= "" then
            local trig = TRIGGERS[self.triggerCombo.selected].key
            local chance = tonumber(self.chanceEntry:getText()) or 30
            if chance < 0 then chance = 0 end
            if chance > 100 then chance = 100 end

            BanditDialogueCustom.Load()
            local id = self.editingId or getRandomUUID()
            local data = BanditDialogueCustom.Get(id)
            if not data then
                data = BanditDialogueCustom.Create(id, self.cid)
            end
            data.general.trigger = trig
            data.general.text = text
            data.general.chance = chance
            BanditDialogueCustom.Save()

            self:clearForm()
            self:refreshList()
        end
    elseif button.internal == "DELETE" then
        if self.list.selected and self.list.selected > 0 then
            local item = self.list.items[self.list.selected]
            if item and item.item and item.item.id then
                BanditDialogueCustom.Load()
                BanditDialogueCustom.Delete(item.item.id)
                BanditDialogueCustom.Save()
                self:clearForm()
                self:refreshList()
            end
        end
    elseif button.internal == "CLEAR" then
        self:clearForm()
    elseif button.internal == "BACK" then
        self:close()
        self:removeFromUIManager()
        if self.onBackCallback then
            self.onBackCallback()
        end
    end
end

function BanditDialogueMain:prerender()
    ISPanel.prerender(self)
    self:drawTextCentre("Custom Dialogue", self.width / 2, UI_BORDER_SPACING + 5, 1, 1, 1, 1, UIFont.Title)
end

function BanditDialogueMain:new(x, y, width, height, cid, onBackCallback)
    local o = {}
    x = getCore():getScreenWidth() / 2 - (width / 2)
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.9}
    o.width = width
    o.height = height
    o.moveWithMouse = true
    o.cid = cid
    o.onBackCallback = onBackCallback
    return o
end
