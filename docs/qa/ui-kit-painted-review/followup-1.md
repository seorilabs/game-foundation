# 그린 스킨 후속 보정 독립 검수

- 검수자: 독립 검수 에이전트(구현자와 다르고, 1~6회차 검수자와도 다름)
- 저장소: seorilabs/game-foundation, 브랜치 fix/ui-kit-skin-followups
- 후보 SHA: 03db1ea9a7b87d2fd64c206f5a49414101385512 (코드 커밋 23e2c01, 그 뒤 잠금 갱신 03db1ea). 기준 main 860bae0
- 크기 4개: 390x844, 320x568, 844x390, 568x320. check.py에 묶인 캠프 프로브는 568x320, 내비게이션 프로브는 320x568, scroll-boundary 프로브는 390x844로 고정이다
- 실행 시각: 2026-11-06 10:17~10:40 UTC
- 실행 환경: macOS 개발 환경, 격리 worktree(새 체크아웃, import 캐시 없음), Godot 4.7.2.stable(headless와 렌더 캡처), Python 3과 Pillow, npm
- 격리 저장: check.py가 만드는 격리 저장소를 썼다. 검수용 임시 프로브 2개는 저장소 밖 스크립트이고 `user://` 임시 저장 파일을 만든 뒤 지웠다. 저장소 파일 수정과 커밋은 없다(검수 뒤 git status에 추적 파일 변경 0건)
- 비교 기준: 이전 후보 f710bbd 캡처(NAS1dual `agent-artifacts/game-foundation/2026-11-06/f710bbd83e260e16b148d87c0a7d0457515f4cbf/ui-kit-painted-review-rounds-4-6/`, 390은 round-4, 320은 round-5, 844와 568은 round-6). 캠프 칩 회귀 확인에는 기준 main 860bae0을 별도 worktree로 띄워 같은 임시 프로브를 돌렸다
- 증거 사본: 캡처 폴더 `gf-fu-qa-captures/`(4크기 캡처 전부, `extra/`에 재현 결과, 확대 crop, 이전 후보 비교 시트, 상점 열림 캠프 캡처, 실행 로그, 임시 프로브 스크립트)

## 검수 계획

설계 "v2 후속 보정" 절의 결함 4건이 실제로 사라졌는지, 그리고 보정이 새 결함을 만들지 않았는지를 바뀐 표면(팝업 프레임 테두리와 나뭇결 면, 재화 칩 타일, 캠프 재화 칩) 중심으로 본다.

1. 기능: 새 체크아웃에서 import 뒤 `check.py --capture`를 4크기로 돌려 ok와 시나리오 수를 적는다. journey 10개와 camp, navigation, scroll-boundary 하위 여정, ui-kit 47항목, ui-contract 87항목, 로그 오류를 본다. `npm test`, `bundle.py verify`, `ui_gate.py`를 돌린다.
2. 재현성(D11): NAS raw로 `skin_postprocess.py`를 새 빈 폴더에 돌려 15장을 커밋된 PNG와 픽셀 비교한다. manifest의 postprocess와 final_canvas를 skin.json margins와 대조한다. main 860bae0의 PNG와도 비교해 이번에 바뀐 텍스처를 가린다.
3. 코드: `tileable`(구간 시작과 모서리 끝 섞기), theme_builder `tile_fit`, camp_home 칩 글자 줄이기와 (+) 44px 하한, camp_probe와 test_ui_kit의 새 검사를 읽는다. 새 검사가 실패할 수 있는 조건인지 확인하고, 필요하면 저장소 밖 임시 프로브로 직접 잰다.
4. UX: 4크기 캡처 전부를 보고, 팝업 프레임이 있는 모달(설정, 우편, 지원, 순위, 결과, 오퍼, 튜토리얼)과 캠프 홈은 이전 후보 캡처와 나란히 본다. 위·아래·좌·우 띠의 끈 맞붙음과 리벳 뭉침, 나뭇결 면의 세로·가로 이음매(열·행 밝기 차 측정), 모서리 조각과 첫 타일 경계, 재화 칩 타일 경계, 캠프 칩 (+) 크기를 확인한다.
5. 결함은 실패 시나리오로 적고, 이전 후보와 같은 것은 기존 문제로 가른다.

