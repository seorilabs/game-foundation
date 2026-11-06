# ui_kit 그린 스킨 독립 검수 6회차(2차 후보 3회차)

- 저장소: seorilabs/game-foundation, 브랜치 feat/ui-kit-painted-skin
- 후보 SHA: f710bbd83e260e16b148d87c0a7d0457515f4cbf (이전 후보 10a8765 → 보정 커밋 dbdf2ae·b18d004·b30aa31·697605e와 잠금 갱신)
- 전환 전 기준: c25effba44197c14bd190e17f3a4b0e98d627660 (568x320으로 직접 캡처해 비교)
- 검수자: 독립 검수 에이전트 6 (구현자, 1~5회차 검수자와 다름)
- 일시: 2026-11-06
- 환경: 격리 worktree, 개발 환경(Godot 4.7.2 headless 렌더 캡처), 저장소 파일 수정·커밋 없음
- 범위: 844x390과 568x320 캡처, 기능 검사, 코드·자산 검토. check.py 묶음에 포함된 캠프 프로브(568x320)와 내비게이션 프로브(320x568)도 함께 봤다
- 설계: docs/design/2026-11-06-ui-kit-painted-skin/design.md AC-2~AC-5·AC-7, runtime-review.md, 이전 기록 docs/qa/ui-kit-painted-review/round-3.md

## 검수 계획

1. 설계 AC와 3회차 결함 D1~D10을 읽고, 이번 회차는 결함 해소 확인을 중심에 둔다. 3회차 표에는 D9가 없어(D1~D8, D10) 9건을 재확인한다.
2. 격리 worktree에서 import 뒤 `check.py --capture`를 844x390과 568x320으로 돌려 ok와 시나리오 수를 적는다. D1(svg 경로)은 깨끗한 checkout에서 check.py가 끝까지 도는지로 판단한다.
3. ui-kit.json 상시 모션 4건, 단위 테스트, bundle verify 파일 수, ui_gate 8항목을 확인한다.
4. 코드·자산: skin.json margins·content를 잘라낸 PNG 치수와 그림 테두리(3배 확대, margins·content 선 겹쳐 보기)로 대조, theme_builder RowPanel·axis, juice.gd idle_pulse resized 연결 중복·shine await 뒤 해제(헤드리스 프로브로 직접 실행), `_clear` 여백, art/ 구성·manifest 기록, 묶음 파일 수와 ui-reference.png 크기.
5. 두 크기 캡처 전부(camp·navigation·scroll-boundary 포함)를 보고, 568x320에서 보이는 문제는 기준 c25effb 같은 크기 캡처로 신규·기존을 가른다.
6. 결함은 실패 시나리오로 적고 취향·추측은 뺀다.

## 실행 명령과 결과

| 단계 | 명령 | 결과 |
|---|---|---|
| worktree | `git worktree add <경로> f710bbd` | 성공(detached) |
| import | `godot --headless --path godot --import --quit-after 2` | exit 0, ERROR 0 |
| 검증기 844x390 | `python3 tools/check.py --capture --size 844x390 --out build/qa-round-6` | **ok true**, scenarios 10, exit 0 |
| 검증기 568x320 | `python3 tools/check.py --capture --size 568x320 --out build/qa-round-6b` | **ok true**, scenarios 10, exit 0 |
| journey.json | 두 크기 모두 | 10개 시나리오 passed(startup-gates … late-server-response-preserves-navigation), mode rendered. camp(568x320) 1개 passed, navigation(320x568) 3개 passed. godot-*.log에 ERROR·SCRIPT ERROR 없음 |
| ui-kit.json | 두 크기 모두 | 47 checks, failed 0, passed true. `ambient motion: idle pulse moves`, `ambient motion: shine band exists`, `ambient reduced: idle pulse stays still`, `ambient reduced: shine band absent` PASS |
| 단위 테스트 | `python3 -m unittest discover -s tools -p 'test_*.py'` | 19 tests OK |
| 묶음 | `python3 tools/bundle.py verify` | ok true, version 1.1.0, files 85, source commit 697605e |
| UI 게이트 | `ui_gate.py --root . --project godot` | 8항목 PASS |
| 기준 캡처 | c25effb worktree에서 `check.py --capture --size 568x320` | ok true, 10 scenarios(비교용) |
| juice 프로브 | `godot --headless -s <scratch>/juice_probe.gd` (저장소 밖 스크립트) | 아래 (c) |

