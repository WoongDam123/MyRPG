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
- [ ] 4단계: 맵 (타일맵, 충돌, 카메라)
- [ ] 5단계: 전투 (공격, 적 AI, 체력)
- [ ] 6단계: UI와 아이템
- [ ] 7단계: 안드로이드 휴대폰에 설치

## 프로젝트 설정 메모
- 렌더러: Compatibility (저사양 휴대폰 호환)
- 기준 해상도 640×360, stretch `canvas_items` / `expand`
- 가로 화면 고정, 텍스처 필터 Nearest (픽셀 아트)

## 파일 구조
- `scenes/main.tscn` — 메인 화면 (잔디 배경 + 플레이어)
- `scenes/player.tscn` — 플레이어 (CharacterBody2D + AnimatedSprite2D + 충돌 박스)
- `scripts/player.gd` — 플레이어 이동·애니메이션·공격 코드
- `scenes/hud.tscn` — 모바일 조작 화면 (VirtualJoystick + 공격 TouchScreenButton)
- `assets/ui/`, `assets/effects/` — 공격 버튼, 칼 휘두르기 효과 그림
- `assets/sprites/player.png` — 플레이어 그림 (16×16, 4방향 × 3프레임 임시 그림)
- `assets/sprites/player_frames.tres` — 애니메이션 묶음 (idle_*/walk_* × down/left/right/up)
- 입력 액션: `move_left/right/up/down` (방향키 + WASD + 조이스틱), `attack` (Space/J + 공격 버튼)
- PC 테스트용: 마우스로 터치 흉내내기 켜짐 (`input_devices/pointing/emulate_touch_from_mouse`)
