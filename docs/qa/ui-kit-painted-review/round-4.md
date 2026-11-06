# ui_kit 그린 스킨 독립 검수 4회차(2차 후보 1회차)

- 검수자: 독립 검수 에이전트 4 (구현자, 1~3회차 검수자와 다름)
- 저장소: seorilabs/game-foundation, 브랜치 feat/ui-kit-painted-skin
- 후보 SHA: f710bbd83e260e16b148d87c0a7d0457515f4cbf (코드 마지막 변경은 697605e, 그 뒤 잠금 갱신 02017a8과 검수 기록 f710bbd)
- 이전 후보: 10a8765d29cdbeb4561fbd8a3ca47ecc7fa506d7 (1~3회차 모두 fail)
- 크기: 390x844 (check.py 묶음에 포함된 캠프 프로브 568x320, 내비게이션 프로브 320x568도 함께 봄)
- 실행 시각: 2026-11-06 09:06~09:08 UTC
- 실행 환경: 격리 worktree(새 체크아웃, import 캐시 없음), Godot 4.7.2.stable headless, 렌더 캡처, Python 3 unittest
- 격리 저장: check.py가 만드는 격리 저장소(effective-profile.json 확인), 저장소 파일 수정·커밋 없음, worktree는 검수 뒤 제거
- 비교 기준: 홈은 시안 A(concept_a_wood_leather.png), 나머지는 전환 전 925cc8c의 fix3-390x844 캡처
- 설계: docs/design/2026-11-06-ui-kit-painted-skin/design.md AC-1~AC-7, runtime-review.md, docs/qa/ui-kit-painted-review/round-1..3.md

## 검수 계획

1. 설계 AC와 runtime-review, 1~3회차 결함(D1~D8, D10, 2회차 결함 1~5)을 읽고 이번 후보의 변경(10a8765..f710bbd: 패널 160px·팝업 프레임 240px, 투명 여백 제거, RowPanel, 팝업 띠 타일, 캠프 아이콘 56 설계 px, 좁은 세로의 머리말 버튼 폭 44, idle_pulse의 resized 재중심, probe 코인 아이콘 png)을 diff로 확인한다.
2. 새 worktree에서 `godot --import` 뒤 `check.py --capture --size 390x844`를 돌려 ok와 시나리오 수를 기록한다. 깨끗한 체크아웃에서 D1(삭제된 svg 경로)이 재발하는지 본다.
3. journey.json 시나리오 status, ui-kit.json 상시 모션·focus 검사, unittest, bundle verify, ui_gate 8항목을 확인한다.
4. 캡처 36장을 하나씩 보고 홈은 시안 A와, 나머지는 전환 전 캡처와 나란히 비교한다. 이전 결함 각각의 해소 여부를 표로 적는다. 의심 구역(재화 칩, 주 버튼, 지원코드 입력란, 토글 행, 팝업 띠, 팝업 안쪽 타일, 캠프 탭, 순위 행, 타이틀 Settings 버튼, 큰 글자 행)은 3~4배 확대해 본다.
5. 코드 검토: juice.gd의 resized 연결 중복 여부와 레이아웃 뒤 pivot을 headless 스크립트로 측정한다. 9분할 타일 이음매는 캡처 열 차분으로 측정한다.
6. 결함은 실패 시나리오로 적고 전환 전부터 있던 것은 기존 문제로 구분한다.

## 실행 명령과 결과

