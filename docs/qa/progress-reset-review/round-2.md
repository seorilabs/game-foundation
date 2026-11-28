# 진행 초기화와 베타 공용 수정 독립 검수 2회차

- 검수자: 독립 검수 에이전트 2 (구현자, 1회차 검수자와 다른 에이전트)
- 승인 근거: 2026-11-28 사용자 계획 승인(설계 `docs/design/2026-11-28-progress-reset/design.md`의 상태 줄, 테스트 계획 `test-plan.json` L3, dev, redesign, release null, 기기 사용 없음)
- 대상: seorilabs/game-foundation PR #32 `feat/progress-reset-betta-upstream`, 후보 SHA `8f43b2462db51feb4078fc3356f01cc7a1b95e15`, 기준 main `4071d7be7ff6d4f11e3fd043bd6e4b05146fff05`(fetch 뒤 origin/main, 후보의 merge-base와 같음)
- 변경 규모: 기준 대비 `git diff --stat 4071d7b..8f43b24` 27개 파일, 706줄 추가, 42줄 삭제(커밋 12개). 1회차 뒤 수정은 `git diff --stat 1afbf05..8f43b24` 6개 파일, 253줄 추가, 28줄 삭제(`ea7fea3` 수정, `8f43b24` 잠금 갱신, 이 중 152줄은 1회차 기록). 공용 묶음 1.3.0, 96개 파일, 잠금 원본 커밋 `ea7fea3`
- 크기: 390x844, 320x568, 844x390, 1280x720 (4개 모두 판정). 레퍼런스 여정은 세로 제품을 네 창 크기로 띄우고, 새 시나리오 `landscape-reset-progress`는 같은 창에서 띄운 뒤 `landscape = true`로 바꾼다. 실제 가로 제품(띄우기 전에 `landscape = true`)은 보조 스크립트로 568x320, 844x390, 1280x720, 390x844를 따로 봤다
- 실행 시각: 2026-11-28 04:35–05:03 UTC
- 실행 환경: dev headless 검증 + 렌더링 캡처. Godot 4.7.2.stable.official.ed1daf0bf(Compatibility, Apple M3), macOS 27.2.1, Python 3.14.7, Node 24.16.0. 격리 worktree `game-foundation.worktrees/review-progress-r2`(detached `8f43b24`). 같은 시간에 다른 세션이 bloomhand, infect-everything, betta-raising의 Godot를 돌렸다(headless 검사와 렌더 여정). 렌더 실행 전마다 `build/review-r2/guard.sh`로 확인했고(`build/logs/guard.log`), 04:41:35부터 별도 감시 루프(`build/logs/godot-monitor.log`, 2초 간격)가 이 worktree 밖의 비 headless Godot를 기록했다. 저장은 여정과 보조 스크립트의 격리 프로필만 썼고, 실행 뒤 이번 실행이 만든 `Game Foundation Reference` 사용자 폴더 항목 40개를 지웠다(아래 정리)
- 설계: `docs/design/2026-11-28-progress-reset/design.md` PR-1~PR-7, "사용자 흐름·화면 상태", "데이터·인터페이스·실패 처리", "품질 요구사항", "독립 검수". 이전 회차 `docs/qa/progress-reset-review/round-1.md`(fail, R1-1~R1-8)

## 검수 계획

실행 전에 적은 계획이다(04:36 UTC, `godot --headless --path godot --import`만 먼저 실행, 종료 0, ERROR 0). 이번 회차는 1회차 major 두 건(R1-1 거부 이유가 가로에서 안 보임, R1-2 빠른 두 번 누름으로 확인 없이 확정)이 실제로 풀렸는지를 원본 캡처와 재현으로 다시 확인하고, 그 수정(이유 위치 이동, 토스트, 0.6초 확인 지연, 무장 판 변경, 가로 한 줄 버튼, 남는 것 문구 축소, 스키마 위반의 거부 문구)이 새로 만든 문제가 없는지 본다. 1회차 판정을 그대로 믿지 않고 새 화면 전체를 네 크기에서 다시 본다.

