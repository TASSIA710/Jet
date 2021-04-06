--[[
	Jet - (c) 2021 Tassilo <https://tassia.net>
	Licensed under the MIT License.
--]]



--- Responsible for detecting and loading plugins.
---
--- @class PluginManager
---
local CLASS = {}
CLASS.__index = CLASS



--- @type table<string, PluginInformation>
CLASS._Located = {}

--- @type table<string, Plugin>
CLASS._Loaded = {}





--- Determines if a given plugin is loaded.
---
--- @param identifier string the plugin's identifier
--- @return boolean is loaded
---
function CLASS:IsPluginLoaded(identifier)
	return self:FindPlugin(identifier) ~= nil
end


--- Finds a loaded plugin by it's identifier.
---
--- @param identifier string the identifier
--- @return Plugin|nil the plugin
---
function CLASS:FindPlugin(identifier)
	return self._Loaded[identifier]
end





--- Determines if a given plugin is available.
---
--- @param identifier string the plugin's identifier
--- @return boolean is available
---
function CLASS:IsPluginAvailable(identifier)
	return self:FindPluginInfo(identifier) ~= nil
end


--- Finds a located plugin by it's identifier.
---
--- @param identifier string the identifier
--- @return PluginInformation|nil the plugin info
---
function CLASS:FindPluginInfo(identifier)
	return self._Located[identifier]
end





--- Locates all available plugins.
---
function CLASS:LocatePlugins()
	Jet:Info("Locating plugins...")
	local files, dirs = file.Find("plugins/*", "LUA")
	for _, dir in ipairs(dirs) do
		Jet:Debug("- " .. dir)
		assert(table.HasValue(files, dir .. ".lua"), "Plugin '" .. dir .. "' found, but no '" .. dir .. ".lua' exists.")
		self:LocatePlugin(dir)
	end
	Jet:Info("Located " .. table.Count(self._Located) .. " plugins.")
end


--- Locates a single plugin by the given folder.
---
--- @param folder string the folder name
---
function CLASS:LocatePlugin(folder)
	local infoRaw = include("plugins/" .. folder .. ".lua")
	local info = self:ValidatePluginInformation(infoRaw)
	info.FolderName = folder
	self._Located[folder] = info
end





--- Validates the given raw information and creates a proper [PluginInformation].
---
---
--- @param raw any the raw information
--- @return PluginInformation the proper information
---
function CLASS:ValidatePluginInformation(raw)
	-- Assert GroupID
	assert(isstring(raw["GroupID"]) and raw["GroupID"] ~= "", "GroupID must be provided.")

	-- Assert PluginID
	assert(isstring(raw["PluginID"]) and raw["PluginID"] ~= "", "PluginID must be provided.")

	-- Assert Version
	assert(isstring(raw["Version"]) and raw["Version"] ~= "", "Version must be provided.")
	local version = Jet:ParseVersion(raw["Version"])

	-- Assert Name
	assert(isstring(raw["Name"]) and raw["Name"] ~= "", "Name must be provided.")

	-- TODO: Assert Dependencies
	local dependencies = {}

	-- TODO: Assert Soft-Dependencies
	local softDependencies = {}

	--- @type PluginInformation
	local meta = debug.getregistry()["Jet:PluginInformation"]

	return setmetatable({

		GroupID = raw["GroupID"],
		PluginID = raw["PluginID"],
		Version = version,
		Name = raw["Name"],
		Description = raw["Description"] or meta.Description,
		Authors = raw["Authors"] or meta.Authors,

		EntrypointServer = raw["EntrypointServer"] or meta.EntrypointServer,
		EntrypointShared = raw["EntrypointShared"] or meta.EntrypointServer,
		EntrypointClient = raw["EntrypointClient"] or meta.EntrypointServer,

		AutoDownloadSharedFiles = raw["AutoDownloadSharedFiles"] == true,
		AutoDownloadClientFiles = raw["AutoDownloadClientFiles"] == true,

		AutoLoadEffects = raw["AutoLoadEffects"] == true,
		AutoLoadEntities = raw["AutoLoadEntities"] == true,
		AutoLoadWeapons = raw["AutoLoadWeapons"] == true,
		AutoLoadLibraries = raw["AutoLoadLibraries"] == true,
		AutoLoadClasses = raw["AutoLoadClasses"] == true,

		LoadOrder = raw["LoadOrder"] or meta.LoadOrder,

		Dependencies = dependencies,
		SoftDependencies = softDependencies,

		Private = raw["Private"] == true,
		Homepage = raw["Homepage"],
		License = raw["License"],
		Bugs = raw["Bugs"],
		Funding = raw["Funding"],
		Repository = raw["Repository"],

	}, meta)
end





