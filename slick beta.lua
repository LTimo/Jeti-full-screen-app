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
local rfidVersion, tCurRFID, tStrRFID = "1", 0, 0
local rfidId, rfidParam, rfidSens, mahId, mahParam, mahSens
local tempId, tempParam, tempSens
local tempVal, tempMax = 0, 0

local temppId, temppParam, temppSens
local temppVal, temppMax = 0, 0

local UId, UParam, USens
local UVal, UMin = 0, 999

local fTimeId, fTimeParam, fTimeSens, fTime

local resetSw, resetGo

local mahCapa, cycle

local time = 0
local aniX, aniY = 0, 0

local tagID = 0
local capaAlarm, capaAlarmTr, alarmVoice, vPlayed
local rfidTime, annGo, annSw, tagCapa, alarm1Tr
local tagValid, tSetAlm, percVal, annTime = 0, 0, "-", 0
local sensorLa1list = { "..." }
local sensorId1list = { "..." }
local sensorPa1list = { "..." }
local trans8
local model
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

local function printEverything()
   
    -- right bottom corner
    -- draw fixed Text
		lcd.drawText(242, 113, "IMax", FONT_MINI)
		lcd.drawText(242, 125, "UMin", FONT_MINI)
		lcd.drawText(242, 137, "T1Max", FONT_MINI)
		lcd.drawText(242, 149, "T2Max", FONT_MINI)
		
        lcd.drawText(307,113,"A",FONT_MINI)
        lcd.drawText(307,125,"V",FONT_MINI)
        lcd.drawText(302,137,"°C",FONT_MINI)
        lcd.drawText(302,149,"°C",FONT_MINI)
    
    -- draw Max Values  
        --lcd.drawText(300 - lcd.getTextWidth(FONT_MINI, string.format("%.1f",val1)),113, string.format("%.1f",val1),FONT_MINI)
        lcd.drawText(300 - lcd.getTextWidth(FONT_MINI, string.format("%.1f",UMin)),125, string.format("%.1f",UMin),FONT_MINI)
        lcd.drawText(300 - lcd.getTextWidth(FONT_MINI, string.format("%.1f",tempMax)),137, string.format("%.1f",tempMax),FONT_MINI)
        lcd.drawText(300 - lcd.getTextWidth(FONT_MINI, string.format("%.1f",temppMax)),149, string.format("%.1f",temppMax),FONT_MINI)

        -- draw "graph"
        lcd.drawLine(200, 140, 200, 120)
        lcd.drawLine(200, 140, 240, 140)
        lcd.drawLine(199, 121, 201, 121)
        lcd.drawLine(239, 139, 239, 141)
        lcd.drawLine(200 ,140, 217, 126)
        lcd.drawLine(200 ,139, 217, 125)
        lcd.drawLine(217, 126, 226, 138)
        lcd.drawLine(217 ,125, 226, 137)
        lcd.drawLine(226, 138, 240, 119)
        lcd.drawLine(226, 137, 240, 118)
        lcd.drawLine(223, 138, 223, 142)
        
        
    -- draw Battery Status window
      lcd.drawText(228, 2, "Battery Status",FONT_MINI)
      lcd.drawText(318 - (lcd.getTextWidth(FONT_MINI,"mAh")), 12 + (lcd.getTextHeight(FONT_BIG, "A")), "mAh", FONT_MINI)
      lcd.drawNumber(310 - (lcd.getTextWidth(FONT_MINI,"mAh")) - (lcd.getTextWidth(FONT_BIG, string.format("%.0f", mahCapa))),12, mahCapa, FONT_MAXI)
      
      lcd.drawText(212, 13 + (lcd.getTextHeight(FONT_MAXI, "A")), "Teplota:", FONT_MINI)
      lcd.drawText(213 + lcd.getTextWidth(FONT_MINI,"Teplota:"), 8 + (lcd.getTextHeight(FONT_MAXI, "A")), string.format("%.1f°C", temppVal), FONT_BIG)
      
      lcd.drawText(212, 11 + (lcd.getTextHeight(FONT_MAXI, "A")) + lcd.getTextHeight(FONT_BIG,"a"),"Učlánok:", FONT_MINI)
      lcd.drawText(213 + lcd.getTextWidth(FONT_MINI,"Učlánok:"),6 + (lcd.getTextHeight(FONT_MAXI, "A")) + lcd.getTextHeight(FONT_BIG,"a"), string.format("%.2fV", UVal / 6), FONT_BIG)
      
      lcd.drawText(212, 8 + (lcd.getTextHeight(FONT_MAXI, "A")) * 2, "Napätie:", FONT_MINI)
      lcd.drawText(214 + lcd.getTextWidth(FONT_MINI,"Napätie:"), 9 + (lcd.getTextHeight(FONT_MAXI, "A")) * 2, string.format("%.1fV", UVal), FONT_MINI)
      
      lcd.drawText(212, 8 + (lcd.getTextHeight(FONT_MAXI, "A")) * 2 + (lcd.getTextHeight(FONT_MINI,"a")), "Cyklov:", FONT_MINI)
      lcd.drawNumber(214 + lcd.getTextWidth(FONT_MINI,"Článok:"), 8 + (lcd.getTextHeight(FONT_MAXI, "A")) * 2 + (lcd.getTextHeight(FONT_MINI, "A")), cycle, FONT_MINI)
      
      
    -- Flight time
      lcd.drawNumber(0,0,fTime,FONT_MAXI)
    
    
    
    -- draw Lines
    lcd.drawFilledRectangle(4, 47, 104, 2)     --lo
		lcd.drawFilledRectangle(4, 111, 116, 2)    --lu
		--lcd.drawFilledRectangle(212, 85, 104, 2)   --ro
		lcd.drawFilledRectangle(200, 111, 116, 2)  --ru
    
    collectgarbage()
    end
  
