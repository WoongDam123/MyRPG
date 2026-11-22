extends Node
## 게임 전체에서 공유하는 정보 (장면이 바뀌어도 유지된다).
## 프로젝트 설정 → 전역(Autoload)에 "GameState"로 등록되어 있어서 어디서든 GameState.attribute 처럼 쓸 수 있다.

## 세 가지 근원 에너지(속성) 정보
const ATTRIBUTES := {
	"solid": {
		"name": "Solid",
		"title": "대지의 힘",
		"desc": "대지·광물·강철의 힘.\n높은 체력과 방어, 묵직한 근접 공격.\n시작 왕국: 그라니아",
		"kingdom": "그라니아",
		"unlocked": true,
	},
	"liquid": {
		"name": "Liquid",
		"title": "흐름의 힘",
		"desc": "물·흐름·생명의 힘.\n빠른 연속 공격과 회복.\n시작 왕국: 아쿠아리스",
		"kingdom": "아쿠아리스",
		"unlocked": false,
	},
	"cosmo": {
		"name": "Cosmo",
		"title": "별의 힘",
		"desc": "별·중력·우주 에너지의 힘.\n멀리서 쏘는 에너지 공격, 낮은 체력.\n시작 왕국: 아스트라",
		"kingdom": "아스트라",
		"unlocked": false,
	},
}

var attribute: String = ""  ## 플레이어가 고른 속성 ("solid" / "liquid" / "cosmo")
var player_name: String = "용사"
