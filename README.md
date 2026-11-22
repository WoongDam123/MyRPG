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

## 캐릭터 그림 (32px 손그림 도트 · 종이 인형)
- 용사는 **장비 칸마다 따로 그린 레이어**를 겹쳐 만든다 (`scripts/paper_doll.gd`, 그림: `assets/hero/`, 생성기: `tools/make_paperdoll.py`)
  - `body`(피부·얼굴·평상복) · `hair` · `armor_<방어구 id>` · `weapon_<무기 id>`(등에 멘 칼 / 공격할 때 손에) · `acc_<장신구 id>` · `cape_<직업 id>`
  - 장비를 바꾸면 그 레이어만 바뀐다 → 평상복 / 가죽옷 / 철 갑옷, 맨손 / 목검 / 철검, 증표, 직업 망토
  - 새 장비를 추가하려면: `make_paperdoll.py`에 그리기 함수 추가 → `armor_<id>.png` 같은 이름으로 저장 → `GameState.ITEMS`에 아이템 추가
- 칸 구성: 32x32, 가로 9칸(대기 0-1 · 걷기 2-5 · 공격 6-8) × 세로 4줄(아래·왼쪽·오른쪽·위)
- NPC도 같은 방식의 32px (머리 모양·수염·앞치마·옷 색만 다르게)

## 프로젝트 설정 메모
- 렌더러: Compatibility (저사양 휴대폰 호환)
- 기준 해상도 640×360, stretch `canvas_items` / `expand`
- 가로 화면 고정, 텍스처 필터 Nearest (픽셀 아트)

## 파일 구조
- `scenes/prologue.tscn`, `scripts/prologue.gd` — **시작 장면**: 미지의 존재, 속성 선택
- `scripts/autoload/game_state.gd` — 전역 `GameState`: **모든 게임 데이터 표** (아이템·상점·퀘스트·스킬·직업) + 진행 상태 (레벨·경험치·가방·장비·스킬·직업·퀵슬롯·퀘스트·기록)
- `scripts/autoload/transition.gd` — 전역 `Transition`: 페이드 화면 전환 + 자막
- `scenes/ui/dialogue_box.tscn`, `scripts/ui/dialogue_box.gd` — 대화창 (한 글자씩, 터치/Space로 넘김)
- `scripts/ui/starfield.gd` — 반짝이는 우주 배경
- `scenes/maps/` — 맵들: 우리 집 · 자갈 마을 · 창고 · 잡화점 · 바위 숲 · 버려진 광산 · 광산 깊은 곳 · 대지의 제단
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
- `scenes/slime.tscn`, `scripts/slime.gd` — 모든 적의 기본 (어슬렁 → 추격, 넉백, 경험치, 아이템 드롭, 재등장, 보스 돌진)
- `scenes/enemies/` — 바위 슬라임 · 단단한 슬라임 · 킹슬라임(보스) · 대지의 수호자(시련 보스) — slime.tscn을 물려받아 그림·능력치만 바꿈
- `scenes/projectile.tscn` — 석영 술사의 수정 탄환
- `scripts/trial.gd` — 전직의 시련 (웨이브 3단계 → 직업 선택)
- `scripts/ui/` — `inventory.gd`(가방) · `shop.gd`(상점) · `skill_tree.gd`(스킬 창) · `job_choice.gd`(전직) · `ui_kit.gd`(창 꾸미기 공통)
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
- [x] 서장-3: 심부름① 장비 장착 + 자동 사냥·퀘스트 자동 이동
- [x] 서장-4: 심부름② 잡화점에서 물약 사기 (상점: 구매·판매)
- [x] 서장-5: 심부름③ 물약 퀵슬롯 등록
- [x] 서장-6: 성인식 (촌장, 자갈 마을의 증표) → 마을 밖 개방
- [x] 레벨·경험치·스킬 포인트, 스킬 창 (돌진·대지 베기·단단한 몸)
- [x] 첫 임무: 버려진 광산 (열쇠 → Lv 5 → 킹슬라임 보스) → 대지의 결정
- [x] 전직의 시련 (Lv 10, 대지의 제단, 3단계 웨이브) → **1차 전직** (화강 기사 / 강철 투사 / 석영 술사)
- [ ] 다음: 저장·불러오기, 2차 전직을 향한 그라니아 본편

## 조작
| 기능 | 휴대폰 | 키보드 |
|---|---|---|
| 이동 | 왼쪽 조이스틱 | 방향키 / WASD |
| 공격·대화 (누르고 있으면 연속 공격) | 칼 버튼 | Space / J |
| 스킬 1 (돌진) · 스킬 2 (직업 스킬) | 칼 버튼 옆 원형 버튼 | K · L |
| 퀵슬롯 물약 | 물약 버튼 | Q |
| 가방 · 스킬 창 | 오른쪽 위 버튼 | I(Tab) · U |
| 퀘스트 자동 이동 | 오른쪽 위 "목표" 누르기 | – |
| 자동 사냥 | "자동" 버튼 | – |

## 맵 연결도
```
우리 집 ── 자갈 마을 ──(성인식 후)── 바위 숲 ──── 버려진 광산 ──(열쇠 + Lv5)── 광산 깊은 곳(보스)
            │   │                       │
          창고  잡화점                  대지의 제단 (전직 시련)
```
새 맵을 추가하면 `scripts/autoload/story.gd`의 `MAP_LINKS`에도 연결을 적어 주세요 (자동 이동 길찾기용).