| 순서 | 영역 | 내용 | 통과 기준 |
|---|---|---|---|
| 0 | 환경 | 렌더 실행 전마다 `build/review-r2/guard.sh`로 실제 Godot 실행 파일 프로세스(셸 명령 줄과 godot-mcp 제외)를 `build/logs/guard.log`에 기록한다. 다른 저장소의 비 headless(렌더) Godot가 있으면 30초 간격으로 최대 10분 기다린다. 다른 저장소의 headless 실행은 허용하고 기록한다 | 렌더 시작 시 다른 렌더 프로세스 없음 |
| 1 | 기능 | `npm test`(단위 + headless check.py), `python3 tools/bundle.py verify` | 종료 0, 건너뜀 없음, verify ok(1.3.0, 잠금 원본 `ea7fea3`) |
| 2 | 렌더링 | `python3 tools/check.py --capture --size <크기> --out build/qa-r2-<크기>`를 390x844, 320x568, 844x390, 1280x720으로. 진행 초기화와 무관한 공용 probe·시간 단계(`reward ceremony impact`, `e2e_scroll_probe`, `camp_probe` 등)가 겹친 부하에서 실패하면 한 번만 다시 돌리고 실패 출력은 `-try1`로 남긴다. 진행 초기화 시나리오의 실패는 재실행으로 덮지 않는다 | 4개 모두 종료 0, 여정의 모든 시나리오 passed(새 `landscape-reset-progress` 포함) |
| 3 | 새 화면 | Read 도구로 `reset-progress`, `reset-progress-armed`, `reset-progress-refused`, `reset-progress-done`, `reset-progress-ko`, `reset-progress-landscape`, `reset-progress-landscape-refused`를 4개 크기 모두 원본으로 본다. 필요하면 확대 crop을 `build/review-r2/crops/`에 만든다 | 잘림 없음, 글자 읽힘, 버튼 높이 세로 48px·가로 56px 이상, 지우는 것과 남는 것을 알 수 있음, 무장 상태가 확인 단계로 읽힘, 거부 이유가 버튼 위에 보임, 다른 공용 화면과 같은 판·버튼, 한국어 해요체가 자연스러움 |
| 3a | 설정 진입 | 진행 초기화 항목이 보이는 설정 캡처를 찾아 본다. 없으면 보조 스크립트로 설정 목록 끝을 찍는다 | 항목이 크레딧·테스트실 다음에 기존 설정 버튼과 같은 판으로 있음 |
| 4 | 1회차 지적 재현 | `build/review-r2/` 아래 일회용 스크립트(추적 파일 수정 없음, headless와 렌더 둘 다)로 아래를 재현한다 | 아래 기준 |
| 4a | R1-1 | 가로 제품(`landscape = true`를 띄우기 전에 정함)을 568x320, 844x390, 1280x720에서, 세로 제품을 844x390, 320x568에서 영어·한국어 × 보통·큰 글자로 연다. 처음 화면(스크롤 0)과 거부 뒤 화면에서 확인·취소 버튼, 거부 이유 줄의 사각형이 스크롤 보기 안에 몇 px 보이는지 잰다. 거부 원인 세 가지(제품 거부 `{}`, 스키마 위반 next, 디스크 쓰기 실패 `save_failed`)를 다 본다. 토스트가 뜨는지, 제목·뒤로·닫기나 이유를 가리는지 본다 | 모든 경우 이유 줄 전체와 두 버튼이 처음 보기 안에 있음, 토스트 1개 |
| 4b | R1-2 | 버튼 중심에 누름·뗌을 실제 시간 간격으로 직접 넣는다(`e2e.tap`의 프레임 대기 없이). 첫 누름 뒤 30ms, 60ms, 300ms 둘째 누름은 초기화하지 않아야 하고, 700ms 뒤 둘째 누름은 초기화해야 한다. 0ms·300ms·550ms 연타(셋째 누름도 0.6초 안), 첫 누름 뒤 무장 문구가 실제로 그려지는 시점도 기록한다 | 0.6초 안의 누름은 저장 바이트 동일, 0.7초 뒤 누름은 타이틀로 이동 |
| 4c | 키보드 | 확인 버튼에 초점을 두고 Enter, Space를 50ms 간격으로 두 번 누른다. Enter를 누른 채(반복 echo 이벤트) 둔다. 0.7초 뒤 Enter 한 번은 확정된다 | 빠른 두 번과 누른 채 유지는 초기화하지 않음, 의도한 확정은 됨 |
| 4d | 무장 중 나가기 | 무장 뒤 뒤로(‹), 닫기(×), Android 뒤로 가기 알림, 다시 열기 | 무장 해제, 저장 바이트 동일 |
| 4e | 거부 뒤 상태 | 거부 뒤 다시 그린 화면의 무장 해제, 초점 위치, 곧바로 다시 무장·확정(0.7초 뒤)이 되는지 | 설계대로 |
| 4f | R1-3~R1-6 | 무장 판(`PrimaryButton`)과 테스트실 무장 판의 일치, 가로 한 줄 배치, 엔딩 본 map 제품에서 "남는 것" 문구와 초기화 뒤 "엔딩 다시 보기"의 일치, 스키마 위반의 문구 | 1회차 지적 해소 |
| 4g | R1-7, R1-8 | 이번 실행의 렌더 probe 실패 여부를 기록하고, `docs/design/2026-11-11-input-layout/design.md`를 읽는다 | 기록, 문서 사실과 일치 |
| 5 | 문서·계약 | 설계의 화면 표·인터페이스, 코드 주석, README와 실제 동작이 같은지 읽어서 확인한다 | 일치 |
| 6 | 정리 | 이번 실행이 만든 `Game Foundation Reference` 사용자 폴더 항목을 실행 전 목록(`build/review-r2/userdata-before.txt`)과 생성 시각으로 찾아 지운다. `build/` 출력과 worktree는 남긴다 | 이번 실행 항목 0개 남음 |
| 7 | 판정 | 인수조건별 결과, 화면별 판정, 1회차 지적별 해소 여부, 새 발견 사항(실패 시나리오, blocker/major/minor) | blocker·major가 원본 PNG나 재현으로 확인되지 않으면 pass |

실행 중 계획에 더한 것: 렌더 check.py 1차에서 320x568과 1280x720이 진행 초기화와 무관한 단계(엔딩 컷신 카운트업, `ui_navigation_probe`)로 실패해 계획대로 한 번씩 다시 돌리고 실패 출력은 `-try1`로 남겼다. 여정 캡처 `reset-progress-done.png`에서 거부 토스트와 성공 토스트가 함께 보여 원인을 코드로 확인했다. 여정의 가로 시나리오가 띄운 뒤 `landscape`를 바꾼다는 것을 보고, 보조 스크립트의 가로 캡처(띄우기 전에 정함)와 글자 배율을 비교했다. 거부 뒤 초점이 사라지는 것을 보고 Tab과 아래 화살표로 초점을 되찾는지 더 봤다.

## 실행 명령과 결과

모든 명령은 격리 worktree 루트에서 실행했다. 실행 시각과 종료 코드는 `build/logs/runs.log`, 렌더 전 확인은 `build/logs/guard.log`, 명령별 출력은 `build/logs/<이름>.log`에 있다.