--- Loads the given plugin.
---
--- @param info PluginInformation the plugin to enable
---
function CLASS:LoadPlugin(info)

	-- Is loaded?
	local plugin = self:FindPlugin(info:Identifier())
	if plugin ~= nil then
		plugin:Debug("Already loaded.")
		return
	end

	-- Create plugin
	plugin = Jet:CreatePlugin(info)

	-- Enable dependencies
	plugin:Debug("Resolving dependencies...")
	for _, dependency in ipairs(info.Dependencies) do
		-- TODO
	end

	-- Enable soft-dependencies
	plugin:Debug("Resolving soft-dependencies...")
	for _, dependency in ipairs(info.SoftDependencies) do
		local depPlugin = self:FindPluginInfo(dependency:GetDependencyIdentifier())
		if depPlugin ~= nil then
			if dependency.Match:Matches(dependency.Version, depPlugin.Version) then
				plugin:Debug("- " .. dependency:GetDependencyIdentifier() .. " (AVAILABLE)")
				self:LoadPlugin(depPlugin)
			else
				plugin:Debug("- " .. dependency:GetDependencyIdentifier() .. " (INVALID VERSION)")
			end
		else
			plugin:Debug("- " .. dependency:GetDependencyIdentifier() .. " (NOT AVAILABLE)")
		end
	end

	-- Register plugin
	self._Loaded[info:Identifier()] = plugin

	-- Pre-Boot
	local start = SysTime()
	plugin:Info("Loading plugin...")

	-- Download shared files
	if info.AutoDownloadSharedFiles then
		plugin:Debug("- Downloading shared files...")
		self:DownloadSharedFiles(info)
	end

	-- Download client files
	if info.AutoDownloadClientFiles then
		plugin:Debug("- Downloading client files...")
		self:DownloadClientFiles(info)
	end

	-- Boot process
	for _, boot in ipairs(info.LoadOrder) do
		if boot == "classes" then
			plugin:Debug("- Loading classes...")
			self:LoadPluginClasses(info)

		elseif boot == "libraries" then
			plugin:Debug("- Loading libraries...")
			self:LoadPluginLibraries(info)

		elseif boot == "shared" then
			plugin:Debug("- Loading shared...")
			self:LoadPluginShared(info)

		elseif boot == "server" and SERVER == true then
			plugin:Debug("- Loading server-side...")
			self:LoadPluginServer(info)

		elseif boot == "client" and CLIENT == true then
			plugin:Debug("- Loading client-side...")
			self:LoadPluginClient(info)

		elseif boot == "weapons" then
			plugin:Debug("- Loading weapons...")
			self:LoadPluginWeapons(info)

		elseif boot == "entities" then
			plugin:Debug("- Loading entities...")
			self:LoadPluginEntities(info)

		elseif boot == "effects" then
			plugin:Debug("- Loading effects...")
			self:LoadPluginEffects(info)

		else
			error("Unknown boot step: '" .. boot .. "'")
		end
	end
	plugin:Info("Enabled " .. info.Name .. " v" .. info.Version .. " - took " .. (SysTime() - start) .. "s")

end





--- @param info PluginInformation the plugin information
---
function CLASS:DownloadSharedFiles(info)
	file.FindRecursive("plugins/" .. info.FolderName .. "/", "*.lua", "LUA", function(dir, file)
		if string.StartWith(file, "sh_") or string.StartWith(file, "shared") then
			AddCSLuaFile(dir .. file)
		end
	end)
end


--- @param info PluginInformation the plugin information
---
function CLASS:DownloadClientFiles(info)
	file.FindRecursive("plugins/" .. info.FolderName .. "/", "*.lua", "LUA", function(dir, file)
		if string.StartWith(file, "cl_") or string.StartWith(file, "client") then
			AddCSLuaFile(dir .. file)
		end
	end)
end





--- @param info PluginInformation the plugin information
---
function CLASS:LoadPluginClasses(info)
	-- TODO
end


--- @param info PluginInformation the plugin information
---
function CLASS:LoadPluginClient(info)
	assert(CLIENT == true, "PluginManager::LoadPluginClient cannot be invoked in non-client realm.")
	letNN(info.EntrypointClient, function(it)
		include("plugins/" .. info.FolderName .. "/" .. it)
	end)
end


--- @param info PluginInformation the plugin information
---
function CLASS:LoadPluginEffects(info)
	-- TODO
end


--- @param info PluginInformation the plugin information
---
function CLASS:LoadPluginEntities(info)
	-- TODO
end


--- @param info PluginInformation the plugin information
---
function CLASS:LoadPluginLibraries(info)
	-- TODO
end


--- @param info PluginInformation the plugin information
---
function CLASS:LoadPluginServer(info)
	assert(SERVER == true, "PluginManager::LoadPluginServer cannot be invoked in non-server realm.")
	letNN(info.EntrypointServer, function(it)
		include("plugins/" .. info.FolderName .. "/" .. it)
	end)
end


--- @param info PluginInformation the plugin information
---
function CLASS:LoadPluginShared(info)
	letNN(info.EntrypointShared, function(it)
		include("plugins/" .. info.FolderName .. "/" .. it)
	end)
end


--- @param info PluginInformation the plugin information
---
function CLASS:LoadPluginWeapons(info)
	-- TODO
end





-- Register class.
debug.getregistry()["Jet:PluginManager"] = CLASS