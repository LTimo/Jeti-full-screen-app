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

local IId, IParam, ISens
local IVal, IMax = 0, 0

local PMax = 0

local resetSw, resetGo

local mahCapa, cycle

local timeSw

local time, lastTime, newTime = 0, 0, 0
local std, min, sec = 0, 0, 0

local timel= 0
local aniX, aniY = 0, 0

local battID = 0

local capaAlarm, capaAlarmTr, alarmVoice, vPlayed, tagID
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
--test
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
        lcd.drawText(300 - lcd.getTextWidth(FONT_MINI, string.format("%.1f",IVal)),113, string.format("%.1f",IVal),FONT_MINI)
        lcd.drawText(300 - lcd.getTextWidth(FONT_MINI, string.format("%.2f",UMin/6)),125, string.format("%.2f",UMin/6),FONT_MINI)
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
        
        --Flight time
        lcd.drawText(lcd.getTextWidth(FONT_MINI,"Čas Letu")/2, 2, "Čas Letu", FONT_MINI)
        lcd.drawText((lcd.getTextWidth(FONT_MAXI, string.format("%02d:%02d", min, sec)) / 4), 13, string.format("%02d:%02d", min, sec), FONT_MAXI)
        
    -- draw Battery Status window
      lcd.drawText(228, 2, "Battery Status",FONT_MINI)
      lcd.drawText(318 - (lcd.getTextWidth(FONT_MINI,"mAh")), 12 + (lcd.getTextHeight(FONT_BIG, "A")), "mAh", FONT_MINI)
      lcd.drawNumber(310 - (lcd.getTextWidth(FONT_MINI,"mAh")) - (lcd.getTextWidth(FONT_BIG, string.format("%.0f", mahCapa))),12, mahCapa, FONT_MAXI)
      
      lcd.drawText(200, 13 + (lcd.getTextHeight(FONT_MAXI, "A")), "Teplota:", FONT_MINI)
      lcd.drawText(201 + lcd.getTextWidth(FONT_MINI,"Teplota:"), 8 + (lcd.getTextHeight(FONT_MAXI, "A")), string.format("%.1f°C", temppVal), FONT_BIG)
      
      lcd.drawText(200, 11 + (lcd.getTextHeight(FONT_MAXI, "A")) + lcd.getTextHeight(FONT_BIG,"a"),"Učlánok:", FONT_MINI)
      lcd.drawText(201 + lcd.getTextWidth(FONT_MINI,"Učlánok:"),6 + (lcd.getTextHeight(FONT_MAXI, "A")) + lcd.getTextHeight(FONT_BIG,"a"), string.format("%.2fV", UVal / 6), FONT_BIG)
      
      lcd.drawText(200, 8 + (lcd.getTextHeight(FONT_MAXI, "A")) * 2, "Napätie:", FONT_MINI)
      lcd.drawText(201 + lcd.getTextWidth(FONT_MINI,"Napätie:"), 9 + (lcd.getTextHeight(FONT_MAXI, "A")) * 2, string.format("%.1fV", UVal), FONT_MINI)
      
      lcd.drawText(200, 8 + (lcd.getTextHeight(FONT_MAXI, "A")) * 2 + (lcd.getTextHeight(FONT_MINI,"a")), "Cyklov:", FONT_MINI)
      lcd.drawNumber(201 + lcd.getTextWidth(FONT_MINI,"Článok:"), 8 + (lcd.getTextHeight(FONT_MAXI, "A")) * 2 + (lcd.getTextHeight(FONT_MINI, "A")), cycle, FONT_MINI)
      
      
    -- ESC status
      lcd.drawText(lcd.getTextWidth(FONT_MINI,"ESC Status")/2, 50, "ESC Status", FONT_MINI)
      lcd.drawText(105 - lcd.getTextWidth(FONT_MAXI,string.format("%.1fA", IVal)), 50 + lcd.getTextHeight(FONT_MINI,"ESC Status"), string.format("%.1fA", IVal), FONT_MAXI)
      
      lcd.drawText(4,56 + lcd.getTextHeight(FONT_MINI,"E") + lcd.getTextHeight(FONT_MAXI,"A"),"Teplota:", FONT_MINI)
      lcd.drawText(6 + lcd.getTextWidth(FONT_MINI,"Teplota:"),50 + lcd.getTextHeight(FONT_MINI,"E") + lcd.getTextHeight(FONT_MAXI,"A"), string.format("%.1f°C", tempVal), FONT_BIG)
      
      lcd.drawText(4,70 + lcd.getTextHeight(FONT_MINI,"E") + lcd.getTextHeight(FONT_MAXI,"A"),"Power:",FONT_MINI)
      lcd.drawText(6 + lcd.getTextWidth(FONT_MINI,"Power:"), 70 + lcd.getTextHeight(FONT_MINI,"E") + lcd.getTextHeight(FONT_MAXI,"A"), string.format("%.1fW", UVal*IVal), FONT_MINI)
      
      lcd.drawText(4, 70 + lcd.getTextHeight(FONT_MINI,"E") * 2 + lcd.getTextHeight(FONT_MAXI,"A"), "Max Pw:",FONT_MINI)
      lcd.drawText(4 + lcd.getTextWidth(FONT_MINI,"Max Pw:"), 70 + lcd.getTextHeight(FONT_MINI,"E") * 2 + lcd.getTextHeight(FONT_MAXI,"A"), string.format("%.2fkW", PMax/100), FONT_MINI)
    
    
    
    -- draw Lines
    lcd.drawFilledRectangle(4, 47, 104, 2)     --lo
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

    if ((tagID == 0) or (mahId == 0) or (percVal == "-")) then
       if (timel == 0) then 
          timel = system.getTime()
        end
        
        timeani = system.getTime()     
        
        if ((system.getTime() - timel) > 1) then
          aniX = aniX + 10
          aniY = aniY + 12
          if (aniX == 110) then
              aniX = 0
              aniY = 0
            end
          timel = system.getTime()
        end
        
        drawText(aniX ,aniY , model, FONT_MAXI)
    elseif (percVal ~= "-") then
      if (percVal == 100)then
        lcd.drawFilledRectangle(148, 48, 24, 8)	-- Top of Battery
      else
        lcd.drawRectangle(148, 48, 24, 8)	-- Top of Battery
      end
        lcd.drawRectangle(134, 55, 52, 101)
        local chgY = (156-percVal)
        local chgH = (percVal)
        lcd.drawFilledRectangle(135, chgY, 50, chgH)
        drawText(160 - (getTextWidth(FONT_BIG, string.format("%.1f%%", percVal))) / 2, 10, string.format("%.1f%%", percVal), FONT_BIG)
        printEverything()
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

