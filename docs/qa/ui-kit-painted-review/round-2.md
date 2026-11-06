# ui_kit 그린 스킨 독립 검수 2회차

- 대상: seorilabs/game-foundation, 브랜치 feat/ui-kit-painted-skin
- 후보 SHA: 10a8765d29cdbeb4561fbd8a3ca47ecc7fa506d7
- 기준(전환 전) SHA: 925cc8c629f58b9619d1b8fc7972a326714e341a
- 설계: docs/design/2026-11-06-ui-kit-painted-skin/design.md (AC-1~AC-7), runtime-review.md
- 회차 크기: 320x568(작은 세로). 캠프 probe는 도구 고정값 568x320
- 검수자: 구현자·1회차 검수자와 다른 에이전트. 저장소 파일은 수정하지 않았다
- 환경: 격리 worktree, Godot 4.7.2.stable, 격리 저장 경로(journey가 만드는 임시 경로)
- 날짜: 2026-11-06

## 검수 계획

작은 세로 화면에서 두꺼운 팝업 프레임과 그린 텍스처가 내용 공간·글자·터치 영역을 해치지 않는지를 중점으로 본다.

1. 기능: `check.py --capture --size 320x568` 전체 통과 여부, journey 10개 시나리오 status, `ui_kit_probe`의 상시 모션 검사(AC-4), 단위 테스트 `test_ui_kit.py`(AC-2), `bundle.py verify`, `ui_gate.py` 8항목.
2. 팝업 프레임: 띠 64px·content 44/48이 320px 폭에서 남기는 내용 폭(계산상 320 − 2×(12+44) = 208px)으로 제목·탭·목록이 읽히는지. 전환 전과 같은 크기에서 비교하기 위해 기준 SHA도 같은 320x568로 캡처한다.
3. 버튼: 최소 높이 48, 터치 영역, 9분할 이음매·줄무늬·모서리 왜곡.
4. 큰 글자(150%)에서 글자가 플랭크 밖으로 나가는지(`large-text-ko`).
5. 칩: 높이 40에서 알약 찌그러짐, 코인 아이콘·숫자·(+) 배치.
6. 캠프 가로(568x320) 아이콘 PNG 전환 결과(`camp_home.gd`가 svg→png로 바뀜).
7. 모든 PNG(camp, navigation, scroll-boundary 포함)를 하나씩 보고, 전환 전 캡처와 비교해 기존 문제와 새 결함을 구분한다.

## 실행 명령과 결과

| 단계 | 명령 | 결과 |
|---|---|---|
| import | `godot --headless --path godot --import --quit-after 2` | exit 0 |
| 전체 검사 | `python3 tools/check.py --capture --size 320x568 --out build/qa-round-2` | **exit 1**. 3번째 probe `ui_kit_probe.gd`에서 `ERROR: Resource file not found: res://addons/seorilabs_game/skins/soft_adventure/icon_coin.svg` (`ui_kit_probe.gd:152`). probe 자체는 "47 checks, 0 failed"지만 check.py가 ERROR 줄을 실패로 판정해 멈추므로 journey·캡처가 만들어지지 않는다. ok 없음, scenarios 없음 |
| 나머지 수동 실행 | check.py가 실행하는 나머지 명령을 같은 인자로 직접 실행(`outgame_journey.gd --size 320x568 --capture`, `accounts_probe`, `account_services_probe`, `e2e_scroll_probe`, `camp_probe --size 568x320`, `ui_navigation_probe`) | 모두 exit 0, 로그에 ERROR 0건 |
| journey.json | 시나리오 status | 10/10 passed (startup-gates, first-play-reward-and-replay, settings-support-language-restart, inbox-read-claim-scroll, commerce-pending-reconcile-restore, leaderboard-states-and-pagination, shared-version-product-hooks, save-corruption-and-guide-recovery, server-claim-batches-and-failure, late-server-response-preserves-navigation). camp 1/1, scroll-boundary 1/1, navigation 3/3 passed |
| ui-kit.json | `ui_kit_probe` | checks 47, failures 0, passed true. ambient(idle_pulse·shine) 검사 reduced/normal 모두 포함 |
| 단위 테스트 | `python3 -m unittest discover -s tools -p 'test_*.py'` | 19 tests OK |
| 묶음 | `python3 tools/bundle.py verify` | ok true, version 1.1.0, files 85, source commit 30999e7 |
| 게이트 | `ui_gate.py --root . --project godot` | 8항목 모두 PASS |
| 기준 비교 | 기준 SHA 925cc8c를 별도 worktree에 받아 `outgame_journey.gd --size 320x568 --capture` | 26장 캡처. 전환 전 320x568 캡처가 없어 직접 만들었다 |

