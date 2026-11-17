-- Brainrot Bay — small shared helpers used by server and client.

local Utils = {}

-- Formats an amount of cash for the HUD and name tags.
-- 1240 -> "$1,240"; 2500000 -> "$2.50M"; 1800 -> "$1,800".
function Utils.formatMoney(amount: number): string
	local n = math.floor(amount + 0.5)
	if n >= 1_000_000 then
		return string.format("$%.2fM", n / 1_000_000)
	elseif n >= 100_000 then
		return string.format("$%.1fK", n / 1_000)
	elseif n >= 1_000 then
		-- Insert the thousands separator by hand.
		local s = tostring(n)
		local out = ""
		while #s > 3 do
			out = "," .. string.sub(s, -3) .. out
			s = string.sub(s, 1, -4)
		end
		return "$" .. s .. out
	else
		return "$" .. tostring(n)
	end
end

-- Short form for the conveyor price tags: 1500 -> "$1.5K".
function Utils.formatShort(amount: number): string
	local n = math.floor(amount + 0.5)
	if n >= 1_000_000 then
		return string.format("$%.2fM", n / 1_000_000)
	elseif n >= 1_000 then
		return string.format("$%.1fK", n / 1_000)
	else
		return "$" .. tostring(n)
	end
end

-- The display colour for a rarity name.
function Utils.rarityColor(rarityName: string, config): Color3
	local entry = config.RARITIES[rarityName]
	if entry then
		return entry.color
	end
	return Color3.fromRGB(255, 255, 255)
end

function Utils.clamp(value: number, low: number, high: number): number
	if value < low then
		return low
	elseif value > high then
		return high
	end
	return value
end

-- Horizontal distance between two world positions (ignores height).
function Utils.distanceBetween(a: Vector3, b: Vector3): number
	local dx = a.X - b.X
	local dz = a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

-- Picks one entry from a weighted table like {Common = 55, Rare = 25}.
function Utils.weightedPick(weights: { [string]: number }): string
	local total = 0
	for _, w in pairs(weights) do
		total += w
	end
	local roll = math.random() * total
	for name, w in pairs(weights) do
		roll -= w
		if roll <= 0 then
			return name
		end
	end
	return "Common"
end

return Utils
