--[[****************************************************************************
  * _Underscore.Chat by Saiket                                                 *
  * _Underscore.Chat.Icons.lua - Adds icons for many chat link types.          *
  ****************************************************************************]]


local me = {};
_Underscore.Chat.Icons = me;

me.LinkFilters = {};




--[[****************************************************************************
  * Function: _Underscore.Chat.Icons.LinkFilters.spell                         *
  ****************************************************************************]]
do
	local GetSpellInfo = GetSpellInfo;
	function me.LinkFilters.spell ( SpellID )
		local _, _, Texture = GetSpellInfo( SpellID );
		return Texture;
	end
end
--[[****************************************************************************
  * Function: _Underscore.Chat.Icons.LinkFilters.trade                         *
  ****************************************************************************]]
me.LinkFilters.trade = me.LinkFilters.spell;
--[[****************************************************************************
  * Function: _Underscore.Chat.Icons.LinkFilters.enchant                       *
  ****************************************************************************]]
me.LinkFilters.enchant = me.LinkFilters.spell;
--[[****************************************************************************
  * Function: _Underscore.Chat.Icons.LinkFilters.item                          *
  ****************************************************************************]]
me.LinkFilters.item = GetItemIcon;
--[[****************************************************************************
  * Function: _Underscore.Chat.Icons.LinkFilters.achievement                   *
  ****************************************************************************]]
do
	local GetAchievementInfo = GetAchievementInfo;
	local select = select;
	function me.LinkFilters.achievement ( AchievementID )
		return select( 10, GetAchievementInfo( AchievementID ) );
	end
end


--[[****************************************************************************
  * Function: _Underscore.Chat.Icons.Filter                                    *
  ****************************************************************************]]
do
	local function LinkGsub ( Full, Pipes, Type, ID )
		local LinkFilter = me.LinkFilters[ Type ];
		if ( LinkFilter and #Pipes % 2 == 1 ) then -- Recognized type, not escaped
			local Texture = LinkFilter( ID );
			return Texture and "|T"..Texture..":0:0:0:0:100:100:8:92:8:92|t"..Full; -- Cropped like in _Underscore.SkinButtonIcon
		end
	end
	function me.Filter ( Text )
		return Text:gsub( "((|+)H([^:]+):(%d+))", LinkGsub );
	end
end




_Underscore.Chat.RegisterFilter( me.Filter );