캡처 36장(루트 26, camp 4, scroll-boundary 1, navigation 5)과 기준 캡처 26장, 확대 crop을 캡처 폴더에 두었다.

## 기능 결과

- AC-2: 단위 테스트는 통과한다. 그러나 `npm test`(= unittest + `tools/check.py`)는 새로 받은 checkout에서 `check.py`가 `icon_coin.svg` 로드 오류로 실패한다. 로컬 작업 저장소에는 gitignore된 `icon_coin.svg.import`가 남아 있어 삭제된 svg가 캐시로 로드되므로 구현자 환경에서는 재현되지 않았을 것으로 본다(사실: 주 저장소에 `skins/soft_adventure/*.svg.import` 16개가 남아 있다). CI는 `check_command: npm test`를 쓰므로 그대로 올리면 required check가 깨진다.
- AC-3: 320x568 캡처에서 9분할 이음매·줄무늬·모서리 왜곡은 없다. 큰 글자(`large-text-ko`)에서 토글 행 글자가 플랭크 안에 있다.
- AC-4: 상시 모션 검사 통과(ui-kit.json). 홈 캡처에서 주 버튼이 정상 위치·크기로 보이고 화면 전환 뒤 Tween 오류 로그 없음.
- journey 10개, navigation 3개, camp 1개, scroll-boundary 1개 모두 passed. 설정·우편·구매·순위·지원코드 흐름은 동작한다.
- 버튼 최소 높이: 모달의 보조 버튼 48px, 홈 하단 탭 44px(minimum 56x44 계약) 유지. 뒤로(‹)·닫기(×) 버튼 52px 폭 유지.
- 칩: 높이 40에서 알약 찌그러짐 없음. 코인 아이콘·숫자·(+) 플랭크가 가죽 알약 안에 들어간다.

## UX 결과

- 홈(hero·map·world)은 시안 A의 재질(가죽 칩, 자작나무 플랭크, 금빛 주 버튼)로 바뀌었고 320 폭에서도 목적지 띠·Set out·하단 탭이 겹치지 않는다.
- 타이틀 화면의 Preparing 상태 비활성 주 버튼(회색 플랭크)과 준비 완료 금빛 버튼이 구분된다.
- 보상 3단계 연출(ceremony)은 그린 코인 아이콘으로 바뀌었고 열이 화면 안에 있다.
- 320 폭 모달은 프레임 띠가 양쪽 56px(12+44)씩 차지해 내용 폭이 전환 전 256px에서 208px로 줄었다. 이 폭 손실이 아래 결함 2·3·4의 공통 원인이다. 설정(ko) 같은 짧은 한국어 제목과 한 줄 버튼은 문제없다.

## 결함

새 결함(전환으로 생김)

1. [기능, 차단] 새 checkout에서 `tools/check.py`가 실패한다.
   - 재현: 브랜치를 새 worktree로 받고 import 뒤 `python3 tools/check.py --capture --size 320x568`.
   - 결과: `ui_kit_probe.gd:152`가 삭제된 `icon_coin.svg`를 `load`해 `ERROR: Resource file not found`가 찍히고 check.py가 exit 1로 멈춘다. journey·캡처·검증 결과(ok, scenarios)가 만들어지지 않는다. CI의 `npm test`도 같은 경로로 실패한다.
   - 기대: probe가 `icon_coin.png`(또는 skin.json의 icons.coin)를 쓰고 check.py가 끝까지 돈다.

2. [UX] 320 폭 모달 제목이 단어 중간에서 줄바꿈된다.
   - 재현: 320x568 영어로 설정, 지원코드, 구매, 순위, 결과 화면을 연다(캡처 navigation/commerce-completed, support, purchase-pending, leaderboard-around, reward).
   - 결과: "Setting / s", "Suppor / t code", "Purcha / ses", "Leader / board", "Expedit / ion / comple / te"(4줄). 결과 화면은 4줄 제목 때문에 ‹·× 버튼이 세로로 길게 늘어난다. 기준 SHA 같은 크기에서는 "Support / code", "Expedition / complete"처럼 공백에서만 줄바꿈되고 Settings·Purchases는 한 줄이었다.
   - 원인(코드 근거): 헤더 HBox = 52px 버튼 + 제목 + 52px 버튼 + separation 8×2이고, 내용 폭 208px에서 제목에 약 96px만 남는다. 25px 표시 서체의 "Settings"가 그보다 넓다.
   - 기대: 320 폭에서도 제목이 단어 단위로만 줄바꿈된다(예: 작은 폭에서 프레임 content 여백을 줄이거나 제목 서체를 줄이는 보정).

