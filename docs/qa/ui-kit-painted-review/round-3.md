# ui_kit 그린 스킨 독립 검수 3회차

- 저장소: seorilabs/game-foundation, 브랜치 feat/ui-kit-painted-skin
- 후보 SHA: 10a8765d29cdbeb4561fbd8a3ca47ecc7fa506d7
- 전환 전 기준: c25effba44197c14bd190e17f3a4b0e98d627660 (같은 크기로 직접 캡처해 비교). 보조 비교로 70e187e2715d1f64f4d343dd8d999529ecd57314의 fix2-844x390 캡처도 사용
- 검수자: 독립 검수 에이전트 3 (구현자, 1·2회차 검수자와 다름)
- 일시: 2026-11-06
- 환경: 격리 worktree, 개발 환경(Godot 4.7.2 headless·렌더 캡처), 저장소 파일 수정·커밋 없음
- 범위: 844x390(가로) 캡처와 기능 검사, 코드·자산 검토. 캠프 프로브(568x320)와 내비게이션 프로브(320x568)는 check.py 묶음에 포함돼 함께 봤다
- 설계: docs/design/2026-11-06-ui-kit-painted-skin/design.md AC-1~AC-7, runtime-review.md

## 검수 계획

1. 설계 AC와 runtime-review를 읽고 이번 회차 대상(AC-2 테마·테스트, AC-3 가로 캡처, AC-4 상시 모션, AC-5 아이콘 화풍, AC-7 독립 검수)을 정한다.
2. 격리 worktree에서 `godot --headless --import` 뒤 `tools/check.py --capture --size 844x390`을 돌려 ok와 시나리오 수를 기록한다.
3. journey.json 시나리오 status, ui-kit.json의 상시 모션 motion/reduced 검사, `python3 -m unittest`, `bundle.py verify`(파일 수, art/ 포함 여부), `ui_gate.py` 8항목을 확인한다.
4. 코드·자산 검토: skin.json margins·content·minimum·axis와 PNG 실제 치수·모서리 장식 범위, theme_builder axis, juice.gd 상시 모션의 reduced_motion·노드 해제 안전성, `_clear` 여백 계산, art/ 구성과 묶음 파일 수, manifest 출처 기록.
5. 844x390 캡처 전부를 전환 전 캡처와 비교한다. 가로 홈 버튼·아이콘 크기, 결과 화면 오른쪽 연출 열과 코인 아이콘, 모달 내용 여백.
6. 결함은 실패 시나리오로 적고, 전환 전부터 있던 것은 기준 c25effb 캡처로 구분한다.

## 실행 명령과 결과

| 단계 | 명령 | 결과 |
|---|---|---|
| worktree | `git worktree add <경로> 10a8765` | 성공 |
| import | `godot --headless --path godot --import --quit-after 2` | exit 0 |
| 검증기 | `python3 tools/check.py --capture --size 844x390 --out build/qa-round-3` | **exit 1, ok 아님**. `ui_kit_probe.gd:152`가 삭제된 `icon_coin.svg`를 load해 `ERROR: Resource file not found`가 나고 check.py가 멈춘다. journey·캡처는 실행되지 않음 (시나리오 0) |
| 우회 실행 | check.py와 같은 명령을 직접 실행. ui_kit_probe만 worktree 안에서 해당 한 줄을 `.png`로 바꿔 실행한 뒤 즉시 되돌림(저장소 반영 없음) | contract·ui_standard_contract·accounts·account_services·scroll·camp·navigation 프로브 exit 0, ERROR 0. journey(844x390, --capture) exit 0 |
| journey.json | 시나리오 status | 10개 모두 passed (startup-gates, first-play-reward-and-replay, settings-support-language-restart, inbox-read-claim-scroll, commerce-pending-reconcile-restore, leaderboard-states-and-pagination, shared-version-product-hooks, save-corruption-and-guide-recovery, server-claim-batches-and-failure, late-server-response-preserves-navigation). mode rendered, viewport [844, 390] |
| ui-kit.json | 패치 상태의 ui_kit_probe | 47 checks 0 failed, passed true. `ambient motion: idle pulse moves`, `ambient motion: shine band exists`, `ambient reduced: idle pulse stays still`, `ambient reduced: shine band absent` 모두 PASS. focus 색 검사 PASS |
| 단위 테스트 | `python3 -m unittest discover -s tools -p 'test_*.py'` | 깨끗한 트리에서 19 tests OK |
| 묶음 | `python3 tools/bundle.py verify` | ok true, version 1.1.0, files 85 (기준 c25effb는 82). art/ 3개(asset-manifest.json, style/style-guide.md, style/ui-reference.png) 포함 |
| UI 게이트 | `ui_gate.py --root . --project godot` | 8항목 PASS (display_font, painted_skin, popup_motion, button_sfx, reward_ceremony, particles, hud_layers, currency_chip) |
| 기준 캡처 | c25effb worktree에서 journey 844x390·camp 568x320 캡처 | exit 0 (비교용) |

