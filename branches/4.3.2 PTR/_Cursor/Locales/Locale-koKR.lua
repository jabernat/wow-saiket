--[[****************************************************************************
  * _Cursor by Saiket                                                          *
  * Locales/Locale-koKR.lua - Localized string constants (ko-KR).              *
  ****************************************************************************]]


if ( GetLocale() ~= "koKR" ) then
	return;
end


-- See http://wow.curseforge.com/addons/cursor/localization/koKR/
_CursorLocalization = setmetatable( {
	OPTIONS_DESC = "마우스를 따라다니는 커서 모델을 바꾸는 설정입니다.  프리셋 또는 자신만의 특정 세트를 선택할 수 있습니다.",
	OPTIONS_TITLE = "_|cffcccc88Cursor|r",
	RESET_ALL = "세트와 커서",
	RESET_CHARACTER = "커서만 초기화",
	RESET_CONFIRM = "_|cffcccc88Cursor|r: 이 캐릭터의 커서와 모든 캐릭터의 세트를 초기화하거나, 또는 커서만 초기화 하시겠습니까?",
	TYPE_CUSTOM = "사용자 정의",


	OPTIONS = setmetatable( {
		APPLY = "적용",
		CURSORS = "커서",
		DELETE = "삭제",
		DELETE_DESC = "이 세트를 모든 캐릭터에서 제거합니다.",
		ENABLED = "모델 활성화",
		ENABLED_DESC = "이 커서 레이어를 보이게 할 것인지를 토글합니다.",
		FACING = "회전",
		FACING_DESC = "모델을 회전합니다.",
		FACING_HIGH = "2π",
		FACING_LOW = "0",
		LOAD = "불러오기",
		PATH = "파일 경로",
		PATH_DESC = "사용할 모델 파일의 경로를 파일 확장자를 제외하여 입력하세요.",
		PREVIEW_DESC = [=[선택한 커서 레이어의 미리보기입니다.
|cffffffff클릭하면 애니메이션 속도를 순환하게 됩니다.]=],
		SAVE = "저장하기",
		SCALE = "크기",
		SCALE_DESC = "모델을 크게 또는 작게 그립니다.",
		SET_DESC = "커서 세트 이름을 저장하거나 불러옵니다.  드랍다운 버튼은 저장된 세트를 선택하는데 사용됩니다.",
		SETS = "세트",
		TYPE = "프리셋 형식",
		TYPE_DESC = "커서 레이어 프리셋의 그룹을 선택할 수 있으며, 또는 “사용자 정의”를 선택하여 임의의 모델 경로를 지정할 수 있습니다.",
		VALUE = "프리셋 이름",
		VALUE_DESC = "선택한 형식의 카테고리에서 프리셋을 선택할 수 있습니다.",
		X_DESC = "X-오프셋: 모델을 왼쪽 또는 오른쪽으로 이동합니다.",
		Y_DESC = "Y-오프셋: 모델을 위쪽 또는 아래쪽으로 이동합니다.",
	}, { __index = _CursorLocalization.OPTIONS; } );
	SETS = setmetatable( {
		["Energy beam"] = "에너지 빔",
		["Face Melter (Warning, bright!)"] = "얼굴 용해기 (경고, 매우 밝음!)",
		["Shadow trail"] = "암흑 자국",
	}, { __index = _CursorLocalization.SETS; } );
	CURSORS = setmetatable( {
		Heat = "열기",
		Laser = "레이저",
		["Layer 1"] = "레이어 1",
		["Layer 2"] = "레이어 2",
		["Layer 3"] = "레이어 3",
		Smoke = "연기",
	}, { __index = _CursorLocalization.CURSORS; } );
	TYPES = setmetatable( {
		Breath = "숨결",
		Glow = "작열",
		Particle = "입자",
		Trail = "자국",
	}, { __index = _CursorLocalization.TYPES; } );
	VALUES = setmetatable( {
		Arcane = "비전",
		Blue = "파란색",
		["Burning cloud, blue"] = "타오르는 구름, 푸른색",
		["Burning cloud, green"] = "타오르는 구름, 녹색",
		["Burning cloud, purple"] = "타오르는 구름, 보라색",
		["Burning cloud, red"] = "타오르는 구름, 빨간색",
		["Cloud, black & blue"] = "구름, 검은색과 푸른색",
		["Cloud, blue"] = "구름, 푸른색",
		["Cloud, bright purple"] = "구름, 밝은 보라색",
		["Cloud, corruption"] = "구름, 타락",
		["Cloud, dark blue"] = "구름, 어두운 푸른색",
		["Cloud, executioner"] = "구름, 집행자",
		["Cloud, fire"] = "구름, 화염",
		["Cloud, frost"] = "구름, 냉기",
		["Dust, arcane"] = "먼지, 비전",
		["Dust, embers"] = "먼지, 불씨",
		["Dust, holy"] = "먼지, 신성",
		["Dust, ice shards"] = "먼지, 얼음 파면",
		["Dust, shadow"] = "먼지, 암흑",
		["Electric, blue"] = "전기, 파란색",
		["Electric, blue long"] = "전기, 긴 파란색",
		["Electric, green"] = "전기, 녹색",
		["Electric, yellow"] = "전기, 노란색",
		Fire = "화염",
		["Fire, blue"] = "화염, 푸른색",
		["Fire. blue"] = "화염, 파란색",
		["Fire, fel"] = "화염, 지옥",
		["Fire, orange"] = "화염, 주황색",
		["Fire, periodic red & blue"] = "화염, 주기적인 빨간색과 파란색",
		["Fire, purple"] = "화염, 보라색",
		["Fire, red"] = "화염, 빨간색",
		["Fire, wavy purple"] = "화염, 물결치는 보라색",
		["First-aid"] = "응급 치료",
		Freedom = "자유",
		Frost = "냉기",
		Frostfire = "냉기화염",
		Ghost = "유령",
		["Holy bright"] = "신성한 빛",
		["Lava burst"] = "용암 폭발",
		Leaves = "나뭇잎",
		["Long blue & holy glow"] = "긴 파란색 & 신성 작열",
		["Periodic glint"] = "주기적인 반짝임",
		["Plague cloud"] = "역병 구름",
		["Ring, bloodlust"] = "고리, 피의 욕망",
		["Ring, bones"] = "고리, 뼈",
		["Ring, frost"] = "고리, 냉기",
		["Ring, holy"] = "고리, 신성",
		["Ring, pulse blue"] = "고리, 푸른색 맥박",
		["Ring, vengeance"] = "고리, 복수심",
		Shadow = "암흑",
		["Shadow cloud"] = "암흑 구름",
		["Simple, black"] = "단순함, 검은색",
		["Simple, green"] = "단순함, 녹색",
		["Simple, white"] = "단순함, 흰색",
		Smoke = "연기",
		Souls = "영혼",
		["Souls, small"] = "영혼, 작은",
		["Sparkling, blue"] = "불꽃 튀기는, 파란색",
		["Sparkling, light green"] = "불꽃 튀기는, 밝은 녹색",
		["Sparkling, red"] = "불꽃 튀기는, 빨간색",
		["Sparkling, white"] = "불꽃 튀기는, 흰색",
		["Spark, small blue"] = "불꽃, 작은 파란색",
		["Spark, small white"] = "불꽃, 작은 하얀색",
		["Sparks, periodic healing"] = "불꽃, 주기적인 치유",
		["Sparks, red"] = "불꽃, 빨간색",
		["Swirling, black"] = "소용돌이 치는, 검은색",
		["Swirling, blood"] = "소용돌이 치는, 피",
		["Swirling, blue"] = "소용돌이 치는, 파란색",
		["Swirling, holy"] = "소용돌이 치는, 신성",
		["Swirling, nature"] = "소용돌이 치는, 자연",
		["Swirling, poison"] = "소용돌이 치는, 독",
		["Swirling, purple"] = "소용돌이 치는, 보라색",
		["Swirling, shadow"] = "소용돌이 치는, 암흑",
		["Swirling, white"] = "소용돌이 치는, 흰색",
		["Swirling, yellow"] = "소용돌이 치는, 노란색",
		["Weather, cloudy"] = "날씨, 구름",
		["Weather, lightning"] = "날씨, 번개",
		["Weather, snow"] = "날씨, 눈",
		["Weather, sun"] = "날씨, 태양",
	}, { __index = _CursorLocalization.VALUES; } );
}, { __index = _CursorLocalization; } );


SLASH__CURSOR_OPTIONS1 = "/cursor";
SLASH__CURSOR_OPTIONS2 = "/cursoroptions";
SLASH__CURSOR_OPTIONS3 = "/커서";
SLASH__CURSOR_OPTIONS4 = "/커서설정";