3. [UX] 320x568 순위 화면에서 순위 목록이 한 행도 보이지 않는다.
   - 재현: 순위 화면 "Around me"(캡처 leaderboard-around).
   - 결과: 제목 2줄, 탭 4개가 각각 2줄("All / time", "This / week", "Top / scores", "Around / me")로 커지고 프레임 상하 여백(12+48)이 더해져 스크롤 목록 높이가 약 30px만 남는다. 첫 행 플랭크의 윗부분만 보이고 이름·점수 글자는 보이지 않는다. 스크롤바가 있어 기능은 되지만 사용자가 자기 순위 주변을 보려면 스크롤해야 한다. 기준 SHA 같은 크기에서는 2.5행(126 Aurora, 127 Parker, 128 Mira)이 보였다.
   - 기대: 적어도 2행이 스크롤 없이 보인다.

4. [UX] 지원코드 값의 첫 글자가 플랭크 리벳 위에 겹친다.
   - 재현: 지원코드 화면(캡처 support, crop support-code).
   - 결과: 읽기 전용 입력란이 플랭크 텍스처를 쓰는데 "SK - 7H2K9X4Q"가 플랭크 폭을 꽉 채워 "S"가 왼쪽 리벳과 겹친다. 사용자가 상담에 읽어 줄 값이라 첫 글자 오독 위험이 있다. 기준 SHA에서는 필드 안에 여유가 있었다.
   - 기대: 코드 전체가 리벳 안쪽 판 위에 놓인다.

5. [UX] 캠프 가로(568x320) 하단 내비 버튼의 캡션이 플랭크 아래로 넘치고 아이콘이 읽히지 않는다.
   - 재현: camp probe 568x320(캡처 camp/camp-title, crop camp-nav-new-4x, camp-inbox-8x).
   - 결과: 계정·상점·우편함·광고 보상·운영·설정 캡션의 글자 아랫부분이 플랭크의 그려진 하단 테두리를 벗어나 배경 위에 걸친다. 버튼 텍스처(160x90)의 위아래 약 6~8px가 투명·그림자 영역이라 컨트롤 rect보다 그려진 판이 작은데, `camp_home.gd`는 캡션을 컨트롤 높이의 53~93% 위치에 둔다. 같은 버튼의 20px 아이콘은 그린 PNG(128px)를 축소한 것이라 봉투·톱니 같은 형태가 아니라 갈색 덩어리로 보인다. 기준 캡처(선 아이콘 svg)는 캡션이 판 안에 있고 아이콘이 식별된다.
   - 기대: 캡션이 판 안에 들어가고 아이콘이 20px에서도 종류를 알아볼 수 있다.

기존 문제(전환 전부터 있음, 이번 변경의 책임 아님)

- map 홈의 "13 Locked" 잠긴 스테이지 버튼이 "13 / Lock / ed"로 단어 중간에서 줄바꿈된다(기준 SHA 320x568에서도 동일). 참조 제품 `reference/bootstrap/main.gd`가 폭을 지정하지 않은 결과.
- 순위 "My best record" 행이 어두운 칩 위에 어두운 글자라 읽기 어렵다. 기준 SHA도 어두운 청록 칩에 어두운 글자였다. 다만 새 스킨에서 홈 목적지 띠에는 밝은 글자·외곽선 보정을 넣었으므로 같은 보정을 `ChipPanel` 행에도 적용하면 함께 해결된다.
- 우편함 카드에 카드 판이 없고 글자가 패널 위에 바로 놓인다(기준 SHA 동일).
- scroll-boundary probe 화면은 회색 기본 테마다(기준 동일, 스킨 비대상).

## 판정

**fail**

- 근거 1(기능): 설계가 정한 검증 명령 `check.py`가 후보 SHA의 새 checkout에서 실패하고(결함 1), CI `npm test`도 같은 이유로 실패한다. 이 상태에서는 AC-3의 캡처 증거를 계약 명령으로 만들 수 없다.
- 근거 2(UX): 320x568은 설계의 명시 검증 크기인데, 두꺼운 프레임 띠로 줄어든 내용 폭 때문에 영어 모달 제목이 단어 중간에서 깨지고(결함 2) 순위 목록이 보이지 않는다(결함 3). 두 가지는 기준 SHA에서 없던 회귀다.
- 결함 4·5는 단독으로는 pass를 막지 않지만 같은 수정 회차에서 함께 고치는 것이 맞다.
- AC-4(상시 모션)·AC-2 단위 테스트·bundle·ui_gate·journey 10/10은 통과했다.
- 재검수 조건: 결함 1~3을 고친 새 후보 SHA에서 `check.py --capture --size 320x568`이 ok로 끝나고, 위 다섯 화면(설정·지원코드·구매·순위·결과)의 영어 320x568 캡처에서 제목이 단어 단위로 줄바꿈되며 순위 목록 2행 이상이 보이는 것.