캡처 복사본: gf-round-3-captures/ (이번 36장 + 첫 check.py 실패 로그 + baseline-c25effb/ 30장).

## 기능 결과

- AC-2: `theme.tres`는 PNG 9분할로 재생성됐고 단위 테스트는 통과한다. 그러나 `check.py`가 깨끗한 checkout에서 실패한다(결함 D1). 메인 작업 트리에는 gitignore된 `*.svg.import` 16개가 남아 있어 Godot이 캐시된 import로 svg를 계속 load했고, 그래서 구현자와 1·2회차에서 드러나지 않은 것으로 판단한다(`.gitignore`의 `**/*.import`, 메인 트리의 `icon_coin.svg.import` 존재 확인).
- AC-4: 상시 모션 프로브 4건 PASS. reduced_motion이면 배율 1 유지, Shine 띠 생성 안 함. Tween은 `node.create_tween()`으로 노드에 묶여 화면 전환 시 노드와 함께 사라진다.
- 10개 여정 시나리오 passed. 보상 3단계(anticipation·impact·settle) 캡처에서 오른쪽 연출 열이 프레임 안에 있고(column end 296 ≤ 320 검사 PASS), 코인 아이콘이 새 그린 아이콘으로 바뀌었다.
- ui_gate 8항목 PASS, 묶음 무결성 ok.

## 코드·자산 검토

(a) skin.json과 PNG

| 텍스처 | 실제 PNG | margins | content | minimum | 판정 |
|---|---|---|---|---|---|
| button_primary/secondary | 160x90 | 24,20,24,22 | 20/18,8,20/18,10 | 64x48 / 56x44 | 모서리 리벳은 margins 안(텍스처 기준 약 12~20px). 다만 PNG 안쪽 투명 여백이 좌우 7~8px, 상하 6~8px 있어 margins에 포함되고, 컨트롤보다 보이는 판이 작아진다(D6) |
| panel | 256x256 | 34,34,34,36 | 26,22,26,24 | 72x72 | 리벳·테두리는 margins 안. 투명 여백 12~13px. 상하 margins 합 70이라 높이 48(순위 행)·70(지원코드 입력란)인 컨트롤에서는 가운데 면이 사라진다(D2, D3) |
| popup_frame | 320x320 | 64x4 | 44,48,44,48 | 136x136 | 놋쇠 모서리 캡은 64 안. 그러나 위·아래 띠의 늘어나는 구간(x 64~256)에 가죽끈과 리벳(텍스처 약 6px)이 있고 axis가 가로 stretch라 844 폭에서 3.5배로 늘어난다(D4). 세로는 tile이라 양 옆은 정상 |
| chip | 96x54 | 28,10,28,10 | 22,4,22,4 | 64x40 | 양 끝 놋쇠 캡은 28 안. 가로 tile로 이음매 없음. 캡처에서 168x44로 정상 |