local function sensorIChanged(value)
    local pSave = system.pSave
    local format = string.format

    ISens = value
    pSave("ISens", value)
    IId = format("%s", sensorId1list[ISens])
    IParam = format("%s", sensorPa1list[ISens])
    if (IId == "...") then
        IId = 0
        IParam = 0
    end
    pSave("IId", IId)
    pSave("IParam", IParam)
end

local function annSwChanged(value)
    annSw = value
    system.pSave("annSw", value)
end

local function resetSwChanged(value)
    resetSw = value
    system.pSave("resetSw", value)
end

local function timeSwChanged(value)
    timeSw = value
    system.pSave("timeSw", value)
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
    addLabel({ label = "Napätie senzor" })
    form.addSelectbox(sensorLa1list, USens, true, sensorUChanged)

    addRow(2)
    addLabel({ label = "Prúd senzor" })
    form.addSelectbox(sensorLa1list, ISens, true, sensorIChanged)

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
    
    addRow(2)
    addLabel({ label = "Time switch", width = 220 })
    form.addInputbox(timeSw, true, timeSwChanged)

    addRow(1)
    addLabel({ label = "Based on RC-Thoughts.com v" .. rfidVersion .. " ", font = FONT_MINI, alignRight = true })

    form.setFocusedRow(1)
end

-- Fligt time
local function FlightTime()
	newTime = system.getTimeCounter()
	ltimeSw = system.getInputsVal(timeSw)
	--resetSw = system.getInputsVal(resSw)

	if (ltimeSw == 0 and resetGo == 1) then time = 0 end
	
	if (ltimeSw > 0.05) then		
		if newTime > (lastTime + 1000) then  -- nach einer sec.
			lastTime = newTime
			time = time + 1
		end
	end	
	std = math.floor(time / 3600)
	min = math.floor(time / 60) - std * 60
	sec = time - min * 60
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
    
    sense = system.getSensorByID(UId, UParam)
    if(sense and sense.valid) then
      UVal = sense.value
      if (UVal < UMin) then
        UMin = UVal
        end
    end
    
     sense = system.getSensorByID(IId, IParam)
    if(sense and sense.valid) then
      IVal = sense.value
      if (IVal > IMax) then
        IMax = IVal
        end
    end
    
    if (IVal*UVal > PMax) then 
      PMax = IVal * UVal
    end
    
    
    resetGo = system.getInputsVal(resetSw)
    
    FlightTime()
    
    
    if (resetGo ~= nil and resetGo > 0) then 
      tempMax = 0
      temppMax = 0
      UMin = 999
      PMax = 0
      battID = 0
    end
  
  
    -- RFID reading and battery-definition
      if (rfidSens > 1) then
        --if (battID == 0)then
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
          --[[if (tagID > 0) then 
            battID = tagID
          end]]--
        --end   
              
        
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
    UId = pLoad("UId", 0)
    IId = pLoad("IId", 0)
    
    rfidParam = pLoad("rfidParam", 0)
    tempParam = pLoad("tempParam", 0)
    temppParam = pLoad("temppParam", 0)
    UParam = pLoad("UParam", 0)
    IParam = pLoad("IParam", 0)
    
    rfidSens = pLoad("rfidSens", 0)
    tempSens = pLoad("tempSens", 0)
    temppSens = pLoad("temppSens", 0)
    USens = pLoad("USens", 0)
    ISens = pLoad("ISens", 0)
    
    mahId = pLoad("mahId", 0)
    mahParam = pLoad("mahParam", 0)
    mahSens = pLoad("mahSens", 0)
    capaAlarm = pLoad("capaAlarm", 0)
    capaAlarmTr = pLoad("capaAlarmTr", 1)
    alarmVoice = pLoad("alarmVoice", "...")
    annSw = pLoad("annSw")
    resetSw = pLoad("resetSw")
    timeSw = pLoad("timeSw")
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