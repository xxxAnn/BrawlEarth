-- HTTP client
local http = require 'socket.http'
local https = require 'ssl.https'
-- JSON decoder
json = require 'BrawlEarth.json'

Client = {};
Client.__index = Client
setmetatable(Client, {})

-- Local functions

local function wait(seconds)
	--[[
	Waits for a certain amount of second
	]]--
    local endTime = os.time() + seconds
    while os.time() < endTime do
    end
end

-- Public functions

function Client:request(sub, method)
	--[[
	Makes a request to the API with the predefined token
	and the subdomain provided.
	]]--
	wait(1)
	meth = method or "GET"
	baseUrl = 'https://api.brawlstars.com'
	url = baseUrl .. sub
	if self.verbose == true then print("> Requesting " .. url .. " <") end

	resp = {}

	r, c = https.request {
	method = meth,
	url = url,
	headers = self.headers,
	sink = ltn12.sink.table(resp)
	}
	resp = table.concat(resp)

	if self.verbose == true then print("HTTP Code: " .. tostring(c)) end
	if c ~= 200 then error("An HTTP error code was received" .. tostring(c)) end

	return json.decode(resp)
end

function Client:getBrawlers(options)
	--[[
	Returns a table with all the brawlers following this format:
	assuming `table` is the returned value:
	assuming characters prefixed with && to be replaced by a valid string 
	as indicated after that characters:
	####
	table.&&brawlerName.gadgets = `table with a list of gadgets`
	table.&&brawlerName.starPowers = `table with a list of star powers`
	table.&&brawlerName.id = `the specific brawler's id`
	####

	%%------------------------------------------------------------%%

	If the returnRaw option is passed as true then the list will be shaped like this:
	(zz = a two digit number ranging from 1 to the number of brawlers)
	####
	table.&&zz.gadgets = `table with a list of gadgets`
	table.&&zz.starPowers = `table with a list of star powers`
	table.&&zz.id = `the specific brawler's id`
	table.&&zz.id = `the specific brawler's name`
	####
	]]--
	returnRaw = options.returnRaw or false
	resp = self:request('/v1/brawlers')
	-- returns an untreated list
	if returnRaw == true then return resp end

	brawlers = {}
	for k, v in pairs(resp) do
		local table = {
		['gadgets'] = v.gadgets, 
		['starPowers'] = v.starPowers, 
		['id'] = v.id
		}
		brawlers[v.name] = table
	end

	return brawlers
end

function Client:getPlayer(options)
	--[[
	Result table structure:
	####
	{
	  "club": {
		"tag": "string",
		"name": "string"
	  },
	  "3vs3Victories": 0,
	  "isQualifiedFromChampionshipChallenge": true,
	  "icon": {
		"id": 0
	  },
	  "tag": "string",
	  "name": "string",
	  "trophies": 0,
	  "expLevel": 0,
	  "expPoints": 0,
	  "highestTrophies": 0,
	  "powerPlayPoints": 0,
	  "highestPowerPlayPoints": 0,
	  "soloVictories": 0,
	  "duoVictories": 0,
	  "bestRoboRumbleTime": 0,
	  "bestTimeAsBigBrawler": 0,
	  "brawlers": [
		{
		  "starPowers": [
			{
			  "name": {},
			  "id": 0
			}
		  ],
		  "gadgets": [
			{
			  "name": {},
			  "id": 0
			}
		  ],
		  "id": 0,
		  "rank": 0,
		  "trophies": 0,
		  "highestTrophies": 0,
		  "power": 0,
		  "name": {}
		}
	  ],
	  "nameColor": "string"
	}
	####
	Doesn't have to be wrapped in a pcall
	playerTag is a required keyword argument
	If the returnRaw option is passed as false, `view getBrawler to see the result for table.brawlers`
	]]--

	playerTag = options.playerTag or false
	returnRaw = options.returnRaw or false

	if playerTag == false then error("Player tag is a required argument that is missing") end

	playerTag = '%23' .. playerTag
	response = self:request('/v1/players/' .. playerTag)
	
	if returnRaw == true then return response end

	brawlers = {}
	for k, v in pairs(response.brawlers) do
		local table = {
		['gadgets'] = v.gadgets, 
		['starPowers'] = v.starPowers, 
		['id'] = v.id
		}
		brawlers[v.name] = table
	end

	response.brawlers = brawlers

	return response
end

function Client:getClub(options)
	--[[
	Returns a table with the following template:
	{
		"tag": "string",
		"name": "string",
		"description": "string",
		"trophies": 0,
		"requiredTrophies": 0,
		"members": [
		{
			"tag": "string",
			"name": "string",
			"trophies": 0,
			"role": "string",
			"nameColor": "string"
		}
		],
		"type": "string"
	}
	]]--
	clubTag = string.gsub('%23' .. options.clubTag, '#', '')

	response = self:request('/v1/clubs/' .. clubTag)

	return response
end

function Client:new(token, verbose, obj)
	--[[
	Creates a new client object with the passed token
	pass pos arg 2 as `true` for verbose dialogue
	]]--
	tbl = obj or {}
	self.verbose = verbose or false
	-- Headers
	auth = "Bearer " .. token
	headers = {
	['Authorization'] = auth,
	['User-Agent'] = "BrawlEarth Lua handler"
	}
	tbl.headers = headers
	setmetatable(tbl, self)
    return tbl
end


return Client