아이콘 7종(128x128)은 같은 화풍(놋쇠 테두리·나무·가죽)이며 콘택트 시트로 봤을 때 일관된다.

(b) theme_builder: `axis` 배열을 읽어 `tile`이면 `AXIS_STRETCH_MODE_TILE`, 아니면 stretch. 기본값 `["stretch","stretch"]`. focus 색을 skin.json `focus`에서 읽는다. 문제 없음.

(c) juice.gd
- `idle_pulse`·`float_loop`: Tween이 노드에 묶이고 reduced_motion이면 `scale = ONE` 후 즉시 종료. 다만 `center_pivot`이 호출 시점의 `node.size`를 쓰는데 `_home`·`_compact_home`에서는 버튼을 컨테이너에 넣은 직후(크기 0)에 호출한다. 헤드리스로 확인: 호출 시 size (0,0), 레이아웃 뒤 size (370,48)인데 pivot_offset은 (0,0)으로 남는다. 숨쉬기가 중심이 아니라 왼쪽 위를 축으로 오른쪽·아래로만 커진다(D8). press_punch가 눌릴 때 pivot을 다시 잡으므로 한 번 누른 뒤에는 정상이다.
- `shine`: 크기가 0이면 `await process_frame` 뒤 band·node에 접근한다. 같은 프레임에 `queue_free`한 뒤 3프레임 기다려 봤으나 오류 로그는 없었다. 띠 Tween은 band에 묶인다. `node.clip_contents = true`를 주 버튼에 켜지만 버튼 자체 그리기에는 영향이 없다.
- `float_loop`는 설계의 "떠다니기"(position) 대신 scale 숨쉬기 별칭이다. 컨테이너가 position을 되돌린다는 주석 근거가 있어 수용.

(d) `_clear` 여백: 타이틀·홈은 가로(`landscape`)면 0, 아니면 좌우 28·상하 12(높이 500 미만)|26. 844x390 여정은 `landscape`가 false라 홈이 28/12로 그려지며 기준 캡처와 같다. 모달은 `max(기본, 16*scale, 12 + 프레임 content)` = 좌우 56, 상하 60. 390 높이에서는 내용에 270px만 남아 스크롤이 없는 튜토리얼이 넘친다(D5).

(e) art/: `asset-manifest.json`, `style/style-guide.md`, `style/ui-reference.png`(762x1366, 약 1.5MB)뿐이고 raw는 없다. `ui-reference.png`는 manifest의 refs로 재생성에 필요해 설계대로 두었으나 공통 묶음(85파일)에 포함돼 모든 소비 게임에 1.5MB가 설치된다. 묶음 파일 수 변화는 svg 15개 삭제, png 15개 추가, art 3개 추가로 82→85, 설계와 맞다. `camp.svg`는 설계 제외 범위라 남아 있다.

(f) manifest 출처: model `gemini-3-pro-image`, anchor 경로, 자산별 프롬프트·aspect_ratio·final_canvas·refs가 기록돼 있다. 별도 라이선스 필드는 없으나 생성 모델과 입력이 적혀 있어 출처 추적은 가능하다.

## UX 결과

844x390(가로) 캡처 36장을 기준 c25effb와 비교했다.