## 실행 명령과 결과

모든 명령은 격리 worktree 안에서 실행했다.

| 단계 | 명령 | 결과 |
|---|---|---|
| worktree | `git worktree add <격리 경로> 03db1ea9a7b87d2fd64c206f5a49414101385512` | 성공, detached HEAD. 원격 main은 860bae0으로 기준과 같음 |
| import | `godot --headless --path godot --import --quit-after 2` | exit 0, 오류 0건(로그의 "error"는 `error.wav` 파일명뿐) |
| 390x844 | `python3 tools/check.py --capture --size 390x844 --out build/qa-fu-390` | exit 0, ok true, scenarios 10, 32초 |
| 320x568 | `python3 tools/check.py --capture --size 320x568 --out build/qa-fu-320` | exit 0, ok true, scenarios 10, 38초 |
| 844x390 | `python3 tools/check.py --capture --size 844x390 --out build/qa-fu-844` | exit 0, ok true, scenarios 10, 51초 |
| 568x320 | `python3 tools/check.py --capture --size 568x320 --out build/qa-fu-568` | exit 0, ok true, scenarios 10, 59초 |
| 하위 결과 | 4크기 공통 | journey 10/10 passed, camp 1/1, navigation 3/3, scroll-boundary 1/1. ui-kit.json 47항목 실패 0, ui-contract.json 87항목 실패 0, automated.json 17항목 true. 로그 40개에 SCRIPT ERROR, ERROR, WARNING 없음. 크기마다 PNG 36장 |
| 단위·E2E | `npm test` | exit 0. unittest 23개 OK(이전 19개 + skin_postprocess 3개 + manifest 대조 1개), 이어서 check.py ok true, scenarios 10 |
| 묶음 | `python3 tools/bundle.py verify` | ok true, version 1.1.0, source commit 23e2c01, files 82(이전 85). 잠금에 `art/` 경로 없음 |
| UI 게이트 | `python3 ~/.agent/skills/game-ui-commercial/scripts/ui_gate.py --root . --project godot` | 8항목 PASS(display_font, painted_skin, popup_motion, button_sfx, reward_ceremony, particles, hud_layers, currency_chip) |
| 재현성 | `python3 tools/skin_postprocess.py --manifest art/skins/soft_adventure/asset-manifest.json --raw <NAS raw> --out <새 빈 폴더>` | exit 0, 15장 생성(아래 재현성 절) |
| 임시 프로브 1 | `godot --headless --path godot --script <저장소 밖>/camp_plus_probe.gd` | 상점이 열린 캠프 홈을 3크기 x 재화 문자열 4종 x 큰 글자 2종으로 재서 (+) 크기, 칩 폭, 자리 폭, 글자 크기를 출력 |
| 임시 프로브 2 | `godot --path godot --script <저장소 밖>/camp_plus_capture.gd -- --out <scratch> --size 568x320` | 후보와 기준 860bae0에서 각각 상점 열림 캠프 홈 3장 캡처 |

## 재현성

NAS1dual `agent-artifacts/game-foundation/2026-11-06/4e9c7aa0fc820c9f80ebb8ed18878bc90aadba82/ui-kit-painted-skin-raw/raw`를 입력으로 새 빈 폴더에 후처리를 돌렸다. 결과 15장(버튼 5, 패널, 팝업 프레임, 칩, 아이콘 7)이 `godot/addons/seorilabs_game/skins/soft_adventure/`의 같은 이름 파일과 크기가 같고, Pillow `ImageChops.difference`의 bbox가 15장 모두 None이다. 즉 픽셀이 완전히 같다. 설계는 "버튼과 아이콘이 같다"고 적었지만 실제로는 패널, 팝업 프레임, 칩까지 전부 같다.

