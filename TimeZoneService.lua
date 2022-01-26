--[[
    TimeZoneService: A way to get server or client timezones while also comparing their viability with each other.
    ...
    By: Eezby

    FUNCTIONS:
        TimeZoneService:GetServerInfo()
         Get details about the server's location and timezone data. See notes in the function for editing data received.

        TimeZoneService:GetClientTimeZone(client: Instance<Player>)
         Invoke the client for their GMT time offset and receive information about their timezone.

        TimeZoneService:GetTimeZoneInfo(zone: string)
         Pass in a valid timezone from the TimeZone table below (ex. EST, PST, GMT) and receive information about it's full name and offset.

        TimeZoneService:GetTimeZoneByOffset(offset: number, inSeconds: boolean)
         Pass in an offset and get back the corresponding timezone. You can specify whether the offset is in seconds or hours using the optional
         "inSeconds" boolean value.

        TimeZoneService:GetTimeZoneByContinent(continent: string)
         Pass in a valid continent code (NA, SA, AS, AF, EU, AU) and receive a list of timezones within that continent.

        TimeZoneService:GetTimeZoneStatus(zone1: string, zone2: string)
         Pass in two valid timezones from the TimeZone table below and receive information about how viable their are together. 
         For example EST -> EST is "Amazing", while EST -> GMT is "Terrible". This can be used for telling players how their ping might fair in a
         certain server region.

        TimeZoneService:SortBestTimeZones(zone: string)
         Pass in a valid timezone from the TimeZone table below and receive an ordered list of every timezone from best to worse in terms of distance
         and "group".


    NOTES:
        I assigned groups to each timezone as a timezone alone is not a viable way to determine whether a player's ping will be good or not in that region.
        For example, EST and PRT are only one hour apart, yet for most on the EST zone CTL, MNT, and even PST are better options. Feel free to change the
        weight or groups as you see fit.
]]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local IsServer = RunService:IsServer()

local GROUP_WEIGHT = 3.25

-- ALL VALID TIMEZONES LISTED HERE --
local TimeZones = {
	["GMT"] = {
		name = "Greenwich Mean Time",
		gmtOffset = 0,
		group = "EU",
        continent = "EU",
	},
	
	["ECT"] = {
		name = "European Central Time",
		gmtOffset = 1,
		group = "EU",
        continent = "EU",
	},
	
	["EET"] = {
		name = "Eastern European Time",
		gmtOffset = 2,
		group = "EU",
        continent = "EU",
	},
	
	["EAT"] = {
		name = "Eastern African Time",
		gmtOffset = 3,
		group = "AF",
        continent = "AF",
	},
	
	["MET"] = {
		name = "Middle East Time",
		gmtOffset = 3.5,
		group = "AF",
        continent = "AF",
	},
	
	["NET"] = {
		name = "Near East Time",
		gmtOffset = 4,
		group = "AF",
        continent = "AF",
	},
	
	["PLT"] = {
		name = "Pakistan Lahore Time",
		gmtOffset = 5,
		group = "AS",
        continent = "AS",
	},

	["IST"] = {
		name = "India Standard Time",
		gmtOffset = 5.5,
		group = "AS",
        continent = "AS",
	},
	
	["BST"] = {
		name = "Bangladesh Standard Time",
		gmtOffset = 6,
		group = "AS",
        continent = "AS",
	},
	
	["VST"] = {
		name = "Vietnam Standard Time",
		gmtOffset = 7,
		group = "CAS",
        continent = "AS",
	},
	
	["CTT"] = {
		name = "China Taiwan Time",
		gmtOffset = 8,
		group = "CAS",
        continent = "AS",
	},
	
	["JST"] = {
		name = "Japan Standard Time",
		gmtOffset = 9,
		group = "EAS",
        continent = "AS",
	},
	
	["ACT"] = {
		name = "Australia Central Time",
		gmtOffset = 9.5,
		group = "AU",
        continent = "AU",
	},
	
	["ACDT"] = {
		name = "Australian Central Daylight Savings Time",
		gmtOffset = 10.5,
		group = "AU",
        continent = "AU",
	},
	
	["AET"] = {
		name = "Australia Eastern Time",
		gmtOffset = 10,
		group = "AU",
        continent = "AU",
	},
	
	["SST"] = {
		name = "Solomon Standard Time",
		gmtOffset = 11,
		group = "AU",
        continent = "AU",
	},
	
	["NST"] = {
		name = "New Zealand Standard Time",
		gmtOffset = 12,
		group = "AU",
        continent = "AU",
	},
	
	["MIT"] = {
		name = "Midway Islands Time",
		gmtOffset = -11,
		group = "US",
        continent = "NA",
	},
	
	["HST"] = {
		name = "Hawaii Standard Time",
		gmtOffset = -10,
		group = "US",
        continent = "NA",
	},
	
	["AST"] = {
		name = "Alaska Standard Time",
		gmtOffset = -9,
		group = "US",
        continent = "NA",
	},
	
	["PST"] = {
		name = "Pacific Standard Time",
		gmtOffset = -8,
		group = "US",
        continent = "NA",
	},
	
	["MST"] = {
		name = "Mountain Standard Time",
		gmtOffset = -7,
		group = "US",
        continent = "NA",
	},
	
	["CST"] = {
		name = "Central Standard Time",
		gmtOffset = -6,
		group = "US",
        continent = "NA",
	},
	
	["EST"] = {
		name = "Eastern Standard Time",
		gmtOffset = -5,
		group = "US",
        continent = "NA",
	},
	
	["PRT"] = {
		name = "Puerto Rico and US Virgin Islands Time",
		gmtOffset = -4,
		group = "PR",
        continent = "NA",
	},
	
	["CNT"] = {
		name = "Canada Newfoundland Time",
		gmtOffset = -3.5,
		group = "CA",
        continent = "NA",
	},
	
	["BET"] = {
		name = "Brazil Eastern Time",
		gmtOffset = -3,
		group = "BR",
        continent = "SA",
	},
	
	["CAT"] = {
		name = "Central African Time",
		gmtOffset = -1,
		group = "AF",
        continent = "AF",
	},
}