| 순서 | 명령 | 결과 |
|---|---|---|
| 0 | `git fetch origin`, `git worktree add --detach .../review-progress-r2 8f43b24…` | 종료 0. origin/main `4071d7b`가 후보의 merge-base와 같다 |
| 1 | `godot --headless --path godot --import` | 종료 0 (04:35:30–04:35:35), ERROR 0 |
| 2 | 렌더 실행 전마다 `build/review-r2/guard.sh` | 렌더 실행 7회(check.py 6회, 보조 스크립트 1회)와 import, `npm test` 앞에서 실행했다. 대기는 844x390 1차 앞 한 번(90초, 04:39:53–04:41:23)이다. 그때 bloomhand의 렌더 여정(pid 97992, 98978, `journey.tscn`)이 떠 있었다. 감시 루프는 내 렌더 실행 중에 다른 저장소의 렌더 창을 여러 번 기록했다(844x390 1차 중 04:42:03–04:42:38 infect-everything·bloomhand, 1280x720 1차 중 04:44:48–04:45:03 bloomhand `box_screens`, 320x568 2차 중 04:47:39–04:48:29 bloomhand, 보조 렌더 중 05:00:36–05:01:40 infect-everything·bloomhand). guard는 시작 시점만 막으므로 실행 도중 겹침은 막지 못했다 |
| 3 | `npm test` | 종료 0 (04:36:34–04:37:35). 단위 테스트 36개 OK(건너뜀 0, `test_contract_1_3_0_installs_over_1_2_0_and_downgrade_refused` 포함), headless check.py `{"ok": true, "scenarios": 16}`, 여정 268단계, ui-kit 115/0, dev 26/0, ui-contract 87/0 |
| 4 | `python3 tools/bundle.py verify` | 종료 0. ok, version 1.3.0, files 96, source commit `ea7fea3…` |
| 5 | `check.py --capture --size 390x844 --out build/qa-r2-390x844` | 종료 0 (04:37:52–04:38:58), 16개 시나리오 |
| 6 | 같은 명령 320x568 1차 | **종료 1** (04:38:58–04:39:53). 여정 `settings-credits-and-ending-replay / count-up uses the shared number format expected=12,800, actual=0` 한 단계만 실패했고 진행 초기화 시나리오 두 개는 통과했다. `ending-count.png`를 찍은 시각(04:39:40)에 bloomhand 렌더 창(pid 97992, 04:39:53에 실행 13초)이 막 떴다. 컷신은 창 포커스를 잃으면 멈춘다(ui-kit "focus loss pauses"). 출력 `build/qa-r2-320x568-try1/`, 로그 `build/logs/render-320x568-try1.log` |
| 7 | 같은 명령 844x390 | 종료 0 (04:41:23–04:43:02), 16개 시나리오. 실행 중 다른 렌더 창이 있었지만 통과 |
| 8 | 같은 명령 1280x720 1차 | **종료 1** (04:43:02–04:47:12). 여정 16/16 통과(269단계), 부속 `ui_navigation_probe`가 첫 단계 `request provider UI`(홈의 리더보드 누름)에서 실패한 뒤 04:44:13 캡처 다음에서 멈춰 check.py의 180초 제한으로 끝났다. 그 시각에 감시 루프가 기록한 다른 렌더 창은 없었다. 제한 시간 종료라 그 probe의 Godot 로그는 남지 않았다. 출력 `build/qa-r2-1280x720-try1/` |
| 9 | 320x568 2차 | 종료 0 (04:47:24–04:48:38), 16개 시나리오, camp 2/2, navigation 3/3 |
| 10 | 1280x720 2차 | 종료 0 (04:48:38–04:49:48), 16개 시나리오, navigation 3/3 |
| 11 | 보조 `build/review-r2/r2_probe.gd` headless | 첫 시도(04:50:19)는 보조 스크립트의 타입 추론과 상수 이름 오류로 불러오지 못했다(Godot 종료 0, SCRIPT ERROR). 고친 뒤 `--only ending`(04:50:28) 종료 0, 전체(04:50:33–04:54:50) 종료 0, ERROR 0, 시나리오 87/87. 초점 확인을 더한 `--only failures`(04:56 전, `headless-dbg2/`) 종료 0. 결과 `build/review-r2/headless/` |
| 12 | 같은 보조 스크립트 렌더(`--capture`) | 종료 0 (04:56:44–05:01:37), ERROR 0, 시나리오 87/87, 캡처 163장. 결과 `build/review-r2/render/` |
| 13 | 사용자 폴더 정리 | 실행 전 목록(1045개)과 비교해 새로 생긴 40개(`e2e-ui-standard-*` 7, `outgame-contract-*` 7, `first-light-e2e-*` 6, `e2e-review-1-{commerce,keyboard,native}-*.json` 16, `review-r2-*` 4)를 지웠다. 모두 04:36:51–04:56:44 UTC에 생겼다. 정리 뒤 항목 수는 실행 전과 같다(1045). 기존 `logs/` 폴더는 공용 로그 폴더라 남겼다 |

## 기능 결과

| 항목 | 결과 | 근거 |
|---|---|---|
| 여정 | 16/16 passed, 4개 크기 모두(최종 실행), headless도 같음 | 단계 268개(1280x720은 269개). `settings-reset-progress` 37단계(빠른 둘째 누름 무시, 무장 판, 토스트, 이유가 버튼 위 포함), 새 `landscape-reset-progress` 7단계 |
| ui-kit, dev, ui-contract probe | 115/0, 26/0, 87/0 | 4개 크기 최종 실행과 headless |
| outgame contract probe | 통과 | 각 check.py 실행의 `godot-1.log` |
| 부속 probe | input-layout 1/1, studio-splash 1/1, scroll-boundary 1/1, camp 2/2, navigation 3/3 | 최종 실행 4개 크기. 1차 실패 2건은 위 6, 8과 R1-7 |
| 묶음·버전 | pass | `bundle.py verify` ok 1.3.0, `test_bundle`(1.3.0 위 설치·역설치 거부 포함), `test_ui_contract` |

