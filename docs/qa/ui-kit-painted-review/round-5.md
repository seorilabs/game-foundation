# ui_kit 그린 스킨 독립 검수 5회차(2차 후보 2회차)

- 저장소: seorilabs/game-foundation, 브랜치 feat/ui-kit-painted-skin
- 후보 SHA: f710bbd83e260e16b148d87c0a7d0457515f4cbf (1차 후보 10a8765의 보정 1~3과 순위 행 보정이 포함된 2차 후보)
- 전환 전 기준 SHA: 925cc8c629f58b9619d1b8fc7972a326714e341a (같은 320x568, 568x320으로 직접 캡처해 비교)
- 설계: docs/design/2026-11-06-ui-kit-painted-skin/design.md AC-1~AC-7, runtime-review.md. 이전 기록 docs/qa/ui-kit-painted-review/round-2.md(320x568)
- 회차 크기: 320x568(작은 세로). 캠프 probe는 도구 고정값 568x320, scroll-boundary probe는 도구 고정값 390x844
- 검수자: 독립 검수 에이전트 5(구현자, 1~4회차 검수자와 다름)
- 환경: 격리 worktree, Godot 4.7.2.stable headless와 렌더 캡처, 격리 저장 경로(journey가 만드는 임시 경로). 저장소 파일 수정·커밋 없음
- 날짜: 2026-11-06

## 검수 계획

2회차가 320x568에서 fail로 판정한 다섯 결함이 2차 후보에서 실제로 사라졌는지, 그리고 보정으로 새 결함이 생기지 않았는지를 작은 화면 기준으로 본다.

1. 기능: `check.py --capture --size 320x568`이 새 checkout에서 ok로 끝나는지(2회차 결함 1), journey 10개 시나리오와 camp·navigation·scroll-boundary 시나리오 status, `ui_kit_probe`의 상시 모션 검사(AC-4), 단위 테스트(AC-2), `bundle.py verify`, `ui_gate.py` 8항목.
2. 모달 제목 줄바꿈 위치: 설정, 지원코드, 구매, 순위, 결과(영어)의 제목이 낱말 중간에서 꺾이지 않는지(2회차 결함 2).
3. 순위 목록 보이는 행 수: Around me 화면에서 스크롤 없이 2행 이상 보이는지(2회차 결함 3).
4. 지원코드 가독성: 코드 값이 리벳과 겹치지 않는지(2회차 결함 4).
5. 캠프 가로 탭: 캡션이 판 안에 있고 아이콘 종류를 알아볼 수 있는지(2회차 결함 5).
6. 터치 영역: 모달 머리말 ‹·× 버튼, 행 버튼, 홈 하단 탭의 컨트롤 크기가 44~48 이상인지. 좁은 폭 보정(360 미만에서 머리말 버튼 44px)이 적용된 결과를 실측한다.
7. 큰 글자: `large-text-ko`에서 글자가 플랭크 밖으로 나가지 않는지.
8. 칩·버튼 판 안의 글자: 재화 칩의 코인·숫자·(+), 목적지 띠, 하단 탭 글자가 그려진 판 안에 있는지.
9. 9분할 품질: 이음매·줄무늬·모서리 왜곡. 보정 3이 팝업 프레임을 stretch에서 tile로 바꿨으므로 타일 경계도 본다.
10. 캡처 37장 전부를 보고, 전환 전 기준 캡처와 비교해 기존 문제와 새 결함을 구분한다.

## 실행 명령과 결과

모든 명령은 격리 worktree 안에서 실행했다.

