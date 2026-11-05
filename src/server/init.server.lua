-- Server entry point - Knit initialization

local ServerScriptService = game:GetService("ServerScriptService")

-- TODO: Install Knit via Wally/Roblox package manager
-- For now, manually require services

local serverFolder = ServerScriptService:FindFirstChild("src")
if serverFolder then
	local server = serverFolder:FindFirstChild("server")
	if server then
		local services = server:FindFirstChild("services")
		if services then
			for _, service in ipairs(services:GetChildren()) do
				if service:IsA("ModuleScript") then
					local success, result = pcall(require, service)
					if success then
						print("[Server] Loaded service:", service.Name)
					else
						warn("[Server] Failed to load service:", service.Name, result)
					end
				end
			end
		end
	end
end

print("[Server] Initialized (Knit framework pending installation)")