# 생성 도구 (Claude가 그림·맵을 만들 때 쓴 스크립트)

Godot는 이 폴더를 무시합니다(`.gdignore`). 게임 실행에는 필요 없습니다.

- `make_sprites.py`, `make_ui.py`, `make_tiles.py` — 픽셀 그림 생성 (Python + Pillow)
- `build_frames.gd` — 플레이어 애니메이션(SpriteFrames) 생성
- `build_map.gd` — 타일셋과 `scenes/main.tscn` 맵 생성

⚠️ `build_map.gd`를 다시 실행하면 `main.tscn`이 덮어써집니다. Godot 에디터에서 맵을 직접 고친 뒤에는 실행하지 마세요.
