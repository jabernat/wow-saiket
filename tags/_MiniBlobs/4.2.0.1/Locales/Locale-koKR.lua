--[[****************************************************************************
  * _MiniBlobs by Saiket                                                       *
  * Locales/Locale-koKR.lua - Localized string constants (ko-KR).              *
  ****************************************************************************]]


if ( GetLocale() ~= "koKR" ) then
	return;
end


-- See http://wow.curseforge.com/addons/miniblobs/localization/koKR/
local _MiniBlobs = select( 2, ... );
_MiniBlobs.L = setmetatable( {
	Styles = setmetatable( {
		Archaeology = "붉은색", -- Needs review
		Quests = "푸른색", -- Needs review
	}, _MiniBlobs.L.Styles );
	Types = setmetatable( {
		Archaeology = "고고학", -- Needs review
		Quests = "퀘스트", -- Needs review
	}, _MiniBlobs.L.Types );

	QUALITY = "품질", -- Needs review
	QUALITY_HIGH = "품질", -- Needs review
	QUALITY_LOW = "성능", -- Needs review
	TYPE_ALPHA = "투명도", -- Needs review
	TYPE_STYLE = "스타일", -- Needs review
}, { __index = _MiniBlobs.L; } );