| 단계 | 명령 | 결과 |
|---|---|---|
| worktree | `git worktree add <경로> f710bbd83e260e16b148d87c0a7d0457515f4cbf` | 성공, detached HEAD |
| import | `godot --headless --path godot --import --quit-after 2` | exit 0, ERROR 0건 |
| 전체 검사 | `python3 tools/check.py --capture --size 320x568 --out build/qa-round-5` | **exit 0, ok true**, sourceSha f710bbd…, scenarios 10. godot-0~9 로그 ERROR 0건. 2회차 결함 1(svg 경로) 해소 |
| journey.json | 시나리오 status | 10/10 passed (startup-gates, first-play-reward-and-replay, settings-support-language-restart, inbox-read-claim-scroll, commerce-pending-reconcile-restore, leaderboard-states-and-pagination, shared-version-product-hooks, save-corruption-and-guide-recovery, server-claim-batches-and-failure, late-server-response-preserves-navigation). mode rendered, viewport [320, 568] |
| 하위 journey | camp, navigation, scroll-boundary | camp 1/1, navigation 3/3, scroll-boundary 1/1 passed |
| ui-kit.json | `ui_kit_probe` | checks 47, failures 0, passed true. `ambient motion: idle pulse moves`, `ambient motion: shine band exists`, `ambient reduced: idle pulse stays still`, `ambient reduced: shine band absent` 모두 PASS |
| 단위 테스트 | `python3 -m unittest discover -s tools -p 'test_*.py'` | 19 tests OK |
| 묶음 | `python3 tools/bundle.py verify` | ok true, version 1.1.0, files 85, source commit 697605e |
| 게이트 | `ui_gate.py --root . --project godot` | 8항목 PASS (display_font, painted_skin, popup_motion, button_sfx, reward_ceremony, particles, hud_layers, currency_chip) |
| 기준 캡처 | 기준 SHA 925cc8c worktree에서 `outgame_journey.gd --size 320x568 --capture`, `camp_probe.gd --size 568x320 --capture` | 각 exit 0, 비교용 30장 |

캡처 37장(루트 27, camp 4, navigation 5, scroll-boundary 1)과 기준 캡처 30장, 확대 crop 6장, check.py 표준 출력을 캡처 폴더 `gf-round-5-captures/`에 두었다(baseline-925cc8c/, zoom-crops/ 하위).

## 이전 결함 재확인

| 2회차 결함 | 2회차 결과(10a8765) | 이번 결과(f710bbd) | 판정 |
|---|---|---|---|
| 1. 새 checkout에서 `check.py` 중단(`ui_kit_probe.gd:152`가 삭제된 `icon_coin.svg` load) | exit 1, journey·캡처 없음 | probe가 `icon_coin.png`를 쓰고 check.py가 끝까지 돌아 ok true, scenarios 10 | 해소 |
| 2. 320 폭 모달 제목 낱말 중간 꺾임 | "Setting/s", "Purcha/ses", "Leader/board", "Expedit/ion/comple/te" | Settings, Purchases, Leaderboard, Inbox, Offer details 한 줄. "Support / code", "Expedition / complete", "Gather / three stars"는 공백에서 2줄. 기준 SHA에서 "Leaderboar/d"로 꺾이던 것도 한 줄이 됐다 | 해소 |
| 3. 순위 목록 한 행도 안 보임 | 탭 4개가 2줄, 목록 높이 약 30px | 탭 4개 한 줄, Around me에서 126 Aurora·127 Parker 2행 전체와 3행 윗부분이 보임(기준 SHA 2.5행과 같은 수준). 행은 얇은 플랭크(RowPanel) 위에 글자가 온전히 보인다 | 해소 |
| 4. 지원코드 첫 글자가 리벳과 겹침 | "S"가 왼쪽 리벳 위 | 입력란이 가죽 띠 판으로 바뀌고 "SK - 7H2K9X4Q"가 왼쪽 여백 안쪽에 놓인다. 리벳과 겹치지 않는다 | 해소 |
| 5. 캠프 탭 캡션이 판 밖, 아이콘 뭉개짐 | 캡션 아랫부분이 배경에 걸침, 20px 아이콘이 갈색 덩어리 | 6개 캡션 모두 플랭크 안. 아이콘이 약 28px로 커져 나침반 배지, 상점 천막, 봉인 편지, 광고 상자, 나침반, 톱니가 구분된다 | 해소 |