main 860bae0의 PNG와 비교하면 버튼 5장과 아이콘 7장은 픽셀이 같고, 바뀐 것은 세 장이다.

| 텍스처 | 바뀐 범위 | 해석 |
|---|---|---|
| ui_popup_frame.png 226x226 | 전 영역. 알파가 다른 픽셀 2,167개(바깥 윤곽 안티에일리어싱) | 의도한 변경. tileable이 x·y 50~74 부근과 150~168 부근을 섞음 |
| ui_chip.png 94x48 | x 18~29만 | 의도한 변경. 왼쪽 모서리 끝 6px와 구간 시작 6px |
| ui_panel.png 148x149 | 9,782픽셀, 그러나 프리멀티플라이 차이가 8 미만 9,570개, 8~15 12개 | 도구로 다시 만든 결과의 미세 차이로 눈에 보이지 않는다. 설계 표에 적히지 않은 변경이라 사실로만 적는다 |

manifest와 skin.json 대조:

| 자산 | manifest postprocess | skin.json | 판정 |
|---|---|---|---|
| ui_popup_frame | chroma_key, trim_alpha, tileable margins [62,62,62,62], axes h·v, band 24, k_band 4, k_face 12 | margins [62,62,62,62], axis tile_fit·tile_fit | 일치 |
| ui_chip | chroma_key, trim_alpha, crop_to [1360,765], tileable margins [24,8,24,8], axes h, k_face 6 | margins [24,8,24,8], axis tile_fit·stretch | 일치 |
| 버튼 5장, 패널 | chroma_key, trim_alpha(버튼은 crop_to 포함) | margins는 최종 PNG 기준 | 비교 대상 없음 |
| final_canvas | 160x90, 160x160, 240x240, 96x54 | 실제 최종 PNG는 150x82, 148x78, 148x149, 226x226, 94x48 | 잘라내기 전 크기가 그대로이고 실제 최종 크기는 manifest에 없다. 도구에는 `expect_size` 검사가 있지만 어느 자산에도 적혀 있지 않다(결함 F4) |

## 이전 결함 재확인

| 이전 ID | 내용 | 이번 결과 | 근거 |
|---|---|---|---|
| N1(4회차) | 팝업 위·아래 띠 타일 경계에서 가죽 끈 두 개가 맞붙고 리벳 4개가 뭉침, 나뭇결 면 세로 밝기 단차 | 해소 | 4크기 모든 모달에서 끈 고정부는 모서리 바로 옆에만 있고 띠 가운데에 맞붙은 끈이 없다(390 settings-ko 위·아래 띠 2.5배, 568 camp-settings 위·아래 띠 2배, 844 large-text-ko 1.5배 비교). 위 띠 리벳 간격은 390에서 58~63px로 고르다 |
| 5회차 결함 1 | 나뭇결 면 세로 타일 경계 | 해소 | 빈 면 영역 열 밝기 차 최댓값: 390 ranking-empty 1.06(중앙값의 3.4배, 이전 4.45로 12배), 320 ranking-empty 1.13(이전 5.12), 844 large-text-ko 0.80(이전 5.69, 경계 6곳 모두 9배 이상). 새 최댓값 위치는 타일 경계가 아닌 오른쪽 모서리 조각 안쪽 결이며 이전 후보에도 같은 값(약 1.0)이 있다. 텍스처 자체에서도 구간 끝→시작 차가 0.47로 이웃 열 중앙값 0.41과 같은 수준이다(이전 4.66) |
| 4회차 O4 | 내 순위 줄(칩 텍스처 가로 tile)에 타일마다 어두운 세로 띠 | 해소 | 390 leaderboard-around 128 Mira 줄 아래쪽 가죽 열 차: 이전은 x 103, 149, 195, 241, 287에서 4.37(9.3배), 이번 최댓값 1.15(2.9배) |
| D11(6회차) | manifest final_canvas가 잘라내기 전 크기라 재생성 시 margins 어긋남, 잘라내기 단계 기록 없음 | 대부분 해소, 잔여 F4 | 후처리 단계가 `tools/skin_postprocess.py`와 manifest `postprocess`에 기록됐고 NAS raw로 15장이 픽셀 단위로 재현된다. 투명 여백이 되돌아오는 원래 실패 시나리오는 trim_alpha 기록으로 막혔다. 실제 최종 크기 기록은 빠졌다 |
| 6회차 관찰 | ui-reference.png 1.5MB와 생성 기록이 공통 묶음에 포함 | 해소 | bundle verify files 82(85에서 art 3개 빠짐), 잠금에 art 경로 없음, 생성 기록은 저장소 루트 `art/skins/soft_adventure/`. `test_painted_skin_record_matches_skin_json`이 `skins/soft_adventure/art`가 없음을 검사한다. manifest anchor 상대 경로 `../../../godot/reference/assets/soft-adventure.png`가 실제 파일로 풀린다 |
| starter 9회차 N-3 | 568x320 캠프 홈에서 긴 재화 문자열로 칩이 줄면 (+) 37px | (+) 하한은 동작, 새 회귀 F1과 검증 공백 F2 | 임시 프로브(상점 열림): 후보는 568x320, 844x390, 1280x720에서 문자열 길이와 무관하게 (+) 44px 이상. 기준 860bae0은 같은 조건에서 (+) 34px(짧은 문자열), 23px(긴 문자열). 대신 후보는 칩이 자리 폭을 넘는다(아래 F1) |

