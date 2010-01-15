--[[****************************************************************************
  * _Underscore.Chat by Saiket                                                 *
  * _Underscore.Chat.Icons.lua - Adds icons for many chat link types.          *
  ****************************************************************************]]


local me = {};
_Underscore.Chat.Icons = me;




--[[****************************************************************************
  * Function: _Underscore.Chat.Icons.SpellGsub                                 *
  ****************************************************************************]]
do
	local GetSpellInfo = GetSpellInfo;
	local Texture, _;
	function me.SpellGsub ( Full, ID )
		_, _, Texture = GetSpellInfo( ID );
		return Texture and "|T"..Texture..":0|t"..Full;
	end
end
--[[****************************************************************************
  * Function: _Underscore.Chat.Icons.ItemGsub                                  *
  ****************************************************************************]]
do
	local GetItemIcon = GetItemIcon;
	local Texture;
	function me.ItemGsub ( Full, ItemString )
		Texture = GetItemIcon( ItemString );
		return Texture and "|T"..Texture..":0|t"..Full;
	end
end
--[[****************************************************************************
  * Function: _Underscore.Chat.Icons.AchievementGsub                           *
  ****************************************************************************]]
do
	local GetAchievementInfo = GetAchievementInfo;
	local select = select;
	local Texture;
	function me.AchievementGsub ( Full, ID )
		Texture = select( 10, GetAchievementInfo( ID ) );
		return Texture and "|T"..Texture..":0|t"..Full;
	end
end


--[[****************************************************************************
  * Function: _Underscore.Chat.Icons.Filter                                    *
  ****************************************************************************]]
function me.Filter ( Text )
	Text = Text:gsub( "(|cff%x%x%x%x%x%x|Hspell:(%d+))", me.SpellGsub );
	Text = Text:gsub( "(|cff%x%x%x%x%x%x|Htrade:(%d+))", me.SpellGsub );
	Text = Text:gsub( "(|cff%x%x%x%x%x%x|Henchant:(%d+))", me.SpellGsub );
	Text = Text:gsub( "(|cff%x%x%x%x%x%x|H(item:[^|]+))", me.ItemGsub );
	Text = Text:gsub( "(|cff%x%x%x%x%x%x|Hachievement:(%d+))", me.AchievementGsub );
	return Text;
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Underscore.Chat.RegisterFilter( me.Filter );
end
