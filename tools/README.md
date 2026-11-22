# 생성 도구 (Claude가 그림·맵을 만들 때 쓴 스크립트)

Godot는 이 폴더를 무시합니다(`.gdignore`). 게임 실행에는 필요 없습니다.

| 파일 | 하는 일 |
|---|---|
| `make_sprites.py` | 플레이어 그림 |
| `make_tiles.py` | 타일 15종 그림 (잔디·길·물·나무·바위·덤불·울타리·나무바닥·벽·밭·자갈) |
| `make_ui.py`, `make_items.py`, `make_enemies.py` | 공격 버튼·칼 효과, 하트·코인, 슬라임 |
| `make_prologue.py` | 미지의 존재, 속성 구슬 |
| `make_village_art.py` | 집 3채, 우물·가구, 포탈, NPC(엄마·아빠·이웃) |
| `build_frames.gd`, `build_slime_frames.gd` | 애니메이션(SpriteFrames) |
| `build_tileset.gd` | 타일셋 + 충돌 모양 |
| `build_maps.gd` | **우리 집**, **자갈 마을** 맵 생성 |
| `build_map.gd` | (옛 도구) 바위 숲 최초 생성용 — 실행 금지 |

⚠️ `build_maps.gd`를 다시 실행하면 `house.tscn`, `village.tscn`이 덮어써집니다. Godot 에디터에서 맵을 직접 고친 뒤에는 실행하지 마세요.