보조 재현 결과(`build/review-r2/render/facts.json`, headless는 `build/review-r2/headless/facts.json`. 두 모드의 측정값이 같다):

거부 뒤 이유 줄과 버튼이 처음 보기(스크롤 0) 안에 보이는 높이(보인 px/전체 px). 1회차 같은 표에서 실패한 칸을 모두 포함한다.

| 제품과 창 | 영어 | 영어 큰 글자 | 한국어 | 한국어 큰 글자 | 확인·취소 버튼 |
|---|---|---|---|---|---|
| 세로 제품 390x844 | 47/47 | 53/53 | 22/22 | 53/53 | 48/48 |
| 세로 제품 320x568 | 47/47 | 53/53(1회차 8/53) | 47/47 | 53/53 | 48/48 |
| 세로 제품 844x390 | 22/22(1회차 18/22) | 25/25(7/25) | 22/22 | 25/25 | 48/48 |
| 세로 제품 1280x720 | 22/22 | 25/25 | 22/22 | 25/25 | 48/48 |
| 가로 제품 568x320 | 22/22(1회차 0/22) | 25/25(0/25) | 22/22 | 25/25 | 56/56, 영어 큰 글자만 54/56 |
| 가로 제품 844x390 | 25/25(0/25) | 32/32(0/32) | 25/25 | 32/32 | 69/69 |
| 가로 제품 1280x720 | 48/48(29/48) | 56/56(0/56) | 48/48 | 56/56 | 126/126 |

| 경우 | 결과 | 판정 |
|---|---|---|
| 처음 화면의 버튼(가로 제품) | 568x320, 844x390, 1280x720 모두 확인과 취소가 한 줄에 전부 보인다(56/56, 69/69, 126/126) | R1-4 해소 |
| 빠른 두 번 누름(세로 390x844, 가로 568x320) | 같은 프레임 두 번, 33ms, 61ms, 300ms, 550ms, 0·300·550ms 세 번 모두 초기화하지 않았다(화면 유지, 바이트 동일, 신호 0). 렌더에서 첫 누름과 33ms 둘째 누름 사이에 4프레임이 그려져 무장 문구가 먼저 보인다 | R1-2 해소 |
| 0.7초 뒤 둘째 누름 | 701~715ms에 누르면 모든 위치(세로 390x844, 320x568, 844x390, 1280x720, 가로 568x320, 844x390)에서 타이틀로 가고 신호 1회. 33ms·300ms는 같은 위치 모두 무시 | 설계대로. 의도한 확정을 막지 않는다 |
| 300ms 뒤 한 번, 700ms 뒤 한 번 | 둘째(300ms)는 무시, 셋째(701~706ms)에 초기화된다. 지연은 무장 시각부터 센다 | 설계대로(참고) |
| 키보드 | Enter 두 번(50ms), Space 두 번, 숫자판 Enter 두 번, Enter 두 번(300ms)은 무장만 하고 바이트 동일. Enter를 1.5초 누른 채(40ms마다 echo)도 무장만 한다. 0.7초 뒤 Enter는 초기화한다 | 통과 |
| 무장 중 나가기(세로, 가로) | 뒤로(‹)와 Android 뒤로 가기 알림은 설정, 닫기(×)는 홈으로 간다. 0.8초 기다린 뒤 뒤로도 같다. 모두 바이트 동일, 다시 열면 "Reset progress"와 기본 판 | 통과 |
| 거부 원인 3가지 × 세로·가로 × 영어·한국어 | 제품 거부와 스키마 위반은 "Progress could not be reset. Nothing was changed." / "진행을 초기화하지 못했어요. 바뀐 것은 없어요."를 토스트와 경고 아래 두 곳에 보인다. 디스크 쓰기 실패(`save_failed`)는 "Could not save. Try again." / "저장하지 못했습니다. 다시 시도해 주세요."를 같은 두 곳에 보인다. 12경우 모두 바이트 동일, 신호 0, 무장 해제 | R1-6 해소. `save_failed` 문구는 R2-5 |
| 거부 뒤 다시 시도 | 원인을 없앤 뒤 같은 화면에서 무장, 0.7초 뒤 누르면 12경우 모두 초기화되고 신호 1회 | 통과 |
| 거부 뒤 초점 | 다시 그린 화면에 초점이 없다. Tab을 누르면 뒤로(‹), 아래 화살표를 누르면 확인 버튼으로 간다 | 키보드로 되찾을 수 있어 지적하지 않음(같은 화면 다시 그리기를 쓰는 다른 공용 화면과 같다) |
| 엔딩을 본 map 제품 | 초기화 화면의 남는 것 문구는 "the opening scene you have seen". 초기화 전 설정에 "Replay ending"이 있고 뒤에는 없다. 타이틀에서 시작하면 프롤로그 없이(`intro_seen` 참, 컷신 idle) 안내부터(`tutorial.status` active, step 0) 시작한다 | R1-5 해소 |
| 무장 버튼 높이(한국어) | 세로 320x568 48→60, 가로 568x320 56→60(큰 글자 64), 가로 제품 390x844 큰 글자 56→89, 영어 가로 제품 390x844 56→70. 무장하는 순간 아래 줄이 그만큼 내려간다(320x568 취소 y 227→239) | R2-2 |
| 가로 568x320 처음 화면의 남는 것·제품 안내 | 영어 "Kept" 줄 33/47(큰 글자 23/53), 제품 안내 0/22. 거부 뒤에는 "Kept" 줄도 0/47. 한국어는 처음 화면에 둘 다 보인다 | R2-3 |
| 토스트 위치 | 거부 토스트는 모든 경우 1개다. 32경우 중 27경우에서 머리 줄(제목, 뒤로, 닫기) 일부나 전부와 2초 동안 겹친다. 이유 줄이나 확인·취소 버튼과는 겹치지 않는다. 토스트는 입력을 받지 않는다(ui-kit "toast … ignores input") | 참고 |

