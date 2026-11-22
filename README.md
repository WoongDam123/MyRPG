# MyRPG

Godot 4.7.2로 만드는 모바일(안드로이드) 탑뷰 액션 RPG.

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
- [ ] 6단계: UI와 아이템
- [ ] 7단계: 안드로이드 휴대폰에 설치

## 프로젝트 설정 메모
- 렌더러: Compatibility (저사양 휴대폰 호환)
- 기준 해상도 640×360, stretch `canvas_items` / `expand`
- 가로 화면 고정, 텍스처 필터 Nearest (픽셀 아트)

## 파일 구조
- `scenes/main.tscn` — 메인 화면: Ground(바닥 타일) / World(y-sort: Obstacles 타일 + Player) / HUD
- `scripts/main.gd` — 카메라 경계 설정, 플레이어 체력 → HUD 연결
- `assets/tiles/tiles.png`, `tileset.tres` — 잔디·꽃·흙길·물·나무·바위·덤불 타일 (물·나무·바위·덤불은 충돌)
- `tools/` — 그림·맵 생성 스크립트 (게임 실행과 무관)
- `scenes/player.tscn` — 플레이어 (CharacterBody2D + AnimatedSprite2D + 충돌 박스)
- `scripts/player.gd` — 플레이어 이동·애니메이션·공격·체력(피격, 무적, 사망)
- `scenes/slime.tscn`, `scripts/slime.gd` — 슬라임 적 (어슬렁 → 추격, 넉백, 사망)
- `scenes/hud.tscn` — 모바일 조작 화면 (VirtualJoystick + 공격 TouchScreenButton + 안내 문구)
- `assets/ui/`, `assets/effects/` — 공격 버튼, 칼 휘두르기 효과 그림
- `assets/sprites/player.png` — 플레이어 그림 (16×16, 4방향 × 3프레임 임시 그림)
- `assets/sprites/player_frames.tres` — 애니메이션 묶음 (idle_*/walk_* × down/left/right/up)
- 입력 액션: `move_left/right/up/down` (방향키 + WASD + 조이스틱), `attack` (Space/J + 공격 버튼)
- PC 테스트용: 마우스로 터치 흉내내기 켜짐 (`input_devices/pointing/emulate_touch_from_mouse`)

## 충돌 레이어
| 번호 | 이름 | 누가 |
|---|---|---|
| 1 | 지형 | 물·나무·바위·덤불 타일 |
| 2 | 플레이어 | Player 몸 |
| 3 | 적 | Slime 몸 |

- 플레이어 `AttackHitbox`(공격 판정)와 `Hurtbox`(피격 판정)는 3번(적)을 감지
- 플레이어는 적과 몸으로 부딪히지 않고 통과하지만, 닿으면 피해를 받음