2회차가 기존 문제로 분류한 항목 중 순위 "My best record" 행의 어두운 글자는 밝은 글자로 바뀌어 읽힌다. 우편함 카드에 카드 판이 없는 것과 map 홈 "13 / Locke / d" 꺾임은 그대로다(아래 기존 문제).

## 기능 결과

- AC-2: `theme.tres`는 PNG 9분할로 조립되고 단위 테스트 19개와 `check.py`가 깨끗한 checkout에서 통과한다. 2회차의 차단 결함이 사라졌으므로 CI `npm test`도 같은 경로로 통과할 것으로 본다(사실: 같은 명령을 새 worktree에서 실행해 exit 0).
- AC-3(320x568): 버튼·칩·패널의 9분할에 줄무늬·모서리 왜곡은 없다. 팝업 프레임 가운데 면의 타일 경계는 아래 결함 1로 적었다.
- AC-4: 상시 모션 4건 PASS. 홈 캡처에서 주 버튼이 정상 위치·크기이고 화면 전환 뒤 Tween 오류 로그가 없다.
- 여정 10개, navigation 3개, camp 1개, scroll-boundary 1개 모두 passed. 설정·언어 전환·지원코드·구매 복원·순위 상태 5종·우편 수령·보상 3단계가 모두 동작한다.
- 터치 영역(코드와 캡처 실측): 모달 머리말 ‹·× 버튼은 폭 360 미만에서 컨트롤 44x48(`outgame_main.gd` 300·307행, 높이 48은 332행). 그려진 판은 약 38px 폭으로 컨트롤보다 3px씩 안쪽이지만 터치 영역은 컨트롤 전체다. 행 버튼·토글 48px, 홈 하단 탭은 계약 최소 56x44 유지. 순위 행 48px.
- 큰 글자: 킷의 "큰 글자"는 +3px(16→19)이며 150% 배율이 아니다(`_ui_font_size`). 이 동작은 전환 전부터 같다. `large-text-ko`에서 토글 행 글자는 플랭크 안에 있다.

## UX 결과

- 홈(hero·map·world): 가죽 재화 칩에 그린 코인·숫자·(+) 플랭크가 모두 알약 안에 있고, 목적지 띠 "WINDWARD ISLES, STAGE 12"는 밝은 글자로 가죽 띠 안에 들어간다. Set out 금빛 플랭크, Shop·Home·Crew 자작나무 플랭크 모두 320 폭에서 겹치지 않는다.
- 타이틀: Preparing 상태의 회색 비활성 주 버튼과 준비 완료 금빛 버튼, 오류 상태 Retry가 구분된다.
- 모달 공통: 프레임 띠가 2회차보다 얇아져 내용 폭이 늘었고 영어 제목·탭·본문이 모두 낱말 단위로 줄바꿈된다. 우편함 Mark read·Claim·Received(비활성), 구매 Check transaction·Support code, 설정 토글 행, 접근성 토글 행의 글자가 전부 플랭크 안에 있다.
- 순위 5개 상태(ended, empty, failed, offline, unranked) 모두 메시지와 My best record 칩이 읽힌다.
- 보상 3단계: 코인 아이콘이 그린 아이콘으로 바뀌었고 "Reward"·코인·"+10 coins" 열이 화면 안에 있다. 연출 중 Continue·View leaderboard 버튼 위로 겹치는 것은 기준 SHA도 같다(기존 동작, 아래 기존 문제).
- 캠프 가로: 상단 "내 계정"·설정 버튼, 재화 띠, 모험 시작 주 버튼, 하단 탭 6개가 그린 재질로 통일됐고 설정·내 계정 팝업 글자가 프레임 안에 있다.
- 키보드 초점: navigation/keyboard-support-focus에서 Support code 버튼에 청록 초점 테두리가 보인다.

## 결함

새 결함(이번 후보에서 생김)

