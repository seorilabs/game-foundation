# 진행 초기화와 베타 공용 수정 독립 검수 1회차

- 검수자: 독립 검수 에이전트 1 (구현자와 다른 에이전트)
- 대상: seorilabs/game-foundation PR #32 `feat/progress-reset-betta-upstream`, 후보 SHA `1afbf05c28140717a6b4c3682fea15797e98adc1`, 기준 main `4071d7be7ff6d4f11e3fd043bd6e4b05146fff05`(fetch 뒤 origin/main, 후보의 merge-base와 같음)
- 변경 규모(`git diff --stat 4071d7b..1afbf05`): 26개 파일, 481줄 추가, 42줄 삭제. 커밋 10개(`62f4033`~`1afbf05`). 공용 묶음 1.3.0, 96개 파일, 잠금 원본 커밋 `95527e8`
- 크기: 390x844, 320x568, 844x390, 1280x720 (4개 모두 판정). 레퍼런스 여정은 세로 제품(`landscape = false`)을 네 창 크기로 띄운다. 가로 제품(`landscape = true`, 캠프 홈)은 보조 스크립트로 568x320, 844x390, 1280x720을 따로 봤다
- 실행 시각: 2026-11-28 04:06–04:27 UTC
- 실행 환경: dev headless 검증 + 렌더링 캡처. Godot 4.7.2.stable.official.ed1daf0bf(Compatibility, Apple M3), macOS 27.2.1, Python 3.14.7, Node 24.16.0. 격리 worktree `game-foundation.worktrees/review-progress-r1`(detached `1afbf05`). 같은 시간에 다른 세션이 다른 저장소의 Godot를 돌렸다(infect-everything headless 여정 3개와 렌더 여정, vernhald feel headless, malang 렌더, 그 밖의 headless 검사). 렌더 실행 전마다 `build/review-r1/guard.sh`로 확인했고, 별도 감시 루프(`build/logs/godot-monitor.log`, 04:08:41부터 2초 간격)가 이 worktree 밖의 Godot 프로세스를 기록했다. 저장은 여정과 보조 스크립트의 격리 프로필만 썼고, 실행 뒤 이번 실행이 만든 `Game Foundation Reference` 사용자 폴더 항목 44개를 지웠다(아래 정리)
- 설계: `docs/design/2026-11-28-progress-reset/design.md` PR-1~PR-7, "사용자 흐름·화면 상태", "데이터·인터페이스·실패 처리", "품질 요구사항". 테스트 계획 `test-plan.json` L3, dev, redesign(새 화면 1개), release null. 이전 회차 없음

## 검수 계획

실행 전에 적은 계획이다(04:08 UTC, `godot --headless --path godot --import`만 먼저 실행). 이번 회차는 새 화면인 진행 초기화(기본, 무장, 거부, 완료 직후, 한국어)가 네 크기에서 잘리지 않고 읽히는지, 지우는 것과 남는 것을 사용자가 알 수 있는지, 무장 상태가 확인 단계로 읽히는지를 화면에서 보고, 저장 바이트·신호·분석 사건·구매 기록이 설계대로 남거나 지워지는지를 여정이 다루지 않는 경우까지 직접 재현한다. 베타에서 옮긴 공용 수정(우편 보상 이름, 작은 가로 보상 카드, E2E 드라이버 오디오 해제 대기와 스크롤 안정 판정, 입력 배치 검사)은 회귀와 화면을 본다.

