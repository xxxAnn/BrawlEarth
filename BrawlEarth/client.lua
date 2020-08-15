-- HTTP client
local http = require 'socket.http'
local https = require 'ssl.https'
-- JSON decoder
json = require 'BrawlEarth.json'

Client = {};
Client.__index = Client
--[[ Pointing __index Client then setting the metatable to {}
so that added methods are indexed in the metatable and accessible
through the getmetatable built-in
--]]
setmetatable(Client, {})


-- Waits for a certain amount of seconds
local function wait(seconds)
    local endTime = os.time() + seconds
    while os.time() < endTime do
    end
end


-- Makes request to the API
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
	if c ~= 200 then return "Error" end

	return json.decode(resp).items
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
		table = {
		['gadgets'] = v.gadgets, 
		['starPowers'] = v.starPowers, 
		['id'] = v.id
		}
		brawlers[v.name] = table
	end

	return brawlers
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