## 인수조건 판정

| 조건 | 결과 | 근거 |
|---|---|---|
| PR-1 | pass | 여정 4개 크기(첫 누름은 무장과 주 버튼 판만, 빠른 둘째 누름 무시, 취소, 다시 열면 해제), 보조 무장 중 나가기 8경우, 키보드 6경우 |
| PR-2 | pass | 여정 4개 크기의 "reason sits above the buttons on screen", "landscape reason is on screen", "an invalid product result reads as a refusal". 보조 측정에서 세로·가로 제품 32경우 모두 이유 줄 전체가 처음 보기 안에 있다. 거부 원인 3가지 모두 바이트 동일, 무장 해제. 훅 없는 공용 초기화(API)는 outgame contract probe |
| PR-3 | pass | 여정의 다시 읽은 저장, 신호 1회, 타이틀에서 시작하면 안내부터. 보조 엔딩 경우 |
| PR-4 | pass | 여정 `settings-reset-progress` 마지막 단계(서버 모드, 훅 없는 제품) |
| PR-5 | pass | 여정 `late-server-response-preserves-navigation`, ui-kit 115/0(작은 가로 카드 4개 포함). 1회차 뒤 이 영역의 코드 변경은 없다 |
| PR-6 | pass | `test_bundle`, `test_ui_contract`, `bundle.py verify`(1.3.0, 잠금 원본 `ea7fea3`) |
| PR-7 | pass | 기본·무장·거부·완료·한국어·가로·가로 거부 캡처가 네 크기 모두 잘리지 않고 읽힌다. 1회차에서 실패한 844x390 거부의 이유 줄은 22/22로 보인다. 한국어 무장 문구의 낱말 중간 줄바꿈(R2-2)은 잘림 없이 읽히므로 minor로 둔다 |

## 화면 판정

캡처 위치: `build/qa-r2-390x844/`, `build/qa-r2-320x568/`, `build/qa-r2-844x390/`, `build/qa-r2-1280x720/`(최종 실행), 1차 실행 `-try1`, 보조 `build/review-r2/render/`, 확대 crop `build/review-r2/crops/`. 모두 Read 도구로 원본 크기에서 봤다. 320x568과 1280x720의 1차·2차 초기화 캡처는 채널 차이 16 초과 픽셀이 0이다(1280x720 `reset-progress-ko` 2,932픽셀, `reset-progress-landscape` 677픽셀은 판 등장 모션 차이).

| 캡처 | 390x844 | 320x568 | 844x390 | 1280x720 | 근거 |
|---|---|---|---|---|---|
| reset-progress | pass | pass | pass | pass | 위에서부터 경고, 진행 초기화, 취소, 남는 것, 제품 안내. 320은 제목이 두 줄("Reset / progress")이지만 잘리지 않는다 |
| reset-progress-armed | pass | pass | pass | pass | 확인 버튼이 금색 주 버튼 판과 "Tap again to reset"으로 바뀌어 취소와 한눈에 구별된다. 테스트실 무장 판과 같다 |
| reset-progress-refused | pass | pass | pass | pass | 이유가 경고 바로 아래, 버튼 위에 있다. 같은 문장의 토스트가 2초 동안 머리 줄을 덮는다(390, 320은 두 줄 토스트가 제목과 ‹ × 대부분을 덮고, 844, 1280은 판 위 테두리에 걸친다). 이유를 가리지는 않는다 |
| reset-progress-done | pass(R2-1) | pass(R2-1) | pass(R2-1) | pass(R2-1) | 타이틀 위에 "Progress could not be reset. Nothing was changed."와 "Progress reset. Start again from the title." 두 토스트가 함께 있다. 여정이 거부 직후 1초 남짓 만에 다시 시도해 성공했기 때문이다. 844x390은 토스트가 스튜디오 이름과 제목 "SKYWAY" 위에 걸친다(1회차부터 같은 위치) |
| reset-progress-ko | pass | pass | pass | pass | 해요체가 자연스럽다("이 기기에서 처음부터 다시 시작해요. 되돌릴 수 없어요.", "코인, 안내, 등대 레벨이 처음으로 돌아가요."). 320은 "복 / 원할"처럼 낱말 중간에서 줄이 바뀐다(공용 Label의 한글 줄바꿈, 다른 한국어 화면도 같음, 참고) |
| reset-progress-landscape | pass | pass | pass | pass | 확인과 취소가 한 줄이다. 320 창에서는 "Reset / progress"가 두 줄이 된다. 이 시나리오는 띄운 뒤 `landscape`를 바꿔 버튼 글자와 ‹ × 기호에 가로 배율이 적용되지 않는다(844, 1280에서 본문보다 훨씬 작다). 실제 가로 제품 캡처와 다르다(R2-4) |
| reset-progress-landscape-refused | pass | pass | pass | pass | 이유 한 줄이 경고 아래, 버튼 위에 있다. 토스트는 위와 같다 |
| 설정 목록의 "Reset progress"/"진행 초기화" | pass | pass | pass(보조) | pass | 390 `settings-ending`, 320 `settings-ko`, 1280 `settings-ending`에서 크레딧·테스트실 다음, 같은 판. 844x390 여정 캡처는 테스트실까지만 보여 보조 `r2-port-844x390-en-settings.png`로 봤다 |