## 코드 검토

(a) `tileable`(tools/skin_postprocess.py). 가로 축은 행마다 두 단계를 거친다. 왼쪽 모서리 조각의 마지막 k열을 구간 끝 k열 쪽으로 점점 섞어 마지막 열(l-1)을 원래 구간 끝 열(W-r-1)과 같게 만들고, 구간 시작 k열은 오른쪽 모서리 조각의 첫 k열(구간 끝 너머 원래 이웃 픽셀)에서 원래 값으로 넘어가게 섞는다. 그래서 구간 끝→다음 구간 시작은 원래 이어져 있던 W-r-1→W-r 쌍과 같아지고, 모서리 끝→첫 구간 시작도 같은 쌍이 된다. 마지막 구간→오른쪽 모서리는 원래 이웃이라 그대로 이어진다. 세로 축은 가로 처리 결과를 같은 방식으로 섞는데, 섞는 가중치가 열마다 같으므로 가로 연속성이 유지된다. 읽는 구간과 쓰는 구간이 겹치려면 구간 폭이 k보다 작아야 하는데 팝업 102px(k 12), 칩 46px(k 6)이라 해당 없다. 텍스처 측정으로 팝업 가로 면 0.47, 세로 면 0.86(이웃 중앙값 0.41, 0.88), 위 여백 행 1.10, 칩 가로 0.71(중앙값 0.54)을 확인했다. 단위 테스트는 가로 그라데이션 한 경우만 본다(세로 축과 band 행은 테스트 없음, 관찰).

(b) theme_builder `tile_fit`. `_axis_mode`가 "tile"은 TILE, "tile_fit"은 TILE_FIT, 나머지는 STRETCH를 돌려준다. Godot의 TILE_FIT은 반복 횟수를 반올림한 정수(최소 1)로 정하고 타일을 그만큼 늘이거나 줄여 마지막 타일이 잘리지 않는다. 그 결과 390 폭 모달은 가로 2타일(119px, 원본 102px의 1.17배), 320 폭은 2타일(84px, 0.82배)로 그려지고 리벳이 타원이 되지 않는 것을 캡처로 확인했다. theme.tres는 axis_stretch 2와 margins 62로 재생성됐다. skin.json `minimum`(96→128)은 코드에서 읽지 않는 기록값이다. `Panel` 테마 형식도 popup_frame을 쓰므로 높이나 폭이 124px보다 작은 Panel은 모서리가 겹친다. 킷 안에서는 전체 화면 backing만 Panel이라 지금은 해당 없다(소비 게임 관찰).