캡처 복사본: gf-round-6-captures/ (qa-round-6 50장, qa-round-6b 50장 중 PNG 합계 100장, baseline-c25effb-568x320/ 비교 캡처, base-vs-6b.png 비교 시트, 팝업 프레임 3배 확대 시트, check·gate 로그).

## 이전 결함 재확인

| ID | 3회차 내용 | 이번 결과 | 근거 |
|---|---|---|---|
| D1 | ui_kit_probe가 삭제된 icon_coin.svg를 load해 check.py가 exit 1 | **해소** | 깨끗한 worktree에서 두 크기 모두 check.py ok true. probe·camp_home 모두 `.png` 경로 |
| D2 | 순위 행이 panel 텍스처에 눌려 갈색 막대, 내 줄 글자 안 보임 | **해소** | leaderboard-around.png(844·568): "126 Aurora 18900 pts"가 RowPanel(보조 플랭크)에서 읽히고, 내 줄은 어두운 칩 판 위 밝은 글자+외곽선 |
| D3 | 지원코드 입력란이 어두운 띠, 코드가 테두리와 겹침 | **해소** | support.png(844·568): 밝은 나무판 입력란에 `SK-7H2K9X4Q`가 선명. panel 텍스처를 148x149로 줄이고 margins 20/20/20/22로 낮춰 54px 높이에도 가운데 면이 남는다 |
| D4 | 팝업 위·아래 띠 리벳이 844 폭에서 3.5배 타원 | **해소** | popup_frame axis가 tile·tile. 844 폭 모달 위 띠에서 가죽끈 고정부와 리벳이 같은 간격으로 반복되고 늘어난 타원이 없다. 568·320 폭도 같다 |
| D5 | 844x390 튜토리얼 Skip guide가 아래 띠 위에 겹침 | **해소** | tutorial.png(844x390): Skip guide 플랭크가 아래 띠 위쪽에 들어가며 겹치지 않는다(여백이 상하 60 → 46/48). 568x320에서는 Skip이 화면 밖인데 기준 c25effb도 같아 기존 문제로 분류 |
| D6 | 버튼 PNG 투명 여백으로 보이는 판이 작고 캠프 탭 캡션이 판 밖 | **해소** | 8장 모두 opaque bbox가 캔버스 전체(투명 여백 0). home.png 플랭크가 컨트롤 높이 전부를 덮는다. camp-title.png: 탭 캡션("계정"…)이 플랭크 안, 아이콘 약 25px로 식별 가능 |
| D7 | 최소 폭 80px 버튼 글자가 리벳 위에 겹침, 토글 글자가 리벳에서 시작 | **해소** | title-ready.png(844·568): Settings 글자가 리벳 안쪽. large-text-ko·camp-settings: "큰 글자", "음악"이 왼쪽 리벳 오른쪽에서 시작. margins 18·content 16/14로 글자 영역이 리벳 밖 |
| D8 | idle_pulse가 레이아웃 전 호출돼 pivot (0,0) | **해소** | juice 프로브: 컨테이너 안 버튼에 호출 시 size (41,48) → 레이아웃 뒤 (400,48), pivot (200,24) centered true. resized 연결이 중복 호출에도 1개 |
| D10 | 320 폭 모달 제목 "Purcha/ses", "Setting/s" 두 줄 | **해소** | navigation/*.png(320x568): "Purchases", "Settings" 한 줄. 프레임 226px·content 22, 뒤로·닫기 폭 44 |

## 기능 결과

- AC-2: theme.tres가 PNG 9분할(StyleBoxTexture)로 조립되고 단위 테스트 19개 통과, check.py가 깨끗한 checkout에서 두 크기 모두 ok.
- AC-3: 844x390·568x320 캡처에서 9분할 이음매·줄무늬·모서리 왜곡 없음. 팝업 프레임 타일 반복과 칩 가로 타일 이음매가 보이지 않는다. 큰 글자(ko) 토글 행 글자가 판 안.
- AC-4: 상시 모션 4건 PASS. reduced_motion이면 배율 1, Shine 띠 없음.
- AC-5: 아이콘 7종 128x128, 놋쇠 테두리·나무·가죽의 같은 화풍. 캠프 탭 25px에서 여우·상점·우편·클래퍼·나침반·톱니가 구분된다.
- 여정 10개, 캠프 1개, 내비게이션 3개, 스크롤 경계 모두 passed. 보상 3단계(anticipation·impact·settle)에서 오른쪽 연출 열이 프레임 안에 있고 코인 아이콘·"+10"·"coins"가 읽힌다(844·568 모두).
- ui_gate 8항목 PASS, 묶음 무결성 ok(85파일).

## 코드·자산 검토

(a) skin.json과 PNG(3배 확대에 margins 선·content 선을 겹쳐 확인)

| 텍스처 | PNG | margins | content | minimum | 판정 |
|---|---|---|---|---|---|
| button_primary 3상태 | 150x82, 투명 여백 0 | 18,14,18,16 | 16,6,16,8 | 56x44 | 모서리 리벳(약 8~15px)과 상단 하이라이트·하단 림이 margins 안. content 선이 리벳 안쪽이라 글자가 리벳과 겹치지 않는다 |
| button_secondary 2상태 | 148x78, 투명 여백 0 | 18,14,18,16 | 14,6,14,8 | 48x40 | 같음. disabled는 primary_disabled 공용 |
| panel | 148x149, 투명 여백 0 | 20,20,20,22 | 14,10,14,12 | 44x44 | 놋쇠 테두리(약 12~15px)와 리벳이 margins 안. 가운데 면이 108x107이라 48·54px 행에서도 면이 남는다 |
| popup_frame | 226x226, 투명 여백 0 | 44,44,44,46 | 22,34,22,36 | 96x96 | 놋쇠 모서리 캡(약 37px)은 margins 안. 띠의 가죽끈 고정부 하나가 x 43~58에 걸쳐 타일 구간에 포함되지만 tile 반복이라 캡처에서 간격이 고르고 이음매가 보이지 않는다 |
| chip | 94x48, 투명 여백 0 | 24,8,24,8 | 20,2,20,2 | 56x36 | 양 끝 놋쇠 캡(약 15px)이 margins 안. 가로 tile, 세로 stretch |

(b) theme_builder: `axis` 배열을 읽어 tile이면 `AXIS_STRETCH_MODE_TILE`, 기본은 stretch. `RowPanel` 변형이 `button_secondary` normal 텍스처로 PanelContainer 판을 그린다. focus 색은 skin.json `focus`(기본 #286778). 문제 없음.

(c) juice.gd(헤드리스 프로브로 실행)
- `idle_pulse`: `center_pivot` 즉시 호출 후 `resized.is_connected(center_pivot.bind(node))`로 중복을 막는다. 같은 노드에 idle_pulse 2회 + float_loop 1회를 불러도 resized 연결 1개. 레이아웃 뒤 pivot이 가운데. Tween은 `node.create_tween()`으로 노드에 묶여 노드가 해제되면 함께 끝난다. 다만 같은 노드에 두 번 부르면 Tween이 두 개 돌아 배율이 겹친다(현재 호출부는 노드당 1회라 발생하지 않음, 관찰).
- `shine`: 크기 0이면 `await process_frame` 뒤 band·node에 접근한다. 같은 프레임에 `queue_free`한 경우와 띠 Tween 진행 중 `queue_free`한 경우 모두 4프레임 뒤까지 오류 로그 없음(band가 node의 자식이라 함께 해제되고, 해제된 뒤 접근은 await 다음 줄 한 번뿐인데 queue_free는 프레임 끝에 실행돼 그 줄이 먼저 돈다). `is_instance_valid` 가드는 없으나 현재 경로에서 실패 시나리오를 재현하지 못했다.
- `float_loop`는 scale 숨쉬기 별칭(3회차와 같음, 수용).

(d) `_clear` 여백: 타이틀·홈은 가로 0, 세로 28/12|26. 모달은 `max(기본, 16*scale, 12 + 프레임 content)` = 좌우 34, 상하 46/48. 844x390에서 내용 영역 높이 296px이라 튜토리얼(Skip 포함)이 들어간다. 모달 본문 글자가 x 34에서 시작해 안쪽 가죽끈(약 x 30)과 겹치지 않는다. 뒤로·닫기 버튼 폭은 폭 360 미만 세로에서 44.

(e) art/: `asset-manifest.json`, `style/style-guide.md`, `style/ui-reference.png`(762x1366, 1,551,665바이트)뿐이고 raw는 없다. manifest에 model `gemini-3-pro-image`, anchor 경로, 자산별 prompt·aspect_ratio·final_canvas·refs가 있다. 라이선스·출처 필드는 없다(생성 모델과 입력 기록으로 추적은 가능). manifest의 `final_canvas`는 b30aa31 이전 크기(160x90, 256, 320, 96x54)라 잘라낸 현재 PNG(150x82, 148x78, 148x149, 226x226, 94x48)와 다르고 잘라내기 단계가 기록돼 있지 않다(D11).

(f) 묶음: 85파일(기준 82). svg 15개 삭제, png 15개 추가, art 3개 추가. `ui-reference.png` 1.5MB가 공통 묶음과 Godot import 대상에 포함돼 소비 게임마다 설치된다(3회차와 같은 관찰).

## UX 결과

844x390(가로, 50장)과 568x320(50장)을 봤고, 568x320은 기준 c25effb 캡처와 나란히 비교했다.

- 타이틀·오류·로딩: 금빛 플랭크 주 버튼과 disabled 구분, Settings 버튼 글자가 플랭크 안. 두 크기 모두 기준과 배치가 같다.
- 홈(hero·map·world): 재화 칩(가죽 알약, 그린 코인, + 플랭크), 목적지 띠(칩 판 위 밝은 글자), 주 버튼 숨쉬기 적용. 플랭크가 컨트롤 높이 전부를 덮어 3회차처럼 작아 보이지 않는다. 568x320 home.png에서 재화 10일 때 "Setting/s"가 두 줄인데 기준 c25effb도 같다(기존 문제).
- 모달 프레임: 가죽 띠와 놋쇠 캡, 띠의 리벳·고정부가 같은 간격으로 반복된다. 844·568·320 폭 모두 늘어난 타원 없음. 본문·버튼이 띠와 겹치지 않는다.
- 순위: 행이 밝은 플랭크 위에 읽히고 내 줄은 어두운 칩에 밝은 글자. 비어 있음·실패·오프라인·종료·미등록 문구 정상.
- 지원코드: 밝은 입력란에 코드가 선명, Copy code 주 버튼.
- 결과(보상): 3단계 모두 오른쪽 연출 열이 프레임 안. 568x320에서 설명 문구가 두 줄로 접히지만 겹침 없음.
- 튜토리얼: 844x390은 Skip guide가 프레임 안. 568x320은 Skip guide가 화면 아래로 잘리는데 기준도 같다(기존 문제).
- 설정·접근성·우편함·구매·복원·오퍼: 토글 행·목록 버튼·스크롤·disabled 상태 정상. 글자가 리벳에 걸치지 않는다.
- 캠프(568x320): 재화 칩, 주 버튼, 내 계정·설정 버튼 정상. 하단 탭 6개 캡션이 플랭크 안, 아이콘 약 25px로 식별 가능.
- 내비게이션(320x568): 제목 한 줄, 초점 테두리 보임, 늦은 콜백 전후 화면 정상.

## 결함

| ID | 심각도 | 구분 | 실패 시나리오 | 근거 |
|---|---|---|---|---|
| D11 | 낮음 | 자산 기록, 신규 | 설계의 재생성 절차대로 `--only ui_panel --force`를 돌리면 manifest `final_canvas` 256x256으로 투명 여백이 있는 PNG가 나오고, skin.json의 148x149 기준 margins(20/20/20/22)가 어긋나 D6(투명 여백)이 되돌아온다. 잘라내기 단계가 manifest나 style-guide에 없다 | asset-manifest.json final_canvas vs 실제 PNG 치수, b30aa31 커밋 |

기존 문제(전환 전부터, 기준 c25effb 568x320 캡처로 확인): 568x320 세로 프로필에서 재화 두 자리일 때 홈 머리말 "Settings"가 두 줄로 꺾임, 568x320 튜토리얼 Skip guide가 화면 아래로 잘림. 둘 다 이 스킨 변경과 무관하고 설계 범위의 크기(320x568·390x844·844x390, 가로는 캠프 프로필)가 아니다.

관찰(결함 아님): `ui-reference.png` 1.5MB 공통 묶음 포함, manifest 라이선스 필드 없음, `shine`에 `is_instance_valid` 가드 없음(재현 실패), 같은 노드에 idle_pulse를 두 번 부르면 Tween 중복(현재 호출부 없음).

## 판정

**pass**

근거: 3회차 결함 9건(D1~D8, D10)이 모두 해소됐다. 깨끗한 checkout에서 check.py가 두 크기 모두 ok true·10 시나리오 passed이고, 상시 모션·단위 테스트·묶음·게이트가 통과했다. 코드 검토에서 idle_pulse의 resized 연결 중복과 shine의 해제 뒤 접근을 헤드리스로 직접 실행해 오류가 없음을 확인했다. 남은 D11은 재생성 절차의 기록 결함이라 실행 화면에 영향이 없고, manifest에 잘라낸 치수(또는 crop 단계)를 적는 후속으로 처리하면 된다. 568x320에서 보인 두 건은 전환 전과 같은 기존 문제다.
