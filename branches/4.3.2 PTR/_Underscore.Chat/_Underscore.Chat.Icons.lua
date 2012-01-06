--[[****************************************************************************
  * _Underscore.Chat by Saiket                                                 *
  * _Underscore.Chat.Icons.lua - Adds icons for many chat link types.          *
  ****************************************************************************]]


local LinkFilters = {
	spell = GetSpellTexture;
	trade = GetSpellTexture;
	enchant = GetSpellTexture;
	item = GetItemIcon;
};
do
	local select, GetAchievementInfo = select, GetAchievementInfo;
	--- @return Texture path for AchievementID.
	function LinkFilters.achievement ( AchievementID )
		return select( 10, GetAchievementInfo( AchievementID ) );
	end
end


--- Adds an icon to a link found by gsub.
local function LinkGsub ( Full, Pipes, Type, ID )
	local LinkFilter = LinkFilters[ Type ];
	if ( LinkFilter and #Pipes % 2 == 1 ) then -- Recognized type, not escaped
		local Texture = LinkFilter( ID );
		if ( Texture ) then
			return "|T"..Texture..":0:0:0:0:100:100:8:92:8:92|t"..Full;
		end
	end
end
--- @return Text with icons added to all links.
local function Filter ( Text )
	return Text:gsub( "((|+)c%x%x%x%x%x%x%x%x|H([^:]+):(%d+))", LinkGsub );
end


_Underscore.Chat.RegisterFilter( Filter );