| 단계 | 명령 | 결과 |
|---|---|---|
| worktree | `git worktree add <격리 경로> f710bbd` | 성공, detached HEAD f710bbd |
| import | `godot --headless --path godot --import --quit-after 2` | exit 0, ERROR 0 |
| 검증기 | `python3 tools/check.py --capture --size 390x844 --out build/qa-round-4` | exit 0, `{"ok": true, "sourceSha": "f710bbd…", "scenarios": 10}`. 33초 (180초 이내, 단독 재실행 불필요). 캡처 PNG 36장 |
| journey.json | 시나리오 status | 10개 모두 passed (startup-gates, first-play-reward-and-replay, settings-support-language-restart, inbox-read-claim-scroll, commerce-pending-reconcile-restore, leaderboard-states-and-pagination, shared-version-product-hooks, save-corruption-and-guide-recovery, server-claim-batches-and-failure, late-server-response-preserves-navigation). mode rendered, viewport [390, 844] |
| ui-kit.json | ui_kit_probe | passed true, 47 checks 0 failed. `ambient motion: idle pulse moves`, `ambient motion: shine band exists`, `ambient reduced: idle pulse stays still`, `ambient reduced: shine band absent`, `focus: default skin keeps the soft-adventure focus color`, `reward motion/reduced: column end 296` PASS |
| 단위 테스트 | `python3 -m unittest discover -s tools -p 'test_*.py'` | 19 tests OK |
| 묶음 | `python3 tools/bundle.py verify` | ok true, version 1.1.0, source commit 697605e, files 85 |
| UI 게이트 | `ui_gate.py --root . --project godot` | 8항목 PASS (display_font, painted_skin, popup_motion, button_sfx, reward_ceremony, particles, hud_layers, currency_chip) |
| pivot 측정 | headless SceneTree 스크립트: VBox 안 Button(size 0)에 `Juice.idle_pulse` 호출 → 2프레임 뒤 | 호출 시 size (0,0) pivot (0,0) → 레이아웃 뒤 size (370,48) pivot (185,24), 0.5초 뒤 scale 1.024. 두 번 호출해도 resized 연결 1개 |
| git status | 검수 뒤 | 깨끗함(저장소 파일 변경 없음) |

## 이전 결함 재확인

| 이전 ID | 내용 | 이번 후보 | 근거 |
|---|---|---|---|
| R1 D-1 / R2 1 / R3 D1 | 프로브가 삭제된 icon_coin.svg를 load해 새 체크아웃에서 check.py 중단 | 해소 | 새 worktree에서 check.py ok true, scenarios 10. ui_kit_probe.gd:152가 icon_coin.png를 load |
| R1 D-3 / R3 D2 | 순위 행(48px)이 panel 텍스처에 눌려 갈색 막대, 내 줄 어두운 글자 | 해소 | leaderboard-around, ranking-closed·offline: 126 Aurora 18900 pts 등 5행이 얇은 플랭크(RowPanel) 위에 선명. 내 줄은 가죽 칩 위 밝은 글자+외곽선 |
| R1 D-2 / R2 4 / R3 D3 | 지원코드 입력란에 밝은 면이 없고 코드가 테두리와 겹침 | 해소 | support: 입력란이 가죽 테두리의 밝은 판으로 그려지고 SK-7H2K9X4Q 전체가 판 위에서 읽힘. 첫 글자 S가 안쪽 테두리 선에 닿을 만큼 가깝지만 겹치지 않음(관찰 O3) |
| R3 D4 | 팝업 위·아래 띠 리벳이 가로로 늘어남 | 해소(잔여 N1) | 띠가 tile이라 리벳은 원형 유지. 다만 타일 경계에서 띠 끈 두 개가 맞붙음 |
| R3 D5 | 844x390 튜토리얼 Skip guide가 아래 띠 위에 겹침 | 이번 크기 범위 밖 | 390x844의 tutorial.png에서는 Skip guide가 프레임 안에 있음. 844x390은 별도 회차 |
| R3 D6 / R2 5 / R1 D-4 | 버튼 PNG 투명 여백으로 보이는 판이 작음, 캠프 탭 캡션이 판 밖, 아이콘 뭉개짐 | 해소 | PNG alpha bbox가 전체(150x82, 148x78, 148x149, 226x226, 94x48). 홈 Set out·Shop 버튼의 판이 컨트롤 높이 48을 채움. camp-title: 6개 탭 캡션(계정, 상점, 우편함, 광고 보상, 운영, 설정)이 플랭크 안에 있고 아이콘 약 25px로 메달·가게·봉투·두루마리·나침반·톱니가 식별됨 |
| R3 D7 | 타이틀 Settings 버튼 글자가 리벳 위에 겹침, 토글 행 글자가 리벳에서 시작 | 해소 | title-ready: Settings 글자가 리벳 안쪽. settings-ko·large-text-ko: 음악, 큰 글자 글자가 왼쪽 리벳 오른쪽에서 시작 |
| R3 D8 | idle_pulse 축이 왼쪽 위 | 해소 | pivot 측정 (185,24) = 가운데. resized 신호로 재중심, 중복 연결 없음 |
| R1 D-5 / R2 2 / R3 D10 | 320 폭 모달 제목이 낱말 중간에서 꺾임 | 해소 | navigation/commerce-completed·keyboard-support-focus: Purchases, Settings 한 줄 |
| R2 3 | 320x568 순위 목록이 한 행도 안 보임 | 이번 프로브에 순위 캡처 없음 | 320 모달의 내용 폭·높이는 프레임 240px로 늘어났고(머리말 버튼 44px) 설정 화면은 4행+안내문+Language까지 보임. 순위는 320x568 회차에서 확인 필요 |