| 순서 | 영역 | 내용 | 통과 기준 |
|---|---|---|---|
| 0 | 환경 | 렌더 실행 전마다 `build/review-r1/guard.sh`로 `pgrep`/`ps`에서 godot-mcp를 뺀 Godot 프로세스를 기록하고, headless가 아닌 다른 렌더 프로세스가 있으면 기다린다. 다른 저장소의 headless 실행은 허용하고 기록한다 | 렌더 시작 시 다른 렌더 프로세스 없음 |
| 1 | 기능 | `npm test`(단위 + headless check.py), `python3 tools/bundle.py verify` | 종료 0, 건너뜀 없음, verify ok(1.3.0) |
| 2 | 렌더링 | `python3 tools/check.py --capture --size <크기> --out build/qa-r1-<크기>`를 390x844, 320x568, 844x390, 1280x720으로. 실패하면 로그를 보고 한 번 재실행하며 실패 출력은 `-try1`로 남긴다 | 4개 모두 종료 0, 여정 모든 시나리오 passed |
| 3 | 새 화면 | Read 도구로 `reset-progress`, `reset-progress-armed`, `reset-progress-refused`, `reset-progress-done`, `reset-progress-ko`를 4개 크기 모두 본다 | 잘림 없음, 글자 읽힘, 버튼 높이 세로 48px·가로 56px 이상, 지우는 것과 남는 것이 화면에 있음, 무장 상태가 확인 단계로 읽힘, 다른 공용 화면과 같은 판·버튼, 한국어 해요체가 자연스러움 |
| 3a | 설정 진입 | 진행 초기화 항목이 보이는 설정 캡처를 찾아 본다. 캡처가 없으면 보조 스크립트로 설정 목록 끝을 찍는다 | 항목이 목록 아래쪽(크레딧·테스트실 다음)에 기존 설정 버튼과 같은 판으로 있음 |
| 3b | 베타 공용 수정 화면 | 우편·보상 캡처(여정의 inbox, reward 계열)를 본다. 이름 제공자 우편과 작은 가로 카드는 여정 캡처가 없으면 보조 스크립트로 찍는다 | 우편 카드에 ID가 드러나지 않음, 작은 카드가 한 줄로 읽힘, 기본 카드 불변 |
| 4 | 보조 재현 | `build/review-r1/` 아래 일회용 스크립트(추적 파일 수정 없음)로: (a) 안내 진행 중(별 일부 누름) 저장에서 초기화, (b) 무장 상태에서 뒤로(‹), 닫기(×), Android 뒤로 가기 알림, 다시 열었을 때 무장 해제, (c) 구매 진행 기록(`ui.commerce`)이 있는 저장에서 초기화 뒤 구매 확인이 이어지는지, (d) 분석 사건(`events`) 수와 `sentAt` 전후 비교, 초기화 뒤 다시 시작했을 때 이미 보낸 사건이 다시 나가지 않는지, (e) 서버 모드에서 항목 없음, (f) 320 폭 한국어 무장 글자와 큰 글자 설정에서 넘침, (g) 엔딩을 본 뒤 초기화했을 때 "엔딩 다시 보기"와 화면 문구("이미 본 장면"이 남음)의 일치, (h) 초기화 직후 홈 재화 칩·우편 수 등 메모리에 남은 값 | 실제 실패 시나리오만 지적으로 적는다 |
| 5 | 문서·계약 | 설계 인터페이스, README, 코드 주석과 실제 동작이 같은지 읽어서 확인한다 | 일치 |
| 6 | 정리 | 이번 실행이 만든 `Game Foundation Reference` 사용자 폴더 항목을 생성 시각으로 찾아 지운다. `build/` 출력은 남긴다 | 이번 실행 항목 0개 남음 |
| 7 | 판정 | 인수조건별 결과, 화면별 판정, 발견 사항(실패 시나리오, blocker/major/minor) | blocker·major가 원본 PNG나 재현으로 확인되지 않으면 pass |

실행 중 계획에 더한 것: 렌더 check.py 1차 실행에서 390x844와 320x568이 진행 초기화와 무관한 부속 probe(입력 무시)로 실패해, 계획대로 같은 명령을 한 번 더 돌리고 실패 출력은 `-try1`로 남겼다(R1-7). 4(f)의 넘침을 보려고 보조 스크립트에 큰 글자 설정을 더했고, 레퍼런스 여정이 세로 제품만 띄운다는 것을 확인한 뒤 가로 제품(`landscape = true`)의 진행 초기화 화면을 568x320, 844x390, 1280x720에서 따로 찍고 사각형을 쟀다. 우편 보상 이름과 작은 가로 카드는 여정 캡처가 없어 보조 스크립트로 찍었다. 같은 자리를 빠르게 두 번 누르는 경우를 더했다.

## 실행 명령과 결과

모든 명령은 격리 worktree 루트에서 실행했다. 실행 시각과 종료 코드는 `build/logs/runs.log`, 렌더 전 확인은 `build/logs/guard.log`, 명령별 출력은 `build/logs/<이름>.log`에 있다.

