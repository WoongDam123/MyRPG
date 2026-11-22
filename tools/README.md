# 생성 도구 (Claude가 그림·맵을 만들 때 쓴 스크립트)

Godot는 이 폴더를 무시합니다(`.gdignore`). 게임 실행에는 필요 없습니다.

| 파일 | 하는 일 |
|---|---|
| `make_paperdoll.py` | **32px 손그림 도트 용사 레이어**(몸·머리·갑옷 2종·무기 2종·직업 망토 3종·증표)와 NPC 6명 |
| `make_sprites.py` | (옛) 16px 플레이어 — 옛 NPC 생성기에서 재사용 |
| `make_tiles.py` | 타일 17종 그림 (잔디·길·물·나무·바위·덤불·울타리·나무바닥·벽·밭·자갈·동굴 바닥·동굴 벽) |
| `make_ui.py`, `make_items.py`, `make_enemies.py` | 공격 버튼·칼 효과, 하트·코인, 슬라임 |
| `make_prologue.py` | 미지의 존재, 속성 구슬 |
| `make_village_art.py` | 집 3채, 우물·가구, 포탈, NPC(엄마·아빠·이웃) |
| `make_errand_art.py` | 창고 건물, 짐 상자·건초·보물 상자, 아이템 아이콘, 가방 버튼 |
| `make_chapter_art.py` | 촌장·대지의 정령, 상점 카운터, 제단, 바위·단단한·킹슬라임, 골렘, 열쇠·결정·증표 아이콘, 스킬 아이콘, 수정 탄환, 충격파 |
| `build_enemy_frames.gd` | 새 적들의 애니메이션 |
| `build_frames.gd`, `build_slime_frames.gd` | 애니메이션(SpriteFrames) |
| `build_tileset.gd` | 타일셋 + 충돌 모양 |
| `build_maps.gd` | 우리 집 · 자갈 마을 · 창고 · 잡화점 · 버려진 광산 · 광산 깊은 곳 · 대지의 제단 맵 생성 |
| `build_map.gd` | (옛 도구) 바위 숲 최초 생성용 — 실행 금지 |

⚠️ `build_maps.gd`를 다시 실행하면 위 7개 맵 파일이 덮어써집니다 (바위 숲은 제외). Godot 에디터에서 맵을 직접 고친 뒤에는 실행하지 마세요.