(c) camp_home 칩. 지연 호출에서 숫자 글자를 2px씩 줄이며 칩 최소 폭이 자리 폭 이하가 될 때까지 반복하고, 그래도 넘치면 `clampf(slot / have, 44/56, 1)`로 칩을 줄인다. (+)의 최소 크기가 56이라 배율 하한 0.786에서 (+)는 44px가 된다. 이 하한 때문에 넘친 칩은 자리 폭 밖으로 나간다(F1). 반복 조건이 `font_size > 12`이고 2씩 줄여서 시작 크기가 홀수면 11까지 내려간다(F3).

(d) camp_probe 새 단계. `not add.visible or add.get_global_rect().size.y >= 43.9`인데 참조 캠프 프로브는 commerce port를 넣지 않아 `commerce.available()`이 false이고 `show_add`도 false다. (+)가 숨겨진 상태라 이 단계는 항상 통과하고, 표시되는 숫자 56은 숨겨진 버튼의 `custom_minimum_size`다(캡처 camp-title.png에도 (+)가 없다). 같은 프로브의 "currency chip fits its slot (161 <= 164)"도 상점이 닫힌 경우만 본다(F2).

(e) test_ui_kit `test_painted_skin_record_matches_skin_json`. tileable이 있는 자산의 margins와 axis 접두어만 skin.json과 대조한다. 버튼과 패널은 크기와 margins를 대조할 기록이 manifest에 없어 검사하지 않는다(F4와 같은 원인).

(f) 문서. 설계 v1 본문 14·32행은 옛 경로 `skins/soft_adventure/art/`를 그대로 적고 있으나 v2 후속 보정 절이 이동을 적어 두었다(관찰). agent-config `game-ui-commercial/references/godot-kit.md`는 axis 값으로 `tile`만 안내한다. `tile_fit` 안내는 이 저장소 범위 밖 후속이다(관찰).

## UX 결과

4크기 캡처 144장(크기마다 루트 27, camp 4, navigation 5, scroll-boundary 1)을 모두 봤다. 모달 7종과 캠프 홈·캠프 모달은 이전 후보 캡처와 나란히 비교했다.

- 팝업 프레임(설정, 우편, 지원, 순위 5상태, 결과 3단계, 오퍼, 튜토리얼, 구매·복원, 접근성, 캠프 설정·계정, 내비게이션 3종): 4크기 모두 위·아래·좌·우 띠에 맞붙은 끈이 없고 리벳이 뭉치지 않는다. 나뭇결 면에 세로 이음매가 보이지 않는다. 모서리 놋쇠 캡에서 첫 타일로 넘어가는 자리가 매끄럽다(390 ranking-empty 왼쪽 위, 오른쪽 아래, 왼쪽 띠 4배 확대). 이전 후보의 오른쪽 아래 모서리 위쪽 이중 끈도 사라졌다. content margins가 그대로라 제목, 버튼, 본문 위치는 이전 후보와 같고 바뀐 것은 프레임 그림뿐이다.
- 재화 칩(홈 4크기, 캠프): 가죽 면에 타일 경계 띠가 보이지 않는다. 홈 칩의 열 밝기 차 상위값은 (+) 버튼 가장자리(x 111~117)뿐이다. 목적지 띠 "WINDWARD ISLES, STAGE 12"는 이전 후보와 측정값이 같다.
- 캠프 홈(참조 구성, 상점 닫힘): 칩, 모험 시작, 내 계정·설정, 하단 탭 6개가 이전 후보와 같다. (+)는 상점이 없어 보이지 않는다.
- 캠프 홈(상점 열림, 임시 프로브): (+) 44px. 긴 문자열과 두 줄 헤드라인에서 겹침(F1).
- 관찰 1, 나뭇결 판 폭: 세로 반복 구간 [62,164)에 판 경계선이 81행과 151행 두 줄 있어, 반복하면 판 폭이 약 31px와 69px로 번갈아 나온다(390 ranking-empty 판 경계 260, 291, 360, 391, 460, 490, 559, 590, 659, 690행). 이전 후보는 65~71px로 고르다. 이음매가 아닌 원본 그림의 판 경계라 결함으로 적지 않는다.
- 관찰 2, 리벳 간격: 위 띠는 거의 고르다(텍스처 48/54px). 아래 띠는 텍스처 39/63px, 좌우 띠는 42/60px라 반복하면 리벳이 두 개씩 묶여 보인다(568 캠프 설정 아래 띠 약 40/65px). 뭉침(맞붙음)은 아니다.
- 기능 화면 흐름: 설정 토글, 언어, 지원코드, 구매 대기·복원, 우편 수령·만료, 순위 5상태, 보상 3단계, 튜토리얼, 키보드 초점 테두리, 늦은 콜백 전후 화면이 이전 후보와 같다.