local Connection

if not IsServer then
	Connection = script:WaitForChild("Connection")
	
	Connection.OnClientInvoke = function(action)
		if action == "get-zone" then
            -- Server time is in UTC (GMT), so this should get the offset between GMT and the client's time rounded to the nearest 100th
			return math.floor((tick() - workspace:GetServerTimeNow()) / 100 + 0.5) * 100
		end
	end
else
	Connection = Instance.new("RemoteFunction")
	Connection.Name = "Connection"
	Connection.Parent = script
end

local TimeZoneService = {}

function TimeZoneService:GetServerInfo()
	assert(IsServer, "This function can only be run on the server, not the client")
	
	local ipResult

	local success, message = pcall(function()
		ipResult = HttpService:JSONDecode(HttpService:GetAsync("https://api4.my-ip.io/ip.json"))
	end)

	if success and ipResult.ip then
		local locationResult
		local success, message = pcall(function()
            -- GOTO: https://ip-api.com/docs/api:json if you would like to change the fields received from the API
			locationResult = HttpService:JSONDecode(HttpService:GetAsync("http://ip-api.com/json/"..ipResult.ip.."?fields=37273887"))
		end)

		if success and locationResult then
			local returnInfo = {
				gmtOffset = locationResult.offset / 60^2,

				continent = locationResult.continent,
				continentCode = locationResult.continentCode,

				country = locationResult.country,
				countryCode = locationResult.countryCode,

				region = locationResult.region,
				regionName = locationResult.regionName,

				city = locationResult.city,
				district = locationResult.district,

				timezone = locationResult.timezone
			}

			return returnInfo
		else
			warn("fatal error fetching server geo location. error: "..message)
		end
	else
		warn("fatal error fetching server ip. error: "..message)
	end
end

function TimeZoneService:GetClientTimeZone(client)
	assert(IsServer, "This function can only be run on the server, not the client")
	
	local gtmOffsetInSeconds
	local success, message = pcall(function()
		gtmOffsetInSeconds = Connection:InvokeClient(client, "get-zone")
	end)
	
	if success and gtmOffsetInSeconds then
		return self:GetByTimeZoneOffset(gtmOffsetInSeconds, true)
	end
end

function TimeZoneService:GetTimeZoneInfo(zone)
    assert(TimeZones[zone] ~= nil, "That is not a valid timezone")
	return TimeZones[zone]
end

function TimeZoneService:GetTimeZoneByOffset(offset, inSeconds)
	if inSeconds then
		offset = offset / 60^2
	end
	
	for timezone, info in pairs(TimeZones) do
		if info.gmtOffset == offset then
			return timezone, info
		end
	end
	
	warn("Could not find any timezone matching a GMT offset of "..offset)
end

function TimeZoneService:GetTimeZoneByContinent(continent)
    local timezoneList = {}

    for timezone, info in pairs(TimeZones) do
        if info.continent == continent then
            local entry = {
                zone = timezone
            }
    
            for i,v in pairs(info) do
                entry[i] = v
            end

            table.insert(timezoneList, entry)
        end
    end

    return timezoneList
end

function TimeZoneService:GetTimeZoneStatus(zone1, zone2)
	local zone1Info = self:GetTimeZoneInfo(zone1)
	local zone2Info = self:GetTimeZoneInfo(zone2)
	
	local difference = math.abs(zone1Info.gmtOffset - zone2Info.gmtOffset)
	
	if zone1Info.group ~= zone2Info.group then
		difference += GROUP_WEIGHT
	end
	
	if difference <= 2 then
		return "Amazing"
	elseif difference <= 4 then
		return "Good"
	elseif difference <= 6 then
		return "Bad"
	elseif difference > 6 then
		return "Terrible"
	end
end

function TimeZoneService:SortBestTimeZones(zone)
	local zoneInfo = self:GetTimeZoneInfo(zone)
	local timezoneList = {}
	
	for timezone, info in pairs(TimeZones) do
		local difference = math.abs(zoneInfo.gmtOffset - info.gmtOffset)
		
        local entry = {
            zone = timezone,
			group = info.group,
			difference = difference
        }

        for i,v in pairs(info) do
            entry[i] = v
        end

        table.insert(timezoneList, entry)
	end
	
	table.sort(timezoneList, function(a,b)
		local weightedA = a.difference
		local weightedB = b.difference
		
		if a.group == zoneInfo.group then
			weightedA -= GROUP_WEIGHT
		end
		
		if b.group == zoneInfo.group then
			weightedB -= GROUP_WEIGHT
		end
	
		return weightedA < weightedB
	end)

	return timezoneList
end

return TimeZoneService