보조 캡처 판정:

| 캡처 | 판정 | 근거 |
|---|---|---|
| 가로 제품 568x320 기본·무장·거부(`r2-land-568x320-*`) | pass, R2-2·R2-3 | 확인·취소 56px 한 줄, 거부 이유가 버튼 위에 보인다. 영어 처음 화면은 "Kept:" 둘째 줄부터 스크롤 끝에 잘린다(crop `land568-en-kept-cut-x3.png`). 한국어 무장은 "한 번 더 누르면 초기화해 / 요", 큰 글자는 "초기 / 화해요"(crop `land568-ko-armed-x3.png`, `land568-ko-large-armed-x3.png`) |
| 가로 제품 844x390, 1280x720(`r2-land-844x390-*`, `r2-land-1280x720-*`) | pass | 버튼 69px, 126px. 띄우기 전에 가로로 정한 제품은 버튼 글자도 배율을 받아 본문과 균형이 맞다 |
| 세로 제품 320x568 한국어 무장(`r2-port-320x568-ko-armed.png`) | pass, R2-2 | "한 번 더 누르면 초기화해 / 요"로 "요" 한 글자가 둘째 줄에 남고 버튼이 48→60px로 커진다(crop `ko320-armed-x3.png`) |
| 디스크 쓰기 실패(`r2-failure-*-save-failed.png`) | pass, R2-5 | 이유와 토스트가 보이지만 한국어가 합쇼체다(crop `ko390-save-failed-x2.png`) |
| 가로 제품 설정 끝(`r2-land-*-settings.png`) | pass | 테스트실 다음 "진행 초기화", 56px 이상 |

버튼 크기: 세로 제품은 확인·취소 48px(4개 크기, 한국어 무장 때 320 폭에서만 60~64px), 머리 줄 뒤로·닫기는 52x48, 320 폭에서 44x48(1.1.0부터 같은 값). 가로 제품은 56 × 배율(568x320 56, 844x390 69, 1280x720 126).

## 1회차 지적별 해소

| 지적 | 상태 | 근거 |
|---|---|---|
| R1-1 major, 거부 이유가 버튼 아래라 가로에서 안 보임 | 해소 | 이유가 경고 아래, 버튼 위로 옮겨졌고 토스트도 뜬다. 1회차 표의 실패 칸 17개를 포함한 32경우 모두 이유 줄 전체가 처음 보기 안에 있다(위 표). 여정에도 "reason sits above the buttons on screen" 검사가 생겼다. 다만 그 여정 검사는 568x320 가로 제품을 띄우지 않는다(R2-4) |
| R1-2 major, 빠른 두 번 누름으로 확인 전 확정 | 해소 | 무장 뒤 600ms 안의 누름은 무시한다. 렌더·headless 각각 무시돼야 할 누름 24번(0~564ms, 초기화하지 않아야 할 20경우와 300ms 뒤 한 번 누른 2경우의 첫 누름)이 모두 저장을 바꾸지 않았고, 701~722ms 누름 8경우는 모두 확정했다. 키보드 연타와 Enter 누른 채 유지도 막는다 |
| R1-3 minor, 무장 판이 취소와 같음 | 해소(새 영향 R2-2) | 무장하면 `PrimaryButton`, 다시 그리면 기본 판. 테스트실과 같은 문법. 주 버튼의 표시 서체 때문에 좁은 버튼에서 한국어 문구가 낱말 중간에서 바뀐다 |
| R1-4 minor, 가로에서 버튼이 첫 화면 밖 | 해소 | 가로 제품은 확인·취소가 한 줄이고 568x320에서도 처음 화면에 전부 보인다 |
| R1-5 minor, "본 장면"이 남는다는 문구와 엔딩 다시 보기 삭제 | 해소 | 문구가 "the opening scene you have seen" / "이미 본 시작 장면"으로 좁혀졌다. 초기화 뒤 프롤로그가 다시 자동 재생되지 않고, 엔딩 다시 보기가 사라지는 것은 문구와 어긋나지 않는다 |
| R1-6 minor, 스키마 위반이 손상 문구로 보임 | 해소 | `save_schema_invalid`는 "Progress could not be reset. Nothing was changed."로 보인다(여정과 보조 4경우). 디스크 쓰기 실패의 문구는 별도 R2-5 |
| R1-7 minor, 렌더 probe의 입력 무시 실패 | 미해소(환경, 이 PR 범위 밖) | 이번에도 렌더 check.py 6회 중 2회가 진행 초기화와 무관한 단계로 실패했고 재실행은 통과했다(실행 6, 8). 320x568은 다른 저장소 렌더 창이 뜬 순간과 겹쳤고, 1280x720 navigation은 겹친 렌더 창 없이 첫 누름이 실패했다. `ui_navigation_probe`는 이 단계 실패 뒤 빈 Callable을 호출해 멈추므로 180초 제한까지 기다리고 로그를 잃는다(이 PR이 바꾸지 않은 파일, 참고). 원인은 확정하지 못했다 |
| R1-8 minor, 입력 배치 설계 문서 | 해소 | `docs/design/2026-11-11-input-layout/design.md`가 원래 실패, 고친 판정, 검증, 1.3.0 포함 사실만 띄어쓰기 맞춰 적는다. 문서의 "4번 같은 값"은 `_settle`의 `stable >= 3`(6프레임에 걸친 같은 상태 4개)과 같다 |