- 타이틀·오류·로딩: 배경·로고 동일. 주 버튼이 금빛 플랭크로 바뀌고 disabled 상태도 구분된다. 오른쪽 위 Settings 버튼은 폭 80px에 글자 63px가 들어가 글자가 양쪽 리벳 위에 겹친다(D7).
- 홈(hero·map·world): 재화 칩 168x44(기준 170x50), 코인 아이콘 36px, (+) 보조 플랭크 정상. 플랭크 버튼은 컨트롤 높이 48px은 그대로지만 보이는 판이 상하 6px씩 줄어 36px이고, 가로 나비 버튼은 144px(기준 159px)로 보인다(D6). 목적지 띠는 칩 판에 밝은 글자로 읽힌다.
- 결과(보상 3단계): 프레임 안에 왼쪽 버튼 열과 오른쪽 연출 열이 들어가고 코인 아이콘·"+10"·"coins"가 읽힌다. impact 단계의 금색 플래시 정상.
- 모달 공통: 프레임의 놋쇠 모서리와 양 옆 가죽끈은 정상이나 위·아래 띠의 리벳이 가로 21px 타원, 가죽끈이 넓은 띠로 늘어난다(D4). 내용 여백은 좌우 56·상하 60으로 글자가 테두리와 겹치지 않는다. 튜토리얼만 Skip guide 버튼이 아래 띠 위에 올라앉는다(D5).
- 지원코드: 입력란이 갈색 띠로 보이고 코드 글자가 왼쪽 어두운 테두리와 겹쳐 읽기 어렵다(D3). 기준은 흰 판에 선명했다.
- 순위: 행이 갈색 막대로 눌려 "126 Aurora 18900 pts"가 거의 보이지 않고, 내 줄(ChipPanel)은 어두운 가죽 위에 어두운 글자라 읽을 수 없다(D2). 기준은 밝은 행·연녹색 내 줄로 선명했다. 비어 있음·실패·오프라인·종료·미등록 상태 문구는 정상.
- 설정·접근성: 토글 행과 목록 버튼은 플랭크로 정상이나 왼쪽 정렬 글자("큰 글자", "Music")가 왼쪽 리벳에서 시작한다(D7).
- 우편함·구매·복원·오퍼: 스크롤과 버튼 상태(Received·Expired disabled) 정상. 오퍼 이미지와 가격 버튼 정상.
- 캠프(568x320): 재화 칩·주 버튼·내 계정 버튼 정상. 하단 탭 6개는 아이콘이 약 16px로 작고 캡션("계정", "상점"…)이 플랭크 아래 테두리를 가로질러 반쯤 밖에 걸친다(D6). 기준은 24px 선 아이콘과 캡션이 판 안에 있었다.
- 내비게이션 프로브(320x568, 세로): 모달 제목 "Purchases"·"Settings"가 "Purcha/ses", "Setting/s"로 줄바꿈된다(D10). 기준은 한 줄.
- 스크롤 경계: 기준과 동일.

## 결함