## 기능 결과

- AC-2: skin.json textures가 PNG 9분할로 등록되고 theme.tres가 재생성됨. RowPanel 변형이 theme_builder VARIATIONS와 스타일박스(보조 버튼 텍스처)에 추가됨. unittest 19 OK, bundle verify ok(85 파일, 잠금 697605e와 일치).
- AC-3(390x844): 이음매·줄무늬·모서리 왜곡은 타일 경계의 N1(아래) 외에 없음. 큰 글자(large-text-ko)에서 토글 행 글자가 판 안에 있음.
- AC-4: 상시 모션 4건 PASS. pivot은 레이아웃 뒤 가운데. reduced_motion이면 정지·Shine 없음.
- AC-7: 이번 회차가 2차 후보의 1회차.
- 여정 10개 passed. 보상 3단계(reward, reward-impact, reward-settle)에서 코인 아이콘(그린 메달)과 +10 coins, 파티클이 프레임 안에 있음. 우편함 Received·Expired disabled 상태 구분, 구매 대기·복원, 오퍼 이미지·가격 버튼, 순위 5상태(closed, empty, failed, offline, unranked) 문구 모두 정상. 내비게이션 프로브의 키보드 focus 링(Support code)이 보임.

## UX 결과

- 홈(home, home-hero) ↔ 시안 A: 가죽 알약 칩+금 코인+(+) 플랭크, 자작나무 플랭크 Inbox/Rank, 금빛 나무 Set out, 하단 3탭 플랭크가 시안의 재질·색·구도와 같다. 시안의 원형 놋쇠 메뉴 단추와 두꺼운 목적지 나무판은 runtime-review에 적힌 대로 차이 수용(플랭크 메뉴 버튼, 가죽 띠 목적지).
- 홈(map, world): 스테이지 버튼이 플랭크로 바뀌고 Lighthouse Lv.2, Collect 20이 읽힘. "13 Locked"의 "Lock/ed" 줄바꿈과 12 Lost lighthouse 겹침은 전환 전과 동일(기존 문제).
- 타이틀·로딩·오류: Begin adventure 금빛 플랭크, disabled 회색 플랭크, Retry 정상. Settings 버튼 글자가 판 안.
- 모달 공통: 프레임 240px(가죽 띠+놋쇠 모서리), 안쪽 나무판 타일. 제목·뒤로·닫기 버튼이 위 띠 아래 놓이고 글자가 테두리와 겹치지 않음. 내용 폭은 전환 전보다 약 14px 좁고 높이는 약 40px 짧아 "Gather three stars"가 두 줄이 되지만 낱말 단위다.
- 설정·접근성(ko): 토글 행 4개와 목록 버튼 6개가 플랭크로 정상, v1.0.0이 프레임 안. 언어 버튼의 focus 링 보임.
- 지원코드: 코드 판 위에서 읽힘(위 표).
- 순위: 행·내 줄·My best record 모두 읽힘. 전환 전 내 줄(어두운 청록 위 회색 글자)보다 대비가 좋아짐.
- 우편함: 카드 글자·버튼 정상. 스크롤 위치가 전환 전과 조금 달라 첫 카드 제목이 머리말 아래로 들어가지만 스크롤 가능.
- 캠프(568x320): 재화 칩, 모험 시작 주 버튼, 내 계정·설정 버튼 정상. 하단 탭 6개 캡션·아이콘 정상(위 표). camp-settings·account-connected는 프레임 띠 때문에 내용 높이가 줄어 설정 2.5행, 계정 버튼 1행+조금만 보이고 나머지는 스크롤(관찰 O2).
- 내비게이션(320x568): 제목 한 줄, 본문·버튼 정상.
- scroll-boundary 프로브는 테마 없는 회색 화면(전환 전 동일, 스킨 비대상).

