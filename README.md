# 코스모 가이아 (MyRPG)

Godot 4.7.2로 만드는 모바일(안드로이드) 탑뷰 액션 RPG. 기획은 [docs/기획서.md](docs/기획서.md) 참고.

## 열어 보는 방법
1. GitHub Desktop으로 이 저장소를 Clone(처음) 또는 Pull(이후)
2. Godot 4.7.2 → 가져오기(Import) → 이 폴더의 `project.godot` 선택
3. ▶ (F5) 실행

## 개발 단계
- [x] 1단계: 개발 환경 준비 (모바일 화면 설정)
- [x] 2단계: 캐릭터 띄우고 움직이기 (방향키/WASD, 4방향 걷기 애니메이션)
- [x] 3단계: 모바일 조작 (가상 조이스틱, 공격 버튼)
- [x] 4단계: 맵 (타일맵, 충돌, 카메라)
- [x] 5단계: 전투 (공격, 적 AI, 체력)
- [x] 6단계: UI와 아이템 (하트 체력, 코인, 아이템 드롭)
- [ ] 7단계: 안드로이드 휴대폰에 설치

## 프로젝트 설정 메모
- 렌더러: Compatibility (저사양 휴대폰 호환)
- 기준 해상도 640×360, stretch `canvas_items` / `expand`
- 가로 화면 고정, 텍스처 필터 Nearest (픽셀 아트)

## 파일 구조
- `scenes/prologue.tscn`, `scripts/prologue.gd` — **시작 장면**: 미지의 존재, 속성 선택
- `scripts/autoload/game_state.gd` — 전역 `GameState`: 속성, 체력·코인, **아이템 목록·가방·장비·공격력/최대체력 계산**, 퀘스트 상태, 자동 기능 상태, 다음 도착 위치, 이야기 기록(flags)
- `scripts/autoload/transition.gd` — 전역 `Transition`: 페이드 화면 전환 + 자막
- `scenes/ui/dialogue_box.tscn`, `scripts/ui/dialogue_box.gd` — 대화창 (한 글자씩, 터치/Space로 넘김)
- `scripts/ui/starfield.gd` — 반짝이는 우주 배경
- `scenes/maps/` — 맵들: `house.tscn`(우리 집) · `village.tscn`(자갈 마을) · `barn.tscn`(창고) · `rock_forest.tscn`(바위 숲)
  - 모든 맵 구조: Ground(바닥 타일) / World(y-sort: Obstacles 타일, 건물·가구, NPC, 포탈, Player) / Spawns / HUD
- `scripts/map.gd` — 모든 맵 공통: 포탈 도착 위치 배치, 카메라 경계(작은 맵은 가운데), HUD 연결, 첫 방문 이벤트 대사
- `scenes/portal.tscn`, `scripts/portal.gd` — 포탈: `portal_id` ↔ `target_map` + `target_portal`로 짝을 맞춤
- `scenes/npc.tscn`, `scripts/npc.gd` — NPC: 가까이 가면 `!` 표시, 공격 버튼으로 대화 (`story_id`가 있으면 Story가 상황별 대사 결정)
- `scripts/autoload/story.gd` — 전역 `Story`: NPC 상황별 대사, 퀘스트 진행, **현재 목표**, 맵 연결(자동 이동 길찾기용)
- `scenes/chest.tscn`, `scripts/chest.gd` — 보물 상자 (한 번만 열림, 특정 퀘스트 중에만 열리게 가능)
- `scripts/auto_pilot.gd` — Player의 자동 조종: **퀘스트 자동 이동**(맵을 넘어 포탈 경유) + **자동 사냥**(적 추적·공격·아이템 줍기)
- `scripts/ui/inventory.gd` — 가방·장비창 (장착/해제/사용)
- `assets/tiles/tiles.png`, `tileset.tres` — 잔디·꽃·흙길·물·나무·바위·덤불 타일 (물·나무·바위·덤불은 충돌)
- `tools/` — 그림·맵 생성 스크립트 (게임 실행과 무관)
- `scenes/player.tscn` — 플레이어 (CharacterBody2D + AnimatedSprite2D + 충돌 박스)
- `scripts/player.gd` — 플레이어 이동·공격(누르고 있으면 연속)·NPC 대화·체력(피격, 무적, 사망)
- `scenes/slime.tscn`, `scripts/slime.gd` — 슬라임 적 (어슬렁 → 추격, 넉백, 사망 시 아이템 드롭: 하트 25% / 코인 60%)
- `scenes/hud.tscn`, `scripts/hud.gd` — 화면 UI: 하트·코인, **목표 버튼(누르면 자동 이동)**, **가방 버튼**, **자동 사냥 ON/OFF**, 알림, 맵 이름, 대화창, 조이스틱, 공격 버튼
- `scenes/pickup.tscn`, `scripts/pickup.gd` — 바닥 아이템(하트: 체력 +1 / 코인), 12초 후 사라짐
- `assets/items/` — 하트(가득/빈), 코인 그림
- `assets/ui/`, `assets/effects/` — 공격 버튼, 칼 휘두르기 효과 그림
- `assets/sprites/player.png` — 플레이어 그림 (16×16, 4방향 × 3프레임 임시 그림)
- `assets/sprites/player_frames.tres` — 애니메이션 묶음 (idle_*/walk_* × down/left/right/up)
- 입력 액션: `move_left/right/up/down` (방향키 + WASD + 조이스틱), `attack` (Space/J + 공격 버튼), `inventory` (I / Tab)
- PC 테스트용: 마우스로 터치 흉내내기 켜짐 (`input_devices/pointing/emulate_touch_from_mouse`)

## 충돌 레이어
| 번호 | 이름 | 누가 |
|---|---|---|
| 1 | 지형 | 물·나무·바위·덤불 타일 |
| 2 | 플레이어 | Player 몸 |
| 3 | 적 | Slime 몸 |

- 플레이어 `AttackHitbox`(공격 판정)와 `Hurtbox`(피격 판정)는 3번(적)을 감지
- 플레이어는 적과 몸으로 부딪히지 않고 통과하지만, 닿으면 피해를 받음

## 기획 진행 (코스모 가이아 서장)
- [x] 서장-1: 프롤로그 (미지의 존재, 속성 선택)
- [x] 서장-2: 자갈 마을, 우리 집, 부모님·이웃 NPC, 포탈 맵 이동, 연속 공격
- [x] 서장-3: 심부름① 장비 장착 (창고·상자·가방·장비창) + 자동 사냥·퀘스트 자동 이동
- [ ] 서장-4~5: 심부름 튜토리얼 (상점 / 물약 퀵슬롯)
- [ ] 서장-6: 성인식 → 모험 출발

## 맵 연결도
```
우리 집 ──(house_door ↔ home_door)── 자갈 마을 ──(forest_exit ↔ village_exit)── 바위 숲
                                        │
                                  (barn_door ↔ barn_out)
                                        │
                                      창고
```
새 맵을 추가하면 `scripts/autoload/story.gd`의 `MAP_LINKS`에도 연결을 적어 주세요 (자동 이동 길찾기용).
```
```