1. [UX, 비차단] 팝업 프레임 가운데 면에 세로 타일 경계가 보인다.
   - 재현: 320x568에서 아무 모달(설정, 지원코드, 구매, 순위, 결과, 접근성)을 연다. 568x320 캠프 설정·내 계정 팝업도 같다.
   - 결과: 프레임 안쪽 나무판에서 x≈194(320 폭 기준) 위치에 나뭇결이 끊기는 세로 선이 한 줄 보인다. 568 폭에서는 세 줄(약 x=192, 330, 468)이다. 글자가 없는 빈 영역(접근성 화면 y 230~330)에서 이웃 열과의 밝기 차 평균이 4.9로, 다른 열 중앙값 0.47의 약 10배다. 밝기 단차는 작지만(약 6%) 나뭇결 무늬가 이어지지 않아 확대 없이도 선으로 인식된다(캡처 폴더 zoom-crops/crop-seam-largetext-4x.png, crop-seam-restore.png).
   - 원인(코드 근거): `skin.json`의 popup_frame이 `axis: ["tile","tile"]`이고 텍스처가 226x226, margins 44/44/44/46이라 가운데 면 138px가 가로로 반복된다. 320 폭 모달의 가운데 면은 약 208px라 138px 지점에서 두 번째 타일이 시작한다. 보정 3이 띠의 리벳 늘어남(3회차 D4)을 막으려고 stretch에서 tile로 바꾼 결과다. 1차 후보(stretch)에서는 이 선이 없었다.
   - 기대: 설계 품질 요구 "9분할 이음매 없음"대로 가운데 면에 선이 보이지 않는다(예: 텍스처 가운데 면을 좌우 끝이 이어지는 무늬로 다시 그리거나, 가운데 면을 균일한 띠로 두고 나무판 결은 별도 내부 패널에 그리는 방법).
   - 영향: 기능과 가독성에는 영향이 없다. pass를 막지 않는다.

기존 문제(전환 전부터 있음, 이번 변경의 책임 아님)

- map 홈의 잠긴 스테이지 버튼 "13 Locked"가 "13 / Locke / d"로 꺾이고 주 버튼 "12 Lost lighthouse" 위에 겹친다. 기준 SHA 925cc8c 320x568 캡처도 동일하다. 참조 제품 `reference/bootstrap/main.gd`의 배치 문제.
- 보상 연출 중 "Reward" 라벨과 코인이 Continue·View leaderboard 버튼 위에 겹친다. 기준 SHA도 동일하며 연출이 끝나면 사라진다.
- 우편함 카드에 카드 판이 없고 글자가 패널 위에 바로 놓인다(기준 동일).
- scroll-boundary probe 화면은 회색 기본 테마다(기준 동일, 스킨 비대상).
- "큰 글자"가 +3px 가산이며 설계가 적은 150%가 아니다. 설계 AC-3의 "150%" 표현과 킷 동작이 다르므로 설계 문구 쪽을 맞추는 것이 맞다.

## 판정

**pass**

- 근거 1(기능): 2회차 차단 결함인 `check.py` 중단이 사라져 새 checkout에서 ok true·scenarios 10으로 끝난다. journey 10/10, camp·navigation·scroll-boundary 전부 passed, ui_kit_probe 47/47, 단위 테스트 19 OK, bundle ok, ui_gate 8항목 PASS.
- 근거 2(UX): 2회차 결함 2~5(제목 꺾임, 순위 목록, 지원코드 리벳 겹침, 캠프 탭 캡션·아이콘)가 모두 320x568·568x320 캡처에서 해소됐다. 2회차가 정한 재검수 조건(설정·지원코드·구매·순위·결과 제목이 낱말 단위, 순위 목록 2행 이상)을 충족한다.
- 남은 결함은 팝업 프레임 가운데 면의 타일 경계 1건이며 기능·가독성에 영향이 없다. 설계의 "이음매 없음" 요구에는 어긋나므로 같은 브랜치의 후속 보정이나 별도 티켓으로 처리하길 권한다. 그 보정이 들어가면 320·844 폭 모달을 다시 캡처해 확인하면 된다.