----------------------------------------------------------------------
-- Draw the telemetry windows
local function printBattery()
    local lcd = lcd
    local drawText = lcd.drawText
    local getTextWidth = lcd.getTextWidth
    local bold = FONT_BOLD
    local timeani = 0
   
    
    
    if (tagID == 0) then
        drawText((150 - getTextWidth(bold, trans8.emptyTag)) / 2, 24, trans8.emptyTag, bold)
    elseif (mahId == 0) then
        drawText((150 - getTextWidth(bold, trans8.noCurr)) / 2, 24, trans8.noCurr, bold)
    elseif (percVal ~= "-") then
        lcd.drawFilledRectangle(148, 48, 24, 7)	-- Top of Battery
        lcd.drawRectangle(134, 55, 52, 101)
        local chgY = (156-percVal)
        local chgH = (percVal)
        lcd.drawFilledRectangle(135, chgY, 50, chgH)
        drawText(160 - (getTextWidth(FONT_BIG, string.format("%.1f%%", percVal))) / 2, 10, string.format("%.1f%%", percVal), FONT_BIG)
        printEverything()
       
    else
        if (time == 0) then 
          time = system.getTime()
        end
        
        timeani = system.getTime()     
        
        if ((system.getTime() - time) > 1) then
          aniX = aniX + 10
          aniY = aniY + 7
          if (aniX == 200) then
              aniX = 0
              aniY = 0
            end
          time = system.getTime()
        end
        
        drawText(aniX ,aniY , model, FONT_BIG)
    end
   
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

local function sensorTempChanged(value)
    local pSave = system.pSave
    local format = string.format

    tempSens = value
    pSave("tempSens", value)
    tempId = format("%s", sensorId1list[tempSens])
    tempParam = format("%s", sensorPa1list[tempSens])
    if (tempId == "...") then
        tempId = 0
        tempParam = 0
    end
    pSave("tempId", tempId)
    pSave("tempParam", tempParam)
end

local function sensorTemppChanged(value)
    local pSave = system.pSave
    local format = string.format

    temppSens = value
    pSave("temppSens", value)
    temppId = format("%s", sensorId1list[temppSens])
    temppParam = format("%s", sensorPa1list[temppSens])
    if (temppId == "...") then
        temppId = 0
        temppParam = 0
    end
    pSave("temppId", temppId)
    pSave("temppParam", temppParam)
end

local function sensorfTimeChanged(value)
    local pSave = system.pSave
    local format = string.format

    fTimeSens = value
    pSave("fTimeSens", value)
    fTimeId = format("%s", sensorId1list[fTimeSens])
    fTimeParam = format("%s", sensorPa1list[fTimeSens])
    if (fTimeId == "...") then
        fTimeId = 0
        fTimeParam = 0
    end
    pSave("fTimeId", fTimeId)
    pSave("fTimeParam", fTimeParam)
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

local function sensorUChanged(value)
    local pSave = system.pSave
    local format = string.format

    USens = value
    pSave("USens", value)
    UId = format("%s", sensorId1list[USens])
    UParam = format("%s", sensorPa1list[USens])
    if (UId == "...") then
        UId = 0
        UParam = 0
    end
    pSave("UId", UId)
    pSave("UParam", UParam)
end

local function annSwChanged(value)
    annSw = value
    system.pSave("annSw", value)
end

local function resetSwChanged(value)
    resetSw = value
    system.pSave("resetSw", value)