기존 문제(이전 후보 f710bbd 같은 크기 캡처와 동일, 이번 변경 책임 아님):

- map 홈 "13 Locked"가 "13 / Locke / d"로 꺾이고 "12 Lost lighthouse" 위에 겹친다(390, 320).
- 568x320 홈 머리말 "Setting / s" 두 줄, 568x320 튜토리얼 Skip guide가 화면 아래로 잘림, 568x320 leaderboard-around에서 목록 행이 보이지 않고 내 기록 칩만 보임.
- 보상 연출 중 Reward 라벨과 코인이 Continue·View leaderboard 위에 겹친다(연출이 끝나면 사라짐).
- scroll-boundary 프로브 화면은 회색 기본 테마다(스킨 비대상).

## 결함

| ID | 심각도 | 구분 | 실패 시나리오 | 근거 |
|---|---|---|---|---|
| F1 | 중간 | UX, 신규(이번 칩 보정이 만든 회귀) | 568x320 캠프 홈에서 상점이 열려 있고(commerce에 purchase 가능 port) 재화 문자열이 "★ 1,234,567    🎟 99,999"인 상태로, en 로캘에서 오류 안내가 헤드라인에 뜨면("Could not complete this action. Try" / "again.") 둘째 줄 "again."이 칩의 (+) 버튼 위에 겹쳐 + 글자를 가린다. 칩 폭이 242px로 자리 폭 164px를 넘어 헤드라인 열(x 206부터)까지 들어가기 때문이다. 짧은 문자열 "★ 10    🎟 2"도 상점이 열리면 칩이 175px로 자리를 11px 넘는다. 기준 main 860bae0은 같은 조건에서 칩을 164px 안에 맞춰 겹치지 않았다(대신 (+) 23px). 헤드라인 라벨은 입력을 받지 않아 (+)는 눌리지만 버튼이 글자에 가려 보인다. 기대: (+) 44px 이상을 지키면서 칩이 헤드라인과 겹치지 않는다 | 캡처 `extra/camp-shop-candidate/camp-shop-long-error.png`(후보), `extra/camp-shop-base-860bae0/camp-shop-long-error.png`(기준), 확대 `extra/zoom/camp-shop-error.png`, `extra/zoom/camp-shop-base-vs-new.png`. 임시 프로브 수치: 568x320 문자열 11·23·35·47자에서 칩 175·243·316·389px, 자리 164px, 칩 배율 0.786, 글자 12px |
| F2 | 중간 | 검증 공백, 신규 | 누군가 camp_home의 `clampf` 하한을 지워 N-3(배율 0.66, (+) 37px)을 되돌려도 camp_probe와 check.py가 통과한다. 참조 캠프 프로브는 상점이 없어 (+)가 숨겨져 있고, 새 단계는 `not add.visible`로 바로 참이 된다. 단계 이름에 찍히는 56은 숨겨진 버튼의 최소 크기다. 같은 프로브의 "fits its slot"도 상점이 닫힌 경우만 보므로, 상점을 열면 이 단계가 175 > 164로 실패해 F1을 잡았을 것이다. 설계 표의 "`camp_probe`가 (+) 크기를 검사한다"가 실제로는 검사되지 않는다 | `godot/tests/reference/camp_probe.gd` 47~48행, `outgame_main.gd` 348행 `chip.show_add = commerce.available()`, camp-title.png에 (+) 없음, 임시 프로브 수치 |
| F3 | 낮음 | 코드, 신규 | 844x390 캠프 홈에서 상점이 열리고 칩이 넘치면 숫자 글자가 시작 17px에서 15, 13, 11px로 내려가 설계와 주석이 말하는 하한 12px 아래가 된다. 반복 조건이 `font_size > 12`이고 2씩 빼기 때문에 시작 크기가 홀수면 항상 11에서 멈춘다 | 임시 프로브 844x390 출력 value_font=11, `camp_home.gd` 112~114행 |
| F4 | 낮음 | 자산 기록, D11 잔여 | 설계 절차대로 ui_panel이나 버튼을 새로 생성하고 후처리하면, 잘라낸 결과가 이전 크기(148x149, 150x82)와 달라져도 도구는 오류를 내지 않고 test_ui_kit도 통과한다. skin.json margins(패널 20/20/20/22, 버튼 18/14/18/16)가 무엇을 기준으로 적혔는지 manifest에서 알 수 없어 어긋남은 눈으로만 찾는다. 설계는 "manifest에 실제 최종 크기 ... 적는다"고 했는데 final_canvas는 잘라내기 전 크기 그대로이고 `expect_size`는 어느 자산에도 없다 | asset-manifest.json final_canvas 값과 실제 PNG 크기, `skin_postprocess.py` `expect_size` 분기 |

