local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local IsServer = RunService:IsServer()

local GROUP_WEIGHT = 3.25

local TimeZones = {
	["GMT"] = {
		name = "Greenwich Mean Time",
		gmtOffset = 0,
		group = "EU"
	},
	
	["ECT"] = {
		name = "European Central Time",
		gmtOffset = 1,
		group = "EU"
	},
	
	["EET"] = {
		name = "Eastern European Time",
		gmtOffset = 2,
		group = "EU"
	},
	
	["EAT"] = {
		name = "Eastern African Time",
		gmtOffset = 3,
		group = "AF"
	},
	
	["MET"] = {
		name = "Middle East Time",
		gmtOffset = 3.5,
		group = "AF"
	},
	
	["NET"] = {
		name = "Near East Time",
		gmtOffset = 4,
		group = "AF"
	},
	
	["PLT"] = {
		name = "Pakistan Lahore Time",
		gmtOffset = 5,
		group = "AF"
	},

	["IST"] = {
		name = "India Standard Time",
		gmtOffset = 5.5,
		group = "AS"
	},
	
	["BST"] = {
		name = "Bangladesh Standard Time",
		gmtOffset = 6,
		group = "AS"
	},
	
	["VST"] = {
		name = "Vietnam Standard Time",
		gmtOffset = 7,
		group = "CAS"
	},
	
	["CTT"] = {
		name = "China Taiwan Time",
		gmtOffset = 8,
		group = "CAS"
	},
	
	["JST"] = {
		name = "Japan Standard Time",
		gmtOffset = 9,
		group = "EAS"
	},
	
	["ACT"] = {
		name = "Australia Central Time",
		gmtOffset = 9.5,
		group = "AU"
	},
	
	["ACDT"] = {
		name = "Australian Central Daylight Savings Time",
		gmtOffset = 10.5,
		group = "AU"
	},
	
	["AET"] = {
		name = "Australia Eastern Time",
		gmtOffset = 10,
		group = "AU"
	},
	
	["SST"] = {
		name = "Solomon Standard Time",
		gmtOffset = 11,
		group = "AU"
	},
	
	["NST"] = {
		name = "New Zealand Standard Time",
		gmtOffset = 12,
		group = "AU"
	},
	
	["MIT"] = {
		name = "Midway Islands Time",
		gmtOffset = -11,
		group = "US"
	},
	
	["HST"] = {
		name = "Hawaii Standard Time",
		gmtOffset = -10,
		group = "US"
	},
	
	["AST"] = {
		name = "Alaska Standard Time",
		gmtOffset = -9,
		group = "US"
	},
	
	["PST"] = {
		name = "Pacific Standard Time",
		gmtOffset = -8,
		group = "US"
	},
	
	["MST"] = {
		name = "Mountain Standard Time",
		gmtOffset = -7,
		group = "US"
	},
	
	["CST"] = {
		name = "Central Standard Time",
		gmtOffset = -6,
		group = "US"
	},
	
	["EST"] = {
		name = "Eastern Standard Time",
		gmtOffset = -5,
		group = "US"
	},
	
	["PRT"] = {
		name = "Puerto Rico and US Virgin Islands Time",
		gmtOffset = -4,
		group = "PR"
	},
	
	["CNT"] = {
		name = "Canada Newfoundland Time",
		gmtOffset = -3.5,
		group = "CA"
	},
	
	["BET"] = {
		name = "Brazil Eastern Time",
		gmtOffset = -3,
		group = "BR"
	},
	
	["CAT"] = {
		name = "Central African Time",
		gmtOffset = -1,
		group = "AF"
	},
}

local Connection

if not IsServer then
	Connection = script:WaitForChild("Connection")
	
	Connection.OnClientInvoke = function(action)
		if action == "get-zone" then
			return math.floor((tick() - workspace:GetServerTimeNow()) / 100 + 0.5) * 100
		end
	end
else
	Connection = Instance.new("RemoteFunction")
	Connection.Name = "Connection"
	Connection.Parent = script
end

local TimeZoneService = {}

function TimeZoneService:GetServerZoneInfo()
	assert(IsServer, "This function can only be run on the server, not the client")
	
	local ipResult

	local success, message = pcall(function()
		ipResult = HttpService:JSONDecode(HttpService:GetAsync("https://api4.my-ip.io/ip.json"))
	end)

	if success and ipResult.ip then
		local locationResult
		local success, message = pcall(function()
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
	
	local utcOffsetInSeconds
	local success, message = pcall(function()
		utcOffsetInSeconds = Connection:InvokeClient(client, "get-zone")
	end)
	
	if success and utcOffsetInSeconds then
		return self:GetByGMTOffset(utcOffsetInSeconds, true)
	end
end

function TimeZoneService:GetTimeZoneInfo(tzAbbreviation)
	return TimeZones[tzAbbreviation]
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

function TimeZoneService:GetByGMTOffset(gmtOffset, inSeconds)
	if inSeconds then
		gmtOffset = gmtOffset / 60^2
	end
	
	for timezone, info in pairs(TimeZones) do
		if info.gmtOffset == gmtOffset then
			return timezone, info
		end
	end
	
	warn("Could not find any timezone matching a GMT offset of "..gmtOffset)
end

function TimeZoneService:SortBestTimeZones(tzAbbreviation)
	local tzInfo = self:GetTimeZoneInfo(tzAbbreviation)
	local timezoneList = {}
	
	for timezone, info in pairs(TimeZones) do
		local difference = math.abs(tzInfo.gmtOffset - info.gmtOffset)
		
		table.insert(timezoneList, {
			zone = timezone,
			group = info.group,
			difference = difference
		})
	end
	
	table.sort(timezoneList, function(a,b)
		local weightedA = a.difference
		local weightedB = b.difference
		
		if a.group == tzInfo.group then
			weightedA -= GROUP_WEIGHT
		end
		
		if b.group == tzInfo.group then
			weightedB -= GROUP_WEIGHT
		end
	
		return weightedA < weightedB
	end)

	return timezoneList
end

return TimeZoneService