end
----------------------------------------------------------------------
-- Draw the main form (Application inteface)
local function initForm()
    local form = form
    local addRow = form.addRow
    local addLabel = form.addLabel

    form.setButton(1, ":tools")

    addRow(1)
    addLabel({ label = "---   Slick telemetry app    ---", font = FONT_BIG })

    addRow(1)
    addLabel({ label = trans8.labelCommon, font = FONT_BOLD })

    addRow(2)
    addLabel({ label = trans8.sensorID })
    form.addSelectbox(sensorLa1list, rfidSens, true, sensorIDChanged)

    addRow(2)
    addLabel({ label = trans8.sensorMah })
    form.addSelectbox(sensorLa1list, mahSens, true, sensorMahChanged)
    
    addRow(2)
    addLabel({ label = "Temp 1 Senzor" })
    form.addSelectbox(sensorLa1list, tempSens, true, sensorTempChanged)
    
    addRow(2)
    addLabel({ label = "Temp 2 Senzor" })
    form.addSelectbox(sensorLa1list, temppSens, true, sensorTemppChanged)
    
    addRow(2)
    addLabel({ label = "Flight time" })
    form.addSelectbox(sensorLa1list, fTimeSens, true, sensorfTimeChanged)
    
    addRow(2)
    addLabel({ label = "Napätie senzor" })
    form.addSelectbox(sensorLa1list, USens, true, sensorUChanged)


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
    
    addRow(2)
    addLabel({ label = "Reset switch", width = 220 })
    form.addInputbox(resetSw, true, resetSwChanged)

    addRow(1)
    addLabel({ label = "Powered by RC-Thoughts.com - v." .. rfidVersion .. " ", font = FONT_MINI, alignRight = true })

    form.setFocusedRow(1)
end

----------------------------------------------------------------------
local function loop()
    local system = system
    
    local sense = system.getSensorByID(tempId, tempParam)
    if(sense and sense.valid) then
      tempVal = sense.value
      if (tempVal > tempMax) then
        tempMax = tempVal
        end
    end
    
    sense = system.getSensorByID(temppId, temppParam)
    if(sense and sense.valid) then
      temppVal = sense.value
      if (temppVal > temppMax) then
        temppMax = temppVal
        end
    end
    
    sense = system.getSensorByID(fTimeId, 3)
    if(sense and sense.valid) then
      fTime = sense.value
    end
    
    sense = system.getSensorByID(UId, UParam)
    if(sense and sense.valid) then
      UVal = sense.value
      if (UVal < UMin) then
        UMin = UVal
        end
    end
    
    resetGo = system.getInputsVal(resetSw)
    
    if (resetGo ~= nil and resetGo > 0) then 
      tempMax = 0
      temppMax = 0
      UMin = 999
    end
  
  
    -- RFID reading and battery-definition
    if (rfidSens > 1) then
        rfidTime = system.getTime()
        tagID = system.getSensorByID(rfidId, 1)
        tagCapa = system.getSensorByID(rfidId, 2)
        cycle = system.getSensorByID(rfidId, 3)
        cycle = cycle.value
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
            mahCapa = system.getSensorByID(mahId, mahParam)
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
    collectgarbage()
end

----------------------------------------------------------------------
-- Application initialization
local function init()
    local pLoad = system.pLoad
    rfidId = pLoad("rfidId", 0)
    tempId = pLoad("tempId", 0)
    temppId = pLoad("temppId", 0)
    fTimeId = pLoad("fTimeId", 0)
    UId = pLoad("UId", 0)
    
    rfidParam = pLoad("rfidParam", 0)
    tempParam = pLoad("tempParam", 0)
    temppParam = pLoad("temppParam", 0)
    fTimeParam = pLoad("fTimeParam", 0)
    UParam = pLoad("UParam", 0)
    
    rfidSens = pLoad("rfidSens", 0)
    tempSens = pLoad("tempSens", 0)
    temppSens = pLoad("temppSens", 0)
    fTimeSens = pLoad("fTimeSens", 0)
    USens = pLoad("USens", 0)
    
    mahId = pLoad("mahId", 0)
    mahParam = pLoad("mahParam", 0)
    mahSens = pLoad("mahSens", 0)
    capaAlarm = pLoad("capaAlarm", 0)
    capaAlarmTr = pLoad("capaAlarmTr", 1)
    alarmVoice = pLoad("alarmVoice", "...")
    annSw = pLoad("annSw")
    resetSw = pLoad("resetSw")
    readSensors()
    model = system.getProperty("Model")
    system.registerForm(1, MENU_APPS, trans8.appName, initForm, keyPressed)
    system.registerTelemetry(1, model, 4, printBattery)
    collectgarbage()
end

----------------------------------------------------------------------
setLanguage()
collectgarbage()
return { init = init, loop = loop, author = "Timotej Labsky", version = rfidVersion, name = "Slick telemetry" }