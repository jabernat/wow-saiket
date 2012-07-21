--[[****************************************************************************
  * _Cursor by Saiket                                                          *
  * Locales/Locale-zhCN.lua - Localized string constants (zh-CN).              *
  ****************************************************************************]]


if ( GetLocale() ~= "zhCN" ) then
	return;
end


-- See http://wow.curseforge.com/addons/cursor/localization/zhCN/
_CursorLocalization = setmetatable( {
	OPTIONS_DESC = "这些选项可以让你改变鼠标指针的模型和移动轨迹效果.你可以使用预置方案或者使用你自己特别的效果！", -- Needs review
	RESET_ALL = "配置 & 指针", -- Needs review
	RESET_CHARACTER = "只是指针", -- Needs review
	TYPE_CUSTOM = "自定义", -- Needs review


	OPTIONS = setmetatable( {
		APPLY = "应用", -- Needs review
		CURSORS = "指针", -- Needs review
		DELETE = "删除", -- Needs review
		DELETE_DESC = "移除当前配置到所有角色", -- Needs review
		ENABLED = "开启模型", -- Needs review
		ENABLED_DESC = "启动或关闭当前指针层", -- Needs review
		FACING = "方向", -- Needs review
		FACING_DESC = "旋转模型", -- Needs review
		FACING_LOW = "0", -- Needs review
		LOAD = "加载", -- Needs review
		PATH = "文件路径", -- Needs review
		PREVIEW_DESC = [=[当前效果预览
	|cffffffff点击改变演示动画速度]=], -- Needs review
		SAVE = "保存", -- Needs review
		SCALE = "缩放", -- Needs review
		SCALE_DESC = "调整模型的大小", -- Needs review
		SET_DESC = "保存或读取光标配置方案的名称. 使用下拉菜单选择已经保存的配置！", -- Needs review
		SETS = "配置方案", -- Needs review
		TYPE = "预置样式", -- Needs review
		TYPE_DESC = "此组是预置的光标样式，也可以使用\"自定义\"选项 ，下面需要添加的模型路径！", -- Needs review
		VALUE = "样式名称", -- Needs review
		X_DESC = "X轴偏移：调整模型水平位置", -- Needs review
		Y_DESC = "Y轴偏移：调整模型垂直位置", -- Needs review
	}, { __index = _CursorLocalization.OPTIONS; } );
	SETS = setmetatable( {
	}, { __index = _CursorLocalization.SETS; } );
	CURSORS = setmetatable( {
	}, { __index = _CursorLocalization.CURSORS; } );
	TYPES = setmetatable( {
		Breath = "吐息", -- Needs review
		Glow = "发光", -- Needs review
		Particle = "颗粒", -- Needs review
		Trail = "轨迹", -- Needs review
	}, { __index = _CursorLocalization.TYPES; } );
		VALUES = setmetatable( {
		Arcane = "奥术", -- Needs review
		Blue = "蓝色", -- Needs review
		["Burning cloud, blue"] = "燃烧烟,蓝色", -- Needs review
		["Burning cloud, green"] = "燃烧烟,绿色", -- Needs review
		["Burning cloud, purple"] = "燃烧烟,紫色", -- Needs review
		["Burning cloud, red"] = "燃烧烟,红色", -- Needs review
		["Cloud, black & blue"] = "烟雾,黑色和蓝色", -- Needs review
		["Cloud, blue"] = "烟雾,蓝色", -- Needs review
		["Cloud, bright purple"] = "烟雾,亮紫", -- Needs review
		["Cloud, corruption"] = "烟雾,堕落", -- Needs review
		["Cloud, dark blue"] = "烟雾,深蓝", -- Needs review
		["Cloud, executioner"] = "烟雾,刽子手", -- Needs review
		["Cloud, fire"] = "烟雾,火焰", -- Needs review
		["Cloud, frost"] = "烟雾,冰霜", -- Needs review
		["Dust, arcane"] = "尘,奥术", -- Needs review
		["Dust, embers"] = "尘,余烬", -- Needs review
		["Dust, holy"] = "尘.圣光", -- Needs review
		["Dust, ice shards"] = "尘,冰片", -- Needs review
		["Dust, shadow"] = "尘,暗影", -- Needs review
		["Electric, blue"] = "电,蓝色", -- Needs review
		["Electric, blue long"] = "电,蓝色 长", -- Needs review
		["Electric, green"] = "电,绿色", -- Needs review
		["Electric, yellow"] = "电,黄色", -- Needs review
		Fire = "火", -- Needs review
		["Fire, blue"] = "火,蓝色", -- Needs review
		["Fire. blue"] = "火,蓝色", -- Needs review
		["Fire, fel"] = "火,绿色", -- Needs review
		["Fire, orange"] = "火,橙色", -- Needs review
		["Fire, periodic red & blue"] = "火,红蓝交加", -- Needs review
		["Fire, purple"] = "火,紫色", -- Needs review
		["Fire, red"] = "火,红色", -- Needs review
		["Fire, wavy purple"] = "火,波浪紫", -- Needs review
		["First-aid"] = "急救", -- Needs review
		Freedom = "自由", -- Needs review
		Frost = "冰霜", -- Needs review
		Frostfire = "霜火", -- Needs review
	}, { __index = _CursorLocalization.VALUES; } );
}, { __index = _CursorLocalization; } );


SLASH__CURSOR_OPTIONS2 = "/cursoroptions";
SLASH__CURSOR_OPTIONS3 = "/cursor选项";