## 발견 사항

- R2-1 (minor, `godot/addons/seorilabs_game/flow/outgame_main.gd` `_apply_progress_reset`의 거부 토스트, 근거 여정 원본 `build/qa-r2-<4개 크기>/reset-progress-done.png`, crop `build/review-r2/crops/done390-two-toasts-x2.png`): 1회차 수정으로 거부 때 토스트(2초 + 사라짐 0.14초)를 띄우는데, 성공할 때 이전 토스트를 정리하지 않는다. 실패 시나리오: 저장 공간이 잠깐 부족해 초기화가 실패한 플레이어가 곧바로 다시 무장하고 0.6초 뒤 누르면(약 1~2초) 타이틀 위에 "진행을 초기화하지 못했어요. 바뀐 것은 없어요."가 위, "진행을 초기화했어요."가 아래에 함께 보인다. 되돌릴 수 없는 동작의 결과가 서로 반대인 두 문장으로 보여 플레이어가 초기화됐는지 헷갈린다. 여정 캡처 네 크기에서 모두 이 상태다. 고칠 방법: 성공 때 Toast 층의 이전 초기화 토스트를 지우고 성공 토스트만 띄우거나, 거부 토스트를 돌려받은 칩으로 기억했다가 성공·화면 이동 때 닫는다. 여정의 완료 단계에 "토스트가 성공 문장 하나뿐"을 더한다.
- R2-2 (minor, 같은 파일 `_reset_progress_screen`의 무장 람다 `theme_type_variation = "PrimaryButton"`, 근거 `build/review-r2/render/r2-port-320x568-ko-armed.png`, `r2-land-568x320-ko-armed.png`, `r2-land-568x320-ko-large-armed.png`, `r2-land-390x844-ko-large-armed.png`, crop `ko320-armed-x3.png`, `land568-ko-armed-x3.png`, `land568-ko-large-armed-x3.png`): 주 버튼 판은 표시 서체(Jua)를 써서 같은 폭에서 글자가 넓다. 그래서 한국어 무장 문구가 세로 320x568에서 "한 번 더 누르면 초기화해 / 요", 가로 568x320에서 "…초기화해 / 요", 큰 글자에서 "…초기 / 화해요", 가로 제품 390x844 큰 글자에서 세 줄로 낱말 중간에서 끊긴다. 버튼 높이도 48→60px(320 세로), 56→60·64px(568 가로)로 커져 무장하는 순간 취소와 아래 글이 12px 내려간다. 1회차(기본 판)에서는 320 폭에서 한 줄이었다(1회차 보조 (f)). 실패 시나리오: 가장 작은 지원 휴대폰과 가로 휴대폰의 한국어 플레이어가 확인 단계의 핵심 문장을 "초기화해 / 요"처럼 깨진 줄로 보고, 누르려던 취소가 무장 순간 아래로 움직인다. 글자는 잘리지 않고 읽히므로 minor로 둔다. 고칠 방법: 무장 문구를 "한 번 더 눌러 초기화"처럼 줄이거나, 무장 버튼의 글자 크기를 기본 버튼과 맞추거나, 한글을 띄어쓰기 단위로만 바꾸게 한다. 320x568 한국어와 568x320 한국어 무장 버튼 높이가 처음과 같은지를 여정에 더한다.
- R2-3 (minor, `_reset_progress_screen`의 배치 순서, 근거 `build/review-r2/render/r2-land-568x320-en-initial.png`, `r2-land-568x320-en-refused.png`, crop `land568-en-kept-cut-x3.png`, 측정 `facts.json` `layout.land-568x320-en*`): 가로 제품 568x320 영어 처음 화면에서 "Kept: settings, language, the opening scene you have seen and"까지만 보이고 "purchases you can restore"와 제품 안내("Coins, the guide and the lighthouse level start over.", 지워지는 것)는 스크롤 아래에 있다(Kept 33/47px, 큰 글자 23/53px, 제품 안내 0px). 거부 뒤에는 이유 줄이 더해져 "Kept" 줄도 처음 보기 밖(0/47)이다. 1회차 R1-4를 고치며 버튼을 위로 올린 결과다. 실패 시나리오: 가로 휴대폰의 영어 플레이어가 구매가 남는지, 무엇이 지워지는지를 보지 못한 채 확인하거나, 구매를 잃을까 봐 취소하고 문의한다. 경고 문장이 되돌릴 수 없음을 알리고 스크롤 막대가 있어 끌면 읽을 수 있으므로 minor다. 고칠 방법: 남는 것 문장을 "Kept: settings, language and restorable purchases."처럼 줄이거나, 가로에서는 남는 것과 제품 안내를 버튼 옆 칸에 두고, 568x320 영어에서 남는 것 줄이 처음 보기 안에 있는지를 검사에 더한다.
- R2-4 (minor, 검사와 증거, `godot/tests/reference/outgame_journey.gd` `_reset_progress_landscape`, 근거 여정 원본 `build/qa-r2-1280x720/reset-progress-landscape.png`, `build/qa-r2-844x390/reset-progress-landscape.png`와 보조 `build/review-r2/render/r2-land-1280x720-en-armed.png` 비교): 새 가로 시나리오는 세로 제품을 띄운 뒤 `main.landscape = true`로 바꾸고 `_open("reset_progress")`를 부른다. 테마 글자 크기는 `_apply_settings`에서 띄울 때 정해지므로, 이 캡처의 버튼 글자와 ‹ × 기호는 가로 배율 없이 작고(1280x720에서 본문 약 36px 대비 버튼 글자 약 16px) 배경도 캠프가 아닌 세로 로비 그림이다. 띄우기 전에 가로로 정한 실제 가로 제품은 버튼 글자도 커진다. 또 이 시나리오는 check.py의 네 창 크기에서만 돌아, R1-1이 처음 난 가로 제품 568x320(휴대폰 가로 배치)에서는 실행되지 않는다(568x320을 도는 `camp_probe`는 진행 초기화를 다루지 않는다). 실패 시나리오: 나중에 568x320 가로 제품에서 이유나 버튼이 다시 밀려도 여정은 통과하고, PR 증거 캡처를 보는 검수자는 실제 제품에 없는 배율 문제를 보거나 실제 문제를 놓친다. 고칠 방법: 가로 시나리오는 `landscape = true`를 띄우기 전에 정해 마운트하고(`camp_probe`처럼), 568x320에서 이유·버튼 보임 검사를 `camp_probe`나 여정에 넣는다.
- R2-5 (minor, `_apply_progress_reset`의 `_error_text(code)`와 공용 `save_failed` 문구, 근거 `build/review-r2/render/r2-failure-port-ko-save-failed.png`, `r2-failure-land-ko-save-failed.png`, `r2-failure-*-en-save-failed.png`, crop `ko390-save-failed-x2.png`): 디스크 쓰기 실패로 초기화가 안 되면 해요체 화면에 합쇼체 "저장하지 못했습니다. 다시 시도해 주세요."가 토스트와 경고 아래 두 곳에 나온다. 영어 "Could not save. Try again."는 거부 문구와 달리 바뀐 것이 없다는 말을 하지 않는다(실제로 저장 바이트와 메모리 값은 그대로다). 실패 시나리오: 되돌릴 수 없는 동작 화면에서 "저장하지 못했다"를 본 플레이어가 진행이 반쯤 지워졌거나 저장이 망가졌다고 생각해 다시 누르지 못하거나 문의한다. 설계의 상태도는 저장 실패도 "이유 표시"로 다루지만 실패 행은 제품 거부와 스키마 위반 문구만 정한다. 고칠 방법: 초기화 경로에서 `save_failed`를 "초기화를 저장하지 못했어요. 바뀐 것은 없어요. 다시 해 주세요." / "Could not save the reset. Nothing was changed. Try again."처럼 초기화 전용 해요체 문구로 바꾸고 설계 실패 행에 적는다.