| 순서 | 명령 | 결과 |
|---|---|---|
| 0 | `git fetch origin`, `git worktree add --detach .../review-progress-r1 1afbf05…` | 종료 0. origin/main `4071d7b`가 후보의 merge-base와 같다 |
| 1 | `godot --headless --path godot --import` | 종료 0 (04:06:49–04:06:54), ERROR 0 |
| 2 | 렌더 실행 전마다 `build/review-r1/guard.sh` | 렌더 실행 11회 앞에서 모두 실행했다(import와 `npm test` 앞에서도 실행). 대기는 844x390 1차 앞 한 번(50초)이다. 그때 infect-everything의 렌더 여정(pid 16131, `--resolution 720x1280`, 04:10:44–04:11:36)이 떠 있었다. 나머지는 다른 저장소 headless 실행만 있었다. 감시 루프에 잡힌 비 headless 항목 중 Godot 렌더는 위 16131과 이번 렌더가 모두 끝난 뒤의 malang(04:23:07~)과 infect-everything(04:24:56~)뿐이고, 나머지는 경로에 godot이 든 Xcode 컴파일과 Python 검사였다 |
| 3 | `npm test` | 종료 0 (04:07:22–04:08:23). 단위 테스트 36개 OK(건너뜀 0, `test_contract_1_3_0_installs_over_1_2_0_and_downgrade_refused` 포함), headless check.py `{"ok": true, "scenarios": 15}`, ui-kit 115/0, dev 26/0, ui-contract 87/0 |
| 4 | `python3 tools/bundle.py verify` | 종료 0. ok, version 1.3.0, files 96, source commit `95527e8…` |
| 5 | `check.py --capture --size 390x844 --out build/qa-r1-390x844` 1차 | **종료 1** (04:08:45–04:09:41). 여정 15/15, ui-kit·dev·ui-contract 0 failed, input-layout 1/1까지 통과한 뒤 부속 `e2e_scroll_probe`(390x844 고정 ScrollContainer 고정물)의 첫 끌기와 탭이 무시됐다(scroll 0, 누름 0). 그 시간에 다른 렌더 프로세스 없음. 출력 `build/qa-r1-390x844-try1/` |
| 6 | 같은 명령 320x568 1차 | **종료 1** (04:09:42–04:10:46). 여정 15/15 통과 뒤 부속 `camp_probe`(568x320 가로 제품)의 `landscape-account-buttons / manage`부터 5단계 실패. `account_manage`가 목록 아래에 있어 끌기가 필요한 단계다. 실패 시각(camp 04:10:41–04:10:46)에 다른 세션의 렌더 창(16131)이 04:10:44에 떴다. 출력 `build/qa-r1-320x568-try1/` |
| 7 | 같은 명령 844x390 | 종료 0 (04:11:37–04:13:03), 15개 시나리오 |
| 8 | 같은 명령 1280x720 | 종료 0 (04:13:03–04:14:11), 15개 시나리오 |
| 9 | 390x844 2차 | 종료 0 (04:14:23–04:15:28), scroll-boundary 1/1, camp 2/2, navigation 3/3 |
| 10 | 320x568 2차 | 종료 0 (04:15:28–04:16:41), camp 2/2, navigation 3/3 |
| 11 | 보조 `build/review-r1/reset_probe.gd` headless 390x844 | 첫 시도(04:16:54)는 이 보조 스크립트의 타입 추론 문법 오류로 불러오지 못했다(Godot 종료 코드는 0). 둘째(04:17:02)는 우편 장면을 띄우는 보조 스크립트 설정 누락으로 SCRIPT ERROR가 났다. 둘 다 고친 뒤 `--only mail` 확인(종료 0, ERROR 0), 전체 실행(04:17:51–04:18:16) 종료 0, ERROR 0, 시나리오 11/11 통과. 결과 `build/review-r1/headless-390x844/` |
| 12 | 같은 보조 스크립트 렌더(`--capture`) 390x844, 320x568, 844x390, 1280x720, 568x320 | 320x568, 844x390, 1280x720 종료 0. 390x844(04:18:58–04:19:33)와 568x320(04:21:54–04:23:04)은 **종료 1**: 새 창을 띄운 직후 첫 탭(`start`)이 무시되어 첫 시나리오(안내 진행 중 초기화)만 실패했고 나머지 10개 시나리오는 통과했다. 같은 시나리오는 headless와 다른 세 크기에서 통과했다(R1-7). 568x320 실행은 `--only` 인자 전달을 잘못 묶어 전체 시나리오가 돌았다. 결과 `build/review-r1/render-<크기>/` |
| 13 | 사용자 폴더 정리 | 이번 실행 전 목록(`build/review-r1/userdata-before.txt`)과 비교해 새로 생긴 44개(`e2e-ui-standard-*` 7, `outgame-contract-*` 7, `first-light-e2e-*` 7, `e2e-review-1-{commerce,keyboard,native}-*.json` 15, `review-r1-reset-*` 8)를 지웠다. 정리 뒤 항목 수는 실행 전과 같다(1036). 기존 `logs/` 폴더는 Godot가 돌려 쓰는 공용 로그 폴더라 남겼다 |

## 기능 결과