| ID | 심각도 | 구분 | 실패 시나리오 | 근거 |
|---|---|---|---|---|
| D1 | 차단 | 기능, 신규 | 깨끗한 checkout에서 `python3 tools/check.py --capture --size 844x390`을 실행하면 `ui_kit_probe.gd:152`의 `load("...icon_coin.svg")`가 ERROR를 내고 check.py가 exit 1로 끝나 journey·캡처·자동 증거(automated.json)가 만들어지지 않는다. CI와 중앙 검증기도 같은 경로다 | 첫 실행 로그(check-py-first-run.log). 메인 트리의 gitignore된 `icon_coin.svg.import`가 캐시를 살려 두어 지금까지 드러나지 않음 |
| D2 | 높음 | UX, 신규(모든 크기) | 순위 화면을 열면 행(PanelContainer, 높이 48)이 panel 텍스처(상하 margins 70)에 눌려 갈색 막대가 되고 이름·점수가 보이지 않는다. 내 줄은 어두운 ChipPanel 위에 어두운 글자다 | leaderboard-around.png, ranking-*.png vs baseline |
| D3 | 높음 | UX, 신규 | 설정 → 지원코드를 열면 코드 입력란(LineEdit read_only = panel 텍스처, 높이 70 = margins 합)에 밝은 면이 없고 코드 글자가 어두운 테두리와 겹친다. 사용자가 코드를 읽고 옮겨 적는 화면이다 | support.png vs baseline, 헤드리스 측정(LineEdit 70px, 스타일박스 margins 34+36) |
| D4 | 중간 | UX·자산, 신규 | 844 폭 모달을 열면 popup_frame 위·아래 띠의 리벳이 6px→21px(3.5배) 타원으로, 가죽끈이 넓은 띠로 늘어난다. 설계의 "늘어나는 구역은 균일한 띠만"에 어긋난다 | reward.png 위 띠 측정, ui_popup_frame.png 분석 |
| D5 | 중간 | UX, 신규(844x390) | 첫 실행 튜토리얼에서 Skip guide 버튼이 프레임 아래 가죽 띠 위에 겹친다. 상하 여백 60px씩 빼면 내용 영역이 270px이라 넘친다 | tutorial.png vs baseline |
| D6 | 중간 | UX, 신규 | 버튼 PNG의 투명 여백(상하 6~8px, 좌우 7~8px)이 9분할 margins에 포함돼 48px 버튼의 보이는 판이 36px, 나비 버튼 폭이 159→144px로 작아 보인다. 터치 영역은 그대로다. 캠프 탭은 캡션이 판 아래 테두리를 넘고 아이콘이 약 16px다 | home.png, camp/camp-title.png vs baseline, PNG opaque bbox 측정 |
| D7 | 낮음 | UX, 기존 원인·신규 노출 | 최소 폭 80px인 Settings 버튼은 글자 63 + content 40 = 103px가 필요하지만 autowrap으로 80px에 머물러 글자가 리벳 위에 겹친다. 토글 행의 왼쪽 정렬 글자도 리벳에서 시작한다. 기준에서는 장식이 없어 보이지 않던 문제 | title-ready.png, large-text-ko.png, 헤드리스 측정 |
| D8 | 낮음 | 코드, 신규 | `_home`·`_compact_home`에서 `Juice.idle_pulse`를 레이아웃 전에 호출해 pivot_offset이 (0,0)으로 남는다. 주 버튼이 중심이 아니라 왼쪽 위를 축으로 숨 쉰다(오른쪽·아래 가장자리만 움직임). 프로브는 size를 직접 지정해 이 경우를 잡지 못한다 | 헤드리스 확인: 호출 시 size (0,0), 레이아웃 뒤 pivot (0,0) |
| D10 | 낮음 | UX, 신규(320x568, 회차 범위 밖이나 프로브 캡처에 포함) | 세로 320 폭 모달에서 제목 "Purchases", "Settings"가 두 줄로 꺾인다. 좌우 여백 56px과 뒤로·닫기 버튼이 폭을 차지한다 | navigation/*.png vs 전환 전 |

기존 문제(전환 전부터): 없음. 위 항목은 모두 기준 c25effb 캡처에서 재현되지 않았다. D7의 최소 폭 80px 규칙은 기존 코드지만 겹침 자체는 새 스킨에서 처음 보인다.

관찰(결함 아님): `ui-reference.png` 1.5MB가 공통 묶음에 들어가 소비 게임마다 설치된다. manifest에 라이선스 필드가 없다. `shine`의 await 뒤 해제 접근은 3프레임 테스트에서 오류가 없었다.

## 판정

**fail**

근거: D1은 검증기 자체를 막는 기능 결함이라 AC-2·AC-3의 증거(check.py ok, 캡처)를 깨끗한 환경에서 만들 수 없다. D2·D3은 순위와 지원코드라는 핵심 정보가 읽히지 않는 UX 결함이고, D4는 설계의 9분할 품질 요구("이음매·줄무늬·모서리 왜곡 없음")에 직접 어긋난다. 우회 실행한 여정 10개와 상시 모션·게이트·묶음 검사는 통과했으므로 D1은 한 줄 수정, D2·D3은 행·입력란의 높이 또는 전용 얇은 판(ChipPanel·전용 텍스처) 적용, D4는 위·아래 띠의 장식 제거 또는 세로 margins 확대, D5·D6은 여백·투명 여백 조정으로 해결 가능하다. 수정 뒤 같은 크기로 재검수가 필요하다.