참고(지적 아님): 토스트는 이 화면에서도 2초 동안 머리 줄을 덮지만 입력을 받지 않고 이유 줄은 가리지 않는다. 토스트 글꼴(`NumberLabel`)은 한 줄에 들 때 고정폭처럼 보이고 한국어는 대체 글꼴로 넓게 그려진다. 1.1.0 공용 토스트의 모양이라 이 PR 범위가 아니다. 0.6초 안의 누름은 아무 반응 없이 무시되지만 그때 버튼은 이미 "한 번 더 누르면 초기화해요"를 보이고 있어 다음 누름으로 확정할 수 있다.

## 판정

pass. 1회차 major 두 건은 풀렸다. R1-1은 이유를 버튼 위로 옮기고 토스트를 더해, 1회차 실패 칸을 포함한 세로·가로 제품 32경우 모두에서 이유 줄 전체가 처음 화면에 보인다. 원본 캡처(여정 네 크기와 보조 568x320·844x390·1280x720 가로 제품)와 사각형 측정으로 확인했다. R1-2는 600ms 확인 지연으로, 같은 프레임부터 564ms까지의 둘째·셋째 누름과 키보드 연타가 렌더·headless 모두에서 저장을 바꾸지 않았고, 700ms 뒤 의도한 누름은 모든 위치에서 확정됐다. R1-3~R1-6, R1-8도 해소됐고 R1-7은 이번에도 진행 초기화와 무관한 렌더 단계 2건으로 나타났다(재실행 통과).

새로 찾은 것은 minor 다섯 건이다. R2-1(실패 뒤 곧바로 성공하면 반대 뜻의 토스트 두 개)과 R2-2(주 버튼 판의 한국어 무장 문구가 낱말 중간에서 끊기고 버튼이 커짐)는 1회차 수정이 만든 것이고, R2-3(가로 568x320 영어에서 남는 것과 지워지는 것이 첫 화면 밖), R2-4(가로 여정 시나리오가 실제 가로 제품과 568x320을 재현하지 않음), R2-5(디스크 쓰기 실패 문구의 합쇼체와 모호함)는 화면 품질과 검사 보강 문제다. 모두 글자가 잘리거나 저장이 잘못 바뀌는 경우가 아니어서 blocker·major가 아니다.

PR-7 최종 판정: 390x844 pass, 320x568 pass, 844x390 pass, 1280x720 pass.

## 증적 보관

검수 캡처와 로그 원본은 이 worktree의 `build/` 아래에만 있다(`qa-r2-390x844`, `qa-r2-320x568`, `qa-r2-844x390`, `qa-r2-1280x720`, 1차 실패 출력 `qa-r2-320x568-try1`, `qa-r2-1280x720-try1`, `npm test`의 headless 출력 `e2e/5397edb8…`, `review-r2/`(보조 스크립트 `r2_probe.gd`, 요약 `summarize.py`, 렌더 확인 `guard.sh`, 감시 `monitor.sh`, 실행 스크립트 `render-all.sh`, `probe-render.sh`, headless·렌더 결과, crop, 사용자 폴더 목록), `logs/`). 전체 약 186MB. NAS1dual 이관은 구현자가 PR 정리 단계에서 한다.
