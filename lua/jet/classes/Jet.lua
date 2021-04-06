--[[
	Jet - (c) 2021 Tassilo <https://tassia.net>
	Licensed under the MIT License.
--]]



--- The global, singleton class for Jet.
---
--- @class Jet
---
local CLASS = {}
CLASS.__index = CLASS



--- The current version of Jet.
---
--- @type Version
---
CLASS.VERSION = nil





--- Creates a new [Plugin] from the given [PluginInformation].
---
--- @param info PluginInformation the plugin information
--- @return Plugin the plugin
---
function CLASS:CreatePlugin(info)
	return setmetatable({
		PluginInfo = info
	}, debug.getregistry()["Jet:Plugin"])
end





--- Creates a new [Version].
---
--- @param major number the major version
--- @param minor number the minor version
--- @param patch number the patch version
--- @param extension string|nil the version extension
--- @return Version the created version
---
function CLASS:CreateVersion(major, minor, patch, extension)
	return setmetatable({
		Major = major,
		Minor = minor,
		Patch = patch,
		Extension = extension
	}, debug.getregistry()["Jet:Version"])
end





--- Parses a [Version] from a given string.
---
--- @param str string the string to parse
--- @return Version|nil the parsed version, or `nil` on failure
---
function CLASS:ParseVersion(str)
	local temp

	-- Major.Minor.Patch-Extension format
	temp = let({ string.match(str, "((%d+).(%d+).(%d+)-([%a%d_-]+))") }, function(it)
		if it[1] ~= str then return nil end
		return Jet:CreateVersion(tonumber(it[2]), tonumber(it[3]), tonumber(it[4]), it[5])
	end)
	if temp ~= nil then return temp end

	-- Major.Minor.Patch format
	temp = let({ string.match(str, "((%d+).(%d+).(%d+))") }, function(it)
		if it[1] ~= str then return nil end
		return Jet:CreateVersion(tonumber(it[2]), tonumber(it[3]), tonumber(it[4]), nil)
	end)
	if temp ~= nil then return temp end

	-- Major.Minor-Extension format
	temp = let({ string.match(str, "((%d+).(%d+)-([%a%d_-]+))") }, function(it)
		if it[1] ~= str then return nil end
		return Jet:CreateVersion(tonumber(it[2]), tonumber(it[3]), 0, it[4])
	end)
	if temp ~= nil then return temp end

	-- Major.Minor format
	temp = let({ string.match(str, "((%d+).(%d+))") }, function(it)
		if it[1] ~= str then return nil end
		return Jet:CreateVersion(tonumber(it[2]), tonumber(it[3]), 0, nil)
	end)
	if temp ~= nil then return temp end

	-- Illegal format
	return nil
end





--- Stores all registered objects.
---
--- @type table<string, any>
---
CLASS._Objects = nil

--- Registers the given object with the given key,
--- overriding previously registered objects if needed.
---
--- @param key string the object key
--- @param value any the object
---
function CLASS:SetObject(key, value)
	assert(key ~= nil, "Key may not be nil.")
	assert(value ~= "Value may not be nil. Use Jet::UnsetObject for removing objects.")
	self._Objects[key] = value
end

--- Fetches a registered object by it's key.
---
--- @param key string the object key
--- @return any|nil the object or `nil`
function CLASS:GetObject(key)
	return self._Objects[key]
end

--- Removes an object registered by the given key.
---
--- @param key string the key
---
function CLASS:UnsetObject(key)
	assert(key ~= nil, "Key may not be nil.")
	self._Objects[key] = nil
end





function CLASS:Log(source, level, ...)
	print(source .. " : " .. level .. ">", ...)
end

function CLASS:Info(...)
	self:Log("Jet", " INFO")
end

function CLASS:Debug(...)
	self:Log("Jet", "DEBUG")
end

function CLASS:Warning(...)
	self:Log("Jet", " WARN")
end

function CLASS:Error(...)
	self:Log("Jet", "ERROR")
end

function CLASS:Severe(...)
	self:Log("Jet", "SEVERE")
end





--- The [PluginManager].
---
--- @type PluginManager
---
CLASS._Plugins = nil

--- Returns the [PluginManager].
---
--- @return PluginManager the plugin manager
---
function CLASS:Plugins()
	return self._Plugins
end





--- Formats the given amount of seconds to a readable time length.
---
--- @param seconds number the amount of seconds
--- @return string a readable string
---
function CLASS:FormatTimeLength(seconds)
	return math.Round(seconds * 1000, 2) .. "ms"
end





-- Register class.
debug.getregistry()["Jet"] = CLASS