관찰(결함 아님): 나뭇결 판 폭 31/69px 교차, 아래·좌우 띠 리벳 간격 1.5~1.6배 교차, ui_panel.png 미세 재처리 차이, `Panel` 형식의 최소 그림 크기 124px, tileable 단위 테스트가 가로 축만 봄, 설계 v1 본문의 옛 art 경로, 스킬 문서의 axis 안내에 tile_fit 없음.

## 판정

**fail**

근거:

- 기능: 새 체크아웃에서 4크기 check.py가 모두 ok true, scenarios 10이고 하위 여정, ui-kit 47항목, ui-contract 87항목, npm test(unittest 23개 포함), bundle verify(82파일), ui_gate 8항목이 모두 통과했다.
- 보정 4건 중 3건은 해소됐다. 팝업 프레임의 끈 맞붙음과 나뭇결 면 이음매(N1, 5회차 결함 1)와 칩 타일 경계(O4)는 4크기 캡처와 열 밝기 차 측정으로 사라진 것을 확인했다. 후처리는 NAS raw로 15장이 픽셀 단위로 재현되고(D11, 잔여 F4 낮음), 생성 기록은 공통 묶음에서 빠졌다.
- fail 사유는 네 번째 보정(캠프 칩 (+) 44px)이다. (+) 하한 자체는 동작하지만, 그 대가로 상점이 열린 568x320에서 칩이 자리 폭을 넘어 두 줄 헤드라인과 겹치는 회귀(F1)가 생겼다. 이 경로를 저장소의 camp_probe가 검사하지 못해 새 단계가 숨겨진 버튼으로 통과한다(F2). N-3이 나온 starter처럼 상점과 긴 재화 문자열을 쓰는 소비 게임이 바로 이 조건이다.
- 재검수 조건: camp_probe가 상점이 열린 상태(purchase 가능 port)와 긴 재화 문자열, 두 줄 헤드라인으로 (+) 44px 이상과 칩·헤드라인 비겹침(또는 칩이 자리 폭 이내)을 함께 검사해 통과하고, 568x320과 844x390 캠프 캡처에서 겹침이 없을 것. F3(하한 11px)은 같은 보정에서 고치고, F4는 manifest에 `expect_size`를 적는 것으로 닫을 수 있다. 팝업 프레임과 칩 텍스처는 재검수 범위에서 빼도 된다.