## 결함

| ID | 심각도 | 구분 | 실패 시나리오 | 근거 |
|---|---|---|---|---|
| N1 | 낮음 | UX·자산, 신규 | 어떤 모달이든 열면 popup_frame 위·아래 띠의 타일 경계(x≈182, 프레임 왼쪽 가장자리에서 138px 간격)에서 가죽 끈 두 개가 2px 간격으로 맞붙어 리벳 4개가 뭉친다. 다른 끈은 약 50px 간격이라 그 자리만 패턴이 끊긴다. 390과 320 모달 모두 같은 자리. 안쪽 나무판도 같은 경계(x≈193, 334)에서 밝기가 한 단계 바뀌는 세로 선이 생긴다(열 차분 4.5, 주변 중앙값 0.44). 설계 AC-3 "이음매 없음"에 어긋나지만 글자·조작에는 영향 없음 | ranking-empty, settings-ko, navigation/commerce-completed 위 띠 4배 확대, 캡처 열 차분 측정 |

기존 문제(전환 전부터, 이번 변경 책임 아님): map 홈 "13 Locked"의 낱말 중간 줄바꿈과 12 Lost lighthouse 겹침. scroll-boundary 프로브의 회색 기본 테마.

관찰(결함 아님)
- O1: "Gather three stars", "Expedition complete" 제목이 390 폭에서 두 줄(낱말 단위). 전환 전 Gather three stars는 한 줄.
- O2: 568x320 모달의 내용 높이가 프레임 띠(44+46px)만큼 줄어 계정 화면에 버튼 1행만 보이고 나머지는 스크롤. 전환 전은 2행. 스크롤바가 있어 기능은 된다.
- O3: 지원코드 첫 글자 S가 입력란 안쪽 테두리 선에 거의 닿는다(content 14px). 읽기에는 지장 없다.
- O4: 내 순위 줄(ChipPanel, 가로 tile)의 가죽에 타일 구간마다 약간 어두운 세로 띠가 보인다.

## 판정

**pass**

근거: 1~3회차의 차단·높음 결함(D1 검증기 중단, D2 순위 행, D3 지원코드)과 중간·낮음 결함(D4 리벳 늘어남, D6 투명 여백·캠프 탭, D7 Settings 버튼, D8 pivot, D10 320 제목)이 이번 후보에서 모두 해소됐고, 새 체크아웃에서 check.py ok·여정 10/10·ui_kit 47/47·unittest 19·bundle·ui_gate 8항목이 통과했다. 홈은 시안 A와 재질·색·구도가 같다. 남은 N1은 타일 경계의 장식 패턴 불연속으로 읽기·조작을 막지 않아 낮음으로 분류했다. 다만 AC-3 문구를 그대로 적용하면 이음매에 해당하므로, 팝업 띠 텍스처의 한쪽 가장자리 끈을 없애고 안쪽 판 좌우 끝 밝기를 맞추는 보정을 잠금 전 후속으로 권한다. 844x390의 D5(튜토리얼 Skip guide)와 320x568 순위 목록(2회차 결함 3)은 이번 크기에서 볼 수 없어 해당 회차에서 확인해야 한다.
