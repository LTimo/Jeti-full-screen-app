--[[
	---------------------------------------------------------
    RFID application reads Arduino + RC522 MIFARE tags from
	battery and stores information to logfile.
	
	This is minimized DC/DS-16 version, requires firmware
	4.20 or newer. 
	
	RC-Thoughts Jeti RFID-Sensor and RFID-Battery application
	is compatible with Revo Bump and does not disturb 
	Robbe BID usage (Onki's solution)
	
	Requires RFID-Sensor with firmware 1.7 or up
	
	Italian translation courtesy from Fabrizio Zaini
	---------------------------------------------------------
	RFID application is part of RC-Thoughts Jeti Tools.
	---------------------------------------------------------
	Released under MIT-license by Tero @ RC-Thoughts.com 2017
	---------------------------------------------------------
--]]
collectgarbage()
----------------------------------------------------------------------
-- Locals for the application
local rfidVersion, tCurRFID, tStrRFID = "1.0", 0, 0
local rfidId, rfidParam, rfidSens, mahId, mahParam, mahSens
local capaAlarm, capaAlarmTr, alarmVoice, vPlayed, tagID
local rfidTime, annGo, annSw, tagCapa, alarm1Tr
local tagValid, tSetAlm, percVal, annTime = 0, 0, "-", 0
local model
local tempSens, tempId, tempParam
local tempmax
local temp = 0
local sensorLa1list = { "..." }
local sensorId1list = { "..." }
local sensorPa1list = { "..." }
local trans8
----------------------------------------------------------------------
-- Read translations
local function setLanguage()
    local lng=system.getLocale()
    local file = io.readall("Apps/Lang/RCT-Rfid.jsn")
    local obj = json.decode(file)
    if(obj) then
        trans8 = obj[lng] or obj[obj.default]
    end
end
----------------------------------------------------------------------
-- Read available sensors for user to select
local function readSensors()
    local sensors = system.getSensors()
    local format = string.format
    local insert = table.insert
    for i, sensor in ipairs(sensors) do
        if (sensor.label ~= "") then
            insert(sensorLa1list, format("%s", sensor.label))
            insert(sensorId1list, format("%s", sensor.id))
            insert(sensorPa1list, format("%s", sensor.param))
        end
    end
end
----------------------------------------------------------------------
-- Draw the telemetry windows
local function printBattery()
    local lcd = lcd
    local drawText = lcd.drawText
    local getTextWidth = lcd.getTextWidth
    local bold = FONT_BOLD

    if (tagID == 0) then
        drawText(160 - (getTextWidth(bold, trans8.emptyTag)) / 2, 24, trans8.emptyTag, bold)
    elseif (mahId == 0) then
        drawText(160 - (getTextWidth(bold, trans8.noCurr)) / 2, 24, trans8.noCurr, bold)
    elseif (percVal ~= "-") then
        lcd.drawFilledRectangle(148, 48, 24, 7)	-- Top of Battery
        lcd.drawRectangle(134, 55, 52, 101)
        local chgY = (156-percVal)
        local chgH = (percVal)
        lcd.drawFilledRectangle(135, chgY, 50, chgH)
        drawText(160 - (getTextWidth(FONT_BIG, string.format("%.1f%%", percVal))) / 2, 10, string.format("%.1f%%", percVal), FONT_BIG)
    else
        drawText((150 - getTextWidth(bold, trans8.noPack)) / 2, 24, trans8.noPack, bold)
    end
    
    -- draw Modellname 
        lcd.drawText(3,130, model, FONT_BIG)
        
    -- right bottom corner
    -- draw fixed Text
		lcd.drawText(245, 113, "IMax", FONT_MINI)
		lcd.drawText(245, 125, "UMin", FONT_MINI)
		lcd.drawText(245, 137, "T1Max", FONT_MINI)
		lcd.drawText(245, 149, "T2Max", FONT_MINI)
		
        lcd.drawText(307,113,"A",FONT_MINI)
        lcd.drawText(307,125,"A",FONT_MINI)
        lcd.drawText(302,137,"°C",FONT_MINI)
        lcd.drawText(302,149,"°C",FONT_MINI)

		-- draw Max Values  
        --lcd.drawText(300 - lcd.getTextWidth(FONT_MINI, string.format("%.1f",val1)),113, string.format("%.1f",val1),FONT_MINI)
       -- lcd.drawText(300 - lcd.getTextWidth(FONT_MINI, string.format("%.1f",val2)),125, string.format("%.1f",val2),FONT_MINI)
       -- lcd.drawText(300 - lcd.getTextWidth(FONT_MINI, string.format("%.1f",val2)),137, string.format("%.1f",Value),FONT_MINI)
       -- lcd.drawText(300 - lcd.getTextWidth(FONT_MINI, string.format("%.1f",val3)),149, string.format("%.1f",val3),FONT_MINI)

        -- draw "graph"
      

        lcd.drawText(200,149,"TelMax:",FONT_MINI)
        
        
    	-- draw fixed Text
		lcd.drawText(200, 2, "Teplota1:", FONT_BOLD)
		lcd.drawText(200, 24, "Teplota2:", FONT_BOLD)
    
   
    
		
		-- draw Values
    lcd.drawText(320 - lcd.getTextWidth(FONT_BIG, string.format("%.1f°C", temp1)), 1, string.format("%.1f°C", temp1), FONT_BIG)
		--lcd.drawText(255, 32, string.format("%02d.%02d.%02d", val2.day, val2.mon, val2.year), FONT_MINI)
    collectgarbage()
end
----------------------------------------------------------------------
-- Store settings when changed by user
--
local function capaAlarmChanged(value)
    local pSave = system.pSave

    capaAlarm = value
    pSave("capaAlarm", value)

    alarm1Tr = string.format("%.1f", capaAlarm)
    pSave("capaAlarmTr", capaAlarmTr)
    system.registerTelemetry(1, trans8.telLabel, 2, printBattery)
end

local function alarmVoiceChanged(value)
    alarmVoice = value
    system.pSave("alarmVoice", value)
end

--
local function sensorIDChanged(value)
    local pSave = system.pSave
    local format = string.format

    rfidSens = value
    pSave("rfidSens", value)
    rfidId = format("%s", sensorId1list[rfidSens])
    rfidParam = format("%s", sensorPa1list[rfidSens])
    if (rfidId == "...") then
        rfidId = 0
        rfidParam = 0
    end
    pSave("rfidId", rfidId)
    pSave("rfidParam", rfidParam)
end

local function sensorMahChanged(value)
    local pSave = system.pSave
    local format = string.format

    mahSens = value
    pSave("mahSens", value)
    mahId = format("%s", sensorId1list[mahSens])
    mahParam = format("%s", sensorPa1list[mahSens])
    if (mahId == "...") then
        mahId = 0
        mahParam = 0
    end
    pSave("mahId", mahId)
    pSave("mahParam", mahParam)
end

local function sensorTempChanged(value)
    local pSave = system.pSave
    local format = string.format

    tempSens = value
    pSave("tempsens", value)
    tempId = format("%s", sensorId1list[tempSens])
    tempParam = format("%s", sensorPa1list[tempSens])
    if (tempId == "...") then
        tempId = 0
        tempParam = 0
    end
    pSave("tempId", tempId)
    pSave("tempParam", tempParam)
end


local function annSwChanged(value)
    annSw = value
    system.pSave("annSw", value)
end
----------------------------------------------------------------------
-- Draw the main form (Application inteface)
local function initForm()
    local form = form
    local addRow = form.addRow
    local addLabel = form.addLabel

    form.setButton(1, ":tools")

    addRow(1)
    addLabel({ label = "---   RC-Thoughts Jeti Tools    ---", font = FONT_BIG })

    addRow(1)
    addLabel({ label = trans8.labelCommon, font = FONT_BOLD })
    
    addRow(2)
    addLabel({ label = "Temp1 Sensor", font = FONT_NORMAL})
    form.addSelectbox(sensorLa1list, tempSens, true, sensorTemp1Changed)
    
    addRow(2)
    addLabel({ label = trans8.sensorMah })
    form.addSelectbox(sensorLa1list, mahSens, true, sensorMahChanged)

    addRow(2)
    addLabel({ label = trans8.sensorID })
    form.addSelectbox(sensorLa1list, rfidSens, true, sensorIDChanged)
    
    addRow(1)
    addLabel({ label = trans8.labelAlarm, font = FONT_BOLD })

    addRow(2)
    addLabel({ label = trans8.AlmVal })
    form.addIntbox(capaAlarm, 0, 100, 0, 0, 1, capaAlarmChanged)

    addRow(2)
    addLabel({ label = trans8.selAudio })
    form.addAudioFilebox(alarmVoice, alarmVoiceChanged)

    addRow(2)
    addLabel({ label = trans8.annSw, width = 220 })
    form.addInputbox(annSw, true, annSwChanged)

    addRow(1)
    addLabel({ label = "Powered by RC-Thoughts.com - v." .. rfidVersion .. " ", font = FONT_MINI, alignRight = true })

    form.setFocusedRow(1)
end

----------------------------------------------------------------------
local function loop()
    local system = system
    
    
    
    -- RFID reading and battery-definition
    if (rfidSens > 1) then
        rfidTime = system.getTime()
        tagID = system.getSensorByID(rfidId, 1)
        tagCapa = system.getSensorByID(rfidId, 2)
        annGo = system.getInputsVal(annSw)
        if (tagID and tagID.valid) then
            tagValid = 1
            tagID = tagID.value
            tagCapa = tagCapa.value
        else
            percVal = "-"
            tagValid = 0
        end
        -- Capacity percentage calculation and voice alert config
        if (mahSens > 1) then
            local mahCapa = system.getSensorByID(mahId, mahParam)
            if (mahCapa and mahCapa.valid) then
                mahCapa = mahCapa.value
                if (tagValid == 1) then
                    if (tSetAlm == 0) then
                        tCurRFID = rfidTime
                        tStrRFID = rfidTime + 5
                        tSetAlm = 1
                    else
                        tCurRFID = system.getTime()
                    end
                    local resRFID = (((tagCapa - mahCapa) * 100) / tagCapa)
                    if (resRFID < 0) then
                        resRFID = 0
                    else
                        if (resRFID > 100) then
                            resRFID = 100
                        end
                    end
                    percVal = string.format("%.1f", resRFID)
                    if (alarm1Tr == 0) then
                        vPlayed = 0
                        tStrRFID = 0
                    else
                        if (resRFID <= capaAlarm) then
                            if (tStrRFID <= tCurRFID and tSetAlm == 1) then
                                if (vPlayed == 0 or vPlayed == nil and alarmVoice ~= "...") then
                                    system.playFile(alarmVoice, AUDIO_QUEUE)
                                    vPlayed = 1
                                end
                            end
                        else
                            vPlayed = 0
                        end
                    end
                else
                    percVal = "-"
                    vPlayed = 0
                    tSetAlm = 0
                end
            end
        end
    else
        rfidTime = 0
    end    
    if(annGo == 1 and resRFID >= 0 and resRFID <= 100 and annTime < rfidTime) then
        system.playNumber(percVal, 0, "%", trans8.annCap)
        annTime = rfidTime + 10
    end
    
    temp1 = system.getSensorByID(temp1, 4)
    collectgarbage()
end

----------------------------------------------------------------------
-- Application initialization
local function init()
    local pLoad = system.pLoad
    rfidId = pLoad("rfidId", 0)
    rfidParam = pLoad("rfidParam", 0)
    rfidSens = pLoad("rfidSens", 0)
    mahId = pLoad("mahId", 0)
    mahParam = pLoad("mahParam", 0)
    tempId = pLoad("tempId", 0)
    tempParam = pLoad("tempParam", 0)
    tempSens = pLoad("tempSens", 0)
    mahSens = pLoad("mahSens", 0)
    capaAlarm = pLoad("capaAlarm", 0)
    capaAlarmTr = pLoad("capaAlarmTr", 1)
    alarmVoice = pLoad("alarmVoice", "...")
    annSw = pLoad("annSw")
    readSensors()
  
    model = system.getProperty("Model")
    system.registerForm(1, MENU_APPS, trans8.appName, initForm, keyPressed)
    system.registerTelemetry(1, model, 4, printBattery)
    collectgarbage()
end

----------------------------------------------------------------------
setLanguage()
collectgarbage()
return { init = init, loop = loop, author = "Timotej Labsky", version = rfidVersion, name = "Slick Telemetry"}