| 항목 | 결과 | 근거 |
|---|---|---|
| 여정 | 15/15 passed, 4개 크기 모두(최종 실행), headless도 같음 | 단계 259개(1280x720은 260개). `settings-reset-progress` 35단계, `korean-cutscene-test-room-credits` 9단계(한국어 초기화 화면 포함) |
| ui-kit probe | 115 checks, 0 failed | 직전 계약의 111개에 작은 가로 카드 4개(움직임·줄인 움직임 × 가로 줄, 44px 아이콘)가 더해졌다 |
| dev, ui-contract probe | 26/0, 87/0 | 4개 크기, headless |
| outgame contract probe | 통과 | 진행 초기화 항목: 제품 거부(`reset_refused`), 스키마 위반(`save_schema_invalid`), 거부 뒤 바이트 동일, 훅 없는 공용 초기화, 읽지 못한 저장의 초기화 거부 |
| 부속 probe | input-layout 1/1, studio-splash 1/1, scroll-boundary 1/1, camp 2/2, navigation 3/3 | 최종 실행 4개 크기. 1차 실패 2건은 R1-7 |
| 묶음·버전 | pass | `bundle.py verify` ok 1.3.0, `test_bundle` 8개(1.3.0 위 설치·역설치 거부 포함), `test_ui_contract` 2개 |

보조 재현 결과(`build/review-r1/headless-390x844/facts.json`, 렌더 결과는 `render-<크기>/facts.json`):

| 경우 | 결과 | 판정 |
|---|---|---|
| (a) 안내 진행 중 초기화: 별 2개를 누른 판(runId 있음)에서 뒤로 → 홈 → 설정 → 초기화 | 저장의 `tutorial.hits` 2→0, `status` active, `ui.runId` 빈 값, 코인 0, 예제 우편 1통으로 복귀. 다시 시작하면 "○ ○ ○"와 "Tap the star"부터 나온다. 별 3개와 받기로 코인 10, `grants.tutorial-first` 10 | 설계대로 |
| (b) 무장 뒤 나가기 | 뒤로(‹) → 설정, 닫기(×) → 홈, Android 뒤로 가기 알림 → 설정, 같은 화면 다시 그리기 → 무장 해제. 네 경우 모두 저장 바이트 동일, 다시 열면 "Reset progress"로 돌아와 있다 | 설계대로 |
| 빠른 두 번 누름 | 같은 자리에 누름·뗌을 두 번(렌더 31~40ms, headless 25ms) 넣으면 무장 문구가 그려지기 전에 초기화가 끝나 타이틀로 간다(코인 340→0). 390x844, 320x568, 844x390, 1280x720 모두 같다 | **R1-2** |
| (c) 확인 중인 구매가 있는 저장 | 상점에서 구매를 `pending`으로 둔 뒤 초기화. `ui.commerce` `{"current:example:user": {"state": "pending", "transactionId": "reference-transaction"}}`가 그대로 남고, 다시 띄워 `reconcile()`하면 `completed`가 된다 | 설계대로 |
| (d) 분석 사건 | 초기화 전 `events` `["startup-first"]`, 뒤에도 같다. 다시 안내를 끝내면 `tutorial-action`, `tutorial-complete`만 더해진다(초기화 전에는 안내를 끝내지 않았다). 이미 있는 키가 다시 생기지 않는다 | 설계대로 |
| (e) 서버 모드, 훅 없는 제품 | 여정 `settings-reset-progress`의 마지막 단계에서 둘 다 항목 없음 | 설계대로 |
| (f) 320 한국어 무장, 큰 글자 | "한 번 더 누르면 초기화해요"가 320 폭 버튼(252x48) 안에 한 줄로 들어간다. 큰 글자에서도 버튼 높이 48 유지 | 통과 |
| (f') 거부 이유의 위치 | 이유 줄이 버튼 아래에 붙어서, 작은 화면과 가로 제품에서 스크롤 보기 밖으로 밀린다(아래 표) | **R1-1** |
| (g) 엔딩을 본 뒤 초기화(map 제품) | 초기화 화면에 "Kept: … scenes you have seen"이 보이는데, 초기화 뒤 설정의 "Replay ending"이 사라진다(레퍼런스 훅이 `set_ending_seen(false)`) | **R1-5** |
| (h) 초기화 직후 메모리 값 | 신호 1회, 토스트, 타이틀. 홈 재화 칩 0, 우편은 예제 우편 1통. 구매 상태는 메모리에도 `pending` 유지 | 설계대로 |
| 제품 훅이 스키마에 맞지 않는 next를 돌려줌 | 저장 바이트 동일, 화면 유지, 이유 줄은 "The save could not be read. Your data was preserved." | **R1-6** |
| 우편 보상 이름 | 영어 "Pearl pack ×2", "Reward ×1", 한국어 "진주 꾸러미 ×2", "보상 ×1". ID(`pearl_pack`, `unknown_item`)가 드러나지 않는다 | 설계대로 |
| 작은 가로 카드 | compact 항목 2개는 `HBoxContainer` 높이 44, 기본 카드는 `VBoxContainer` 79x141 그대로 | 설계대로 |

거부 이유 줄이 스크롤 보기 안에 보이는 높이(보기 아래 끝 기준, 단위 px, 스크롤 0인 처음 화면):

| 제품과 창 | 영어 | 영어 큰 글자 | 한국어 | 한국어 큰 글자 |
|---|---|---|---|---|
| 세로 제품 390x844 | 47/47 | 53/53 | 22/22 | 53/53 |
| 세로 제품 320x568 | 46/47 | **8/53** | 47/47 | 53/53 |
| 세로 제품 844x390 | **18/22** | **7/25** | **18/22** | **7/25** |
| 세로 제품 1280x720 | 22/22 | 25/25 | 22/22 | 25/25 |
| 가로 제품 568x320 | **0/22** | **0/25** | **0/22** | **0/25** |
| 가로 제품 844x390 | **0/25** | **0/32** | **0/25** | **0/32** |
| 가로 제품 1280x720 | **29/48** | **0/56** | **29/48** | **3/56** |

가로 제품에서 처음 화면과 거부 뒤 화면의 픽셀 차이는 568x320과 844x390에서 82~184픽셀(스크롤 막대 손잡이 길이만 바뀜)이라 사용자에게는 같은 화면으로 보인다.

## 인수조건 판정

| 조건 | 결과 | 근거 |
|---|---|---|
| PR-1 | pass | 여정 4개 크기, 보조 (b). 첫 누름은 저장 바이트를 바꾸지 않고 취소, 뒤로, 닫기, Android 뒤로 가기, 다시 그리기가 모두 무장을 푼다. 빠른 두 번 누름은 R1-2 |
| PR-2 | **fail** | 저장 바이트 동일, 무장 해제, 훅 없는 공용 초기화(API)는 통과. "이유를 보여 주며"는 세로 제품 844x390(여정 캡처에서 글자 아래가 잘림), 320x568 큰 글자, 가로 제품 568x320·844x390·1280x720에서 지켜지지 않는다(R1-1) |
| PR-3 | pass | 여정의 다시 읽은 저장(코인·안내·홈 레벨 처음, 설정·`intro_seen`·`ui.commerce`·제품이 고른 키 유지, 다른 제품 키 삭제, 저장 버전 3, 신호 1회, 시작하면 안내). 보조 (a), (c), (d) |
| PR-4 | pass | 여정의 서버 모드와 훅 없는 제품 단계 |
| PR-5 | pass | 여정 `late-server-response-preserves-navigation`의 이름 단계, ui-kit 115/0, 보조 우편·카드 캡처 |
| PR-6 | pass | `test_bundle` 1.3.0 설치·역설치 거부, `test_ui_contract`(1.3.0 아래 skin 1.1.0), `bundle.py verify` |
| PR-7 | **fail(844x390 거부 상태)** | 기본·무장·완료·한국어 캡처는 네 크기 모두 잘리지 않고 읽힌다. 844x390 `reset-progress-refused`의 이유 줄은 스크롤 보기 아래 끝에 걸려 글자 아래(g, p 꼬리)가 잘린다(`build/review-r1/crops/l844-refused-bottom-x3.png`, R1-1) |

## 화면 판정

캡처 위치: `build/qa-r1-390x844/`, `build/qa-r1-320x568/`, `build/qa-r1-844x390/`, `build/qa-r1-1280x720/`(최종 실행), 1차 실행 `-try1`, 보조 `build/review-r1/render-<크기>/`, 확대 crop `build/review-r1/crops/`. 모두 Read 도구로 원본 크기에서 봤다. 390x844 1차와 2차의 초기화 캡처는 기본·무장·완료·설정이 픽셀 동일, 거부는 채널 차이 16 이하만 있고, 한국어는 판 등장 모션 차이(1,898픽셀)만 있었다.

| 캡처 | 390x844 | 320x568 | 844x390 | 1280x720 | 근거 |
|---|---|---|---|---|---|
| reset-progress | pass | pass | pass | pass | 제목, 되돌릴 수 없다는 안내, 남는 것, 제품 안내, 두 버튼이 판 안에 있다. 320은 제목이 두 줄("Reset / progress")이지만 잘리지 않는다 |
| reset-progress-armed | pass | pass | pass | pass | 버튼 글자만 "Tap again to reset"으로 바뀐다. 글자로는 확인 단계가 읽히지만 판 모양은 취소와 같다(R1-3) |
| reset-progress-refused | pass | pass | **fail** | pass | 390, 320, 1280은 이유 두 줄 또는 한 줄이 보인다. 844x390은 이유 줄의 아래가 스크롤 보기 끝에서 잘린다(R1-1) |
| reset-progress-done | pass | pass | pass | pass | "Progress reset. Start again from the title." 토스트와 타이틀. 844x390에서는 토스트 왼쪽 끝이 2초 동안 스튜디오 이름 "SEORILABS REFERENCE"의 마지막 글자에 닿는다(기존 토스트 위치, 참고) |
| reset-progress-ko | pass | pass | pass | pass | 해요체 문장이 자연스럽다. 390 "되돌릴 수 / 없어요."는 낱말 단위 줄바꿈. "남는 것" 줄의 "구매"는 판 안쪽에서 끝난다(crop `ko390-kept-right-x3.png`) |
| 설정 목록의 "Reset progress"/"진행 초기화" | pass | pass | pass | pass | 390 `settings-ending`, 320 `settings-ko`, 844 보조 `r1-settings-bottom-ko`, 1280 보조 `r1-settings-bottom-en`. 크레딧·테스트실 다음, 기존 설정 버튼과 같은 판(48px) |

보조 캡처 판정:

| 캡처 | 판정 | 근거 |
|---|---|---|
| 한국어 무장·거부·큰 글자(`r1-reset-ko-*`) 4개 크기 | 무장 pass, 거부는 R1-1과 같다 | 320 무장 한 줄, 큰 글자에서도 버튼 안 |
| 가로 제품 초기화 화면(`r1-land-reset-*`) 568x320, 844x390, 1280x720 | **R1-1, R1-4** | 버튼 높이는 568x320 56, 844x390 69, 1280x720 126으로 56 이상. 568x320 영어는 "Reset progress" 버튼이 8px만 보이고 취소는 보이지 않는다. 844x390은 취소가 위 테두리만 보인다. 거부 뒤 이유가 보이지 않는다 |
| 가로 제품 설정(`r1-land-settings-*`) | pass | 목록 끝에 "Reset progress" 56px |
| 우편 이름(`r1-mail-named-en/ko`) | pass | 이름이 카드 글자 크기 20으로 읽힌다 |
| 작은 가로 카드(`r1-compact-settle`) | pass | 아이콘 44px과 "+10 coins"가 한 줄. 이 캡처는 보조 스크립트가 홈 위에 연출만 띄운 것이라 배경 겹침은 판정하지 않았다 |

버튼 크기: 세로 제품은 확인·취소 48px(4개 크기), 머리 줄 뒤로·닫기는 52x48, 320 폭에서 44x48(1.1.0부터 같은 값). 가로 제품은 56 × 배율.

## 발견 사항

- R1-1 (major, `godot/addons/seorilabs_game/flow/outgame_main.gd` `_reset_progress_screen`의 `notice` 위치, 근거 `build/qa-r1-844x390/reset-progress-refused.png`, `build/review-r1/crops/l844-refused-bottom-x3.png`, `build/review-r1/render-568x320-landscape/r1-land-reset-refused-ko.png`, `render-844x390/r1-land-reset-refused-en.png`, `render-1280x720/r1-land-reset-refused-en.png`, `render-320x568/r1-reset-en-refused-large.png`, 위 표): 거부나 저장 실패의 이유를 스크롤 목록 맨 끝(취소 버튼 아래)에 붙이고 토스트는 띄우지 않는다. 그래서 화면 높이가 낮으면 이유가 보이지 않는다. 실패 시나리오: 가로 게임(1280x720 기준 캔버스가 휴대폰에서 568x320 배치로 줄어드는 구성)의 플레이어가 진행 초기화를 두 번 눌렀는데 제품이 거부하거나 디스크 쓰기가 실패하면, 화면은 처음과 픽셀까지 거의 같고(스크롤 막대만 다름) 버튼 글자만 "Reset progress"로 돌아온다. 플레이어는 실패했다는 것도 이유도 모른 채 같은 동작을 되풀이한다. 세로 제품도 844x390 창에서는 이유 줄 아래가 잘리고, 320x568 큰 글자에서는 53px 중 8px만 보인다. 설계 PR-2 "이유를 보여 주며"와 PR-7 "잘리지 않고"에 어긋난다. 고칠 방법: 이유를 안내 문단 바로 아래(버튼 위)에 두거나, 같은 이유를 `layers.toast`로도 띄우고, 가로 제품 568x320에서 이유가 보이는지를 여정이나 probe에 넣는다.
- R1-2 (major, `_reset_progress_screen`의 무장 람다, 근거 보조 스크립트 `r1-fast-double-tap`, `facts.json`의 `double_tap`): 첫 누름과 둘째 누름 사이에 최소 시간이 없다. 같은 자리를 31~40ms 간격으로 두 번 누르면(렌더 실행 5회 중 확인 버튼이 스크롤 보기 안에 있던 390x844, 320x568, 844x390, 1280x720 네 크기 모두. 568x320 창에서는 버튼이 보기 밖이라 누름이 닿지 않았다) "Tap again to reset"이 그려지기 전에 초기화가 확정된다. 실패 시나리오: 버튼을 습관처럼 두 번 누르거나 첫 누름 뒤 반응이 없다고 느껴 바로 다시 누른 플레이어는 확인 문구를 보지 못한 채 모든 진행을 잃는다. 되돌릴 수 없는 공용 동작이고 모든 소비 게임(다음은 betta-raising)에 같이 들어가므로 확인 단계가 이 경우를 막아야 한다. 고칠 방법: 무장 뒤 0.5~1초 동안 둘째 누름을 무시하거나, 확인 버튼을 무장 때 다른 자리(취소 자리와 바꾸기 등)로 옮긴다. R1-3과 함께 고치면 좋다.
- R1-3 (minor, 같은 람다, 근거 `build/qa-r1-390x844/reset-progress-armed.png`): 무장하면 글자만 바뀌고 판은 취소와 같은 기본 판이다. 설계가 같은 방식이라고 적은 테스트실은 무장 버튼을 `PrimaryButton`(금색)으로 바꾼다(`dev/test_room.gd:235`). 실패 시나리오: 화면을 훑어보는 플레이어가 무장 상태를 알아차리지 못하고, 두 공용 화면의 확인 문법이 다르게 보인다. 고칠 방법: 무장 때 테스트실처럼 판 변형을 바꾸고, 해제 때 되돌린다.
- R1-4 (minor, `_reset_progress_screen` 배치, 근거 `build/review-r1/render-568x320-landscape/r1-land-reset-en.png`, `render-844x390/r1-land-reset-en.png`): 가로 제품 568x320에서 영어 화면은 안내 세 문단이 보기 높이(164px)를 거의 채워 "Reset progress" 버튼이 8px만 보이고 취소는 보이지 않는다. 844x390에서는 취소가 위 테두리만 보인다. 스크롤 막대가 있어 끌면 보이고, 머리 줄의 뒤로·닫기는 늘 보인다. 실패 시나리오: 가로 게임 플레이어가 화면을 열면 글만 보이고 누를 버튼이 없어 보인다. 파괴적인 버튼이 먼저 보이고 안전한 취소가 가려지는 배치이기도 하다. 고칠 방법: 가로에서는 확인과 취소를 한 줄에 나란히 두거나, 안내 문단을 줄인다.
- R1-5 (minor, 공용 문구 "Kept: settings, language, scenes you have seen and purchases you can restore."와 `godot/reference/bootstrap/main.gd`의 `progress_was_reset` 연결, 근거 보조 `r1-ending-seen-reset`): 엔딩을 본 map 제품에서 초기화 화면은 "본 장면"이 남는다고 말하지만, 초기화 뒤 설정의 "Replay ending"이 사라진다. 실제로 남는 것은 프롤로그를 다시 자동 재생하지 않는 기록(`intro_seen`)뿐이다. 실패 시나리오: 엔딩 다시 보기를 남기려고 문구를 믿고 초기화한 플레이어가 다시 보기를 잃는다. 고칠 방법: 공용 문구를 "처음 장면은 다시 나오지 않아요"처럼 `intro_seen`에 맞게 좁히거나, 제품이 남는 것 문구를 덮어쓸 수 있게 하거나, 레퍼런스가 엔딩 본 기록을 지우지 않는다.
- R1-6 (minor, `_apply_progress_reset`의 `_error_text(state.error)`, 근거 보조 `r1-invalid-product-next`, `render-*/r1-reset-invalid-product.png`): 제품 훅이 공용 스키마에 맞지 않는 next를 돌려주면 `save_schema_invalid`가 되어 "The save could not be read. Your data was preserved."(한국어 "저장을 읽지 못했습니다. 기존 데이터는 보존했습니다.", 합쇼체)를 보인다. 저장은 읽혔고 초기화가 거부된 것이라 문구가 사실과 다르다. 실패 시나리오: 제품 훅 버그가 있을 때 플레이어는 저장이 망가졌다고 오해해 지원 문의를 하거나 앱을 지운다. 고칠 방법: 초기화 경로에서는 `save_schema_invalid`를 `reset_refused` 문구로 바꿔 보인다.
- R1-7 (minor, 검수 환경, R5-2와 같은 계열, 근거 `build/qa-r1-390x844-try1/scroll-boundary/journey.json`, `build/qa-r1-320x568-try1/camp/journey.json`, `build/review-r1/render-390x844/journey.json`, `render-568x320-landscape/journey.json`, `build/logs/godot-monitor.log`): 렌더 check.py 6회 중 2회가 부속 probe의 입력 무시로 실패했고, 보조 스크립트도 렌더 5회 중 2회에서 새 창의 첫 탭이 무시됐다. 같은 명령의 재실행과 headless는 모두 통과했다. 390x844 실패 때는 다른 렌더 프로세스가 없었고, 320x568 camp 실패 때는 다른 세션의 렌더 창이 실패 2초 전에 떴다. 이번 후보가 바꾼 `scroll_into_view`와 `_settle`은 끌기가 무시된 경우 이전 코드와 같은 값(false)을 돌려주므로 이 실패를 만들거나 숨기지 않는다고 판단했다. 원인은 확정하지 못했다. 실패 시나리오: 다음 회차가 이 실패를 후보 회귀로 오인하거나, 실제 회귀를 환경 탓으로 넘긴다. 드라이버가 렌더 창의 포커스 이탈이나 첫 입력 전 창 활성화를 기록하면 구분할 수 있다(범위 밖).
- R1-8 (minor, `docs/design/2026-11-11-input-layout/design.md`): 이 PR로 main에 들어가는 문서인데 띄어쓰기가 빠진 문장이 많고("사용자는2026-11-11", "추가독립검수1회를"), 마지막 문단이 "현재사용중인f1da40e안정묶음에패치한다", "main/원격/PR/배포는이작업끝점에포함하지않는다"처럼 betta 로컬 브랜치 기준의 범위를 그대로 적는다. 실패 시나리오: game-foundation main을 읽는 다음 작업자가 이 수정이 main 범위가 아니라고 읽거나, 어느 묶음에 들어갔는지 오해한다. 고칠 방법: 원래 실패, 고친 판정 조건, 1.3.0에 들어갔다는 사실만 남겨 다시 쓴다.

## 판정

fail. 새 진행 초기화 화면의 기본, 무장, 완료, 한국어 상태는 네 크기 모두 잘리지 않고 읽히고, 저장 처리(남기는 필드, 제품 키 정리, 한 번의 쓰기, 바이트 보존, 신호 1회, 구매 진행 기록과 분석 사건 유지)는 여정과 보조 재현 모두에서 설계대로 동작했다. 베타에서 옮긴 우편 이름, 작은 가로 카드, E2E 드라이버 수정도 회귀가 없다.

실패 이유는 major 두 건이다. R1-1은 거부나 저장 실패의 이유가 목록 맨 아래에 붙어 세로 제품 844x390 캡처에서 잘리고(PR-7), 가로 제품 568x320·844x390에서는 전혀 보이지 않는 것이다(PR-2). 원본 PNG와 사각형 측정으로 확인했다. R1-2는 확인 단계가 빠른 두 번 누름을 막지 못해 되돌릴 수 없는 초기화가 확인 문구 없이 확정되는 것이다. 렌더 4개 크기에서 재현했다. minor 여섯 건(R1-3~R1-8)은 이번 판정에 영향을 주지 않지만 R1-3, R1-4는 R1-1, R1-2와 같은 자리를 고칠 때 함께 다루는 것이 좋다.

PR-7 최종 판정: 390x844 pass, 320x568 pass, 844x390 fail(거부 상태의 이유 줄 잘림), 1280x720 pass.

## 증적 보관

검수 캡처와 로그 원본은 이 worktree의 `build/` 아래에만 있다(`qa-r1-390x844`, `qa-r1-320x568`, `qa-r1-844x390`, `qa-r1-1280x720`, 1차 실패 출력 `qa-r1-390x844-try1`, `qa-r1-320x568-try1`, `npm test`의 headless 출력 `e2e/8a2705…`, `review-r1/`(보조 스크립트 `reset_probe.gd`, 렌더 확인 `guard.sh`, 감시 `monitor.sh`, 실행 스크립트, headless·렌더 결과, crop, 사용자 폴더 목록), `logs/`). 전체 약 180MB. NAS1dual 이관은 구현자가 PR 정리 단계에서 한다.
