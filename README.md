# Roblox-TimeZoneService
A way to get server or client timezones while also comparing their viability with each other.

## Disclaimer
This was more of a fun side project that I wrote in about 2 hours. I have no clue what the API limitations are, and the function weightings are completely based on my opinion.

## Functions
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

## NOTES
I assigned groups to each timezone as a timezone alone is not a viable way to determine whether a player's ping will be good or not in that region. For example, EST and PRT are only one hour apart, yet for most on the EST zone CTL, MNT, and even PST are better options. Feel free to change the weight or groups as you see fit.