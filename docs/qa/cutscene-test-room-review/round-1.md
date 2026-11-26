# 컷신 재생기, 크레딧, 테스트실 독립 검수 1회차

- 검수자: 독립 검수 에이전트 1 (구현자와 다른 에이전트)
- 대상: seorilabs/game-foundation `cutscene-test-room`, 후보 SHA `0dbc661c1f154b417ac8cb038e6cb89e96a6ce08`, 기준 main `e7e905df9aefe8f50f917ba103f6bcdcf240f60e`
- 크기: 390x844 (모바일 세로), 1280x720 (PC 가로). 부속 probe는 고정 크기로 캠프 568x320, 내비게이션 320x568도 함께 찍힌다
- 실행 시각: 2026-11-26 10:37–10:57 UTC
- 실행 환경: dev headless 검증 + 렌더링 캡처(Godot 4.7.2.stable.official.ed1daf0bf, macOS 27.2.1, Python 3.14.7, Node 24.16.0), 격리 worktree(detached HEAD), 격리 저장(여정과 probe 자체 격리 프로필)
- 설계: `docs/design/2026-11-26-cutscene-test-room/design.md` AC-8~AC-14, "사용자 흐름·화면 상태", "품질 요구사항". 상위 설계 agent-config `docs/design/2026-11-26-game-skill-system-v2/design.md`의 컷신 재생기, 아웃게임 연결, 테스트실, 품질 요구사항 절. 테스트 계획 L3·dev·redesign·release null

## 검수 계획

이번 회차는 모든 AC를 직접 재현하고 390x844와 1280x720에서 화면을 판정한다.

| 순서 | 영역 | 내용 | 통과 기준 |
|---|---|---|---|
| 1 | 기능 | `godot --headless --path godot --import --quit-after 2`, `npm test`(단위 테스트 + `check.py`), `python3 tools/bundle.py verify` | 모두 종료 0 |
| 2 | 렌더링 | `check.py --capture --size 390x844 --out build/qa-r1-390x844`, `--size 1280x720 --out build/qa-r1-1280x720`. 기존 probe(e2e_scroll_probe, ui_navigation_probe)가 렌더 모드에서 실패하면 한 번 더 돌려 둘 다 적고, origin/main 별도 worktree에서 같은 크기로 재현 여부 확인 | 종료 0, 기존 probe 실패가 후보 변경 탓이 아님 |
| 3 | 기능 결과 | `journey.json`, `ui-kit.json`, `dev.json`에서 새 시나리오 3개(`map-prologue-first-start-once`, `settings-credits-and-ending-replay`, `debug-test-room`)와 기존 10개 시나리오 통과, 기존 시나리오 단계와 probe 기대가 origin/main보다 약해지지 않음(diff) | 13개 passed, 기존 기대 삭제·완화 없음 |
| 4 | 화면 | prologue-1, prologue-2, prologue-title, credits, credits-end, settings-ending, ending-1, ending-count, ending-credits, ending-end, test-room, test-room-armed, test-room-blocked를 두 크기에서 판정. 잘림, 프레임 띠 안 글자와 안쪽 여백(1280x720 크레딧 본문과 왼쪽 프레임 거리 포함), 스킵 버튼과 자막 겹침, 모바일 터치 목표 48dp 이상(설계는 56px), PC 배치 늘어짐, 시각 위계, 한국어 캡처 | 모두 pass |
| 5 | 정적 | `python3 -m unittest tools/test_export_presets.py`, 로컬 `godot --headless --path godot --export-pack "Web" build/qa-r1-export/web.zip` 뒤 파일 목록에 `addons/seorilabs_game/dev/` 없음, 공통 코드가 `dev/`를 preload하지 않음 | 통과 |
| 6 | 코드 | `cutscene_player` 공개 API가 설계와 일치(`play`, 신호, `state`, `can_skip`, `current_cut`, `request_next`, `request_skip`, 주입 `audio`·`text`·`number_format`·`art_loader`), `push_error` 없음, `seorilabs_game`에 `class_name` 없음, `intro_seen` 기본값 읽기, `SAVE_VERSION` 불변 | 일치 |

## 실행 명령과 결과

모든 명령은 격리 worktree 루트(`game-foundation.worktrees/review-r1`, detached `0dbc661`)에서 실행했다. 비교용 origin/main worktree(`review-r1-main`, detached `e7e905d`)는 같은 크기로 실행한 뒤 삭제했다. 시각은 UTC다.

| 순서 | 명령 | 결과 |
|---|---|---|
| 1 | `godot --headless --path godot --import --quit-after 2` | 종료 0 (10:37:31–10:37:37), ERROR 0 |
| 2 | `npm test` (`unittest discover` + `check.py` headless) | 종료 0 (10:37:47–10:38:36). 단위 테스트 34개 OK, check.py `{"ok": true, "scenarios": 13}` |
| 3 | `python3 tools/bundle.py verify` | ok, version 1.2.0, files 87, source commit `38df503…`(잠금이 가리키는 직전 커밋) |
| 4 | `check.py --capture --size 390x844 --out build/qa-r1-390x844` | **종료 1** (10:38:53–10:42:38). 기존 `ui_navigation_probe`가 180초 제한 초과. `navigation/journey.json`의 `native-open-late-callback`에서 `request provider UI` 탭은 참인데 `provider request held`가 거짓(순위 화면으로 가지 않음). 그 뒤 probe가 비어 있는 콜백을 불러 종료하지 못했다. 같은 실행의 여정 13개, ui-kit 102/0, dev 21/0, scroll·camp probe는 통과 |
| 5 | 같은 `ui_navigation_probe`를 check.py와 같은 인자로 단독 2회 렌더 실행 | 2회 모두 종료 0, 3개 시나리오 통과(10:43:12–10:43:19) |
| 6 | `check.py --capture --size 390x844 --out build/qa-r1-390x844-rerun` (재실행 1회) | **종료 1** (10:43:46–10:44:27). 이번에는 기존 시나리오 `first-play-reward-and-replay`의 `collect` 탭이 참으로 끝났지만 코인이 0으로 남아(`first reward committed expected=10, actual=0`) 이후 19단계가 연쇄 실패. 캡처 `reward.png`에 Collect +10 버튼이 정상 표시됨. 나머지 12개 시나리오 통과 |
| 7 | `check.py --capture --size 1280x720 --out build/qa-r1-1280x720` | 종료 0 (10:44:27–10:45:29), 13개 시나리오, automated.json passed |
| 8 | origin/main `e7e905d`에서 `check.py --capture --size 390x844` 6회(후보와 번갈아 실행) | 6회 모두 종료 0, 10개 시나리오 통과(10:46:47–10:55:15) |
| 9 | 후보에서 `check.py --capture --size 390x844` 4회 더(`build/qa-r1-390x844-run3`~`run6`, main과 번갈아 실행) | 4회 모두 종료 0, 13개 시나리오 통과(10:48:27–10:54:40) |
| 10 | `python3 -m unittest tools/test_export_presets.py`, `cd tools && python3 -m unittest test_bundle test_ui_contract` | 2 tests OK, 9 tests OK(1.2.0이 1.1.0 위에 설치되고 역방향 거부, 1.2.0 아래 스킨 계약 1.1.0) |
| 11 | `godot --headless --path godot --export-pack "Web" ../build/qa-r1-export/web.zip` (4.7.2 템플릿) | 종료 0 (10:51:44–10:51:47), 175개 항목. `addons/seorilabs_game/dev/` 항목 0개, `tests/` 0개, `cutscene_player`·`outgame_main`·OFL 4개 포함. 목록 `build/qa-r1-export/filelist.txt` |
| 12 | 검수자 보조 스크립트 `build/review-r1-ko/ko_capture.gd`로 ko-KR 캡처(390x844, 1280x720) | 2회 모두 종료 0(10:51:58–10:52:09). 새 화면 11장씩, 끝 화면 Esc·뒤로 가기 동작 기록 |
| 13 | 정적 검사: `grep push_error`, `grep class_name`, `preload(…dev/`, `SAVE_VERSION`, 기존 probe와 여정 diff | 아래 "코드 확인" 참조 |

렌더 캡처 실패 집계(390x844): 후보 6회 중 2회 실패(1·2번째 실행), origin/main 6회 중 0회 실패. 1280x720 후보 1회 통과. 두 실패 모두 바뀌지 않은 기존 경로에서 드라이버의 탭이 참으로 끝났는데 버튼 동작이 일어나지 않은 형태다. 같은 시간대에 다른 세션의 렌더링 Godot(`--write-movie`) 창이 반복해서 뜨고 있었다(10:42, 10:47 확인, 10:50 이후 0개). 후보 코드에서 마우스 탭을 가로챌 경로는 찾지 못했다(컷신은 idle에서 숨김과 `MOUSE_FILTER_IGNORE`, 테스트실은 숨김, 새 입력 처리는 키 이벤트만). 원인은 확정하지 못했다(발견 사항 F-3).

## 기능 결과

`build/qa-r1-390x844/journey.json`(렌더, 390x844)과 `build/qa-r1-1280x720/journey.json` 기준. 390x844 첫 실행은 여정 단계 자체는 모두 통과했고, 단계 수는 origin/main 실행과 같다.

| 시나리오 | 390x844 | 1280x720 | 단계 수(후보/main) | featureIds |
|---|---|---|---|---|
| startup-gates | pass | pass | 9/9 | startup, operations |
| first-play-reward-and-replay | pass(첫 실행), fail(재실행, F-3), pass(run3~6) | pass | 25/25 (1280은 가로 검사 1단계 추가로 26) | startup, tutorial, account_save, observability |
| settings-support-language-restart | pass | pass | 22/22 | settings_support 외 6개 |
| inbox-read-claim-scroll | pass | pass | 13/13 | inbox, account_save, observability |
| commerce-pending-reconcile-restore | pass | pass | 13/13 | commerce, ui_navigation |
| leaderboard-states-and-pagination | pass | pass | 20/20 | ui_leaderboard |
| shared-version-product-hooks | pass | pass | 31/31 | startup, ui_navigation |
| save-corruption-and-guide-recovery | pass | pass | 6/6 | account_save, tutorial |
| server-claim-batches-and-failure | pass | pass | 12/12 | inbox, operations, observability |
| late-server-response-preserves-navigation | pass | pass | 6/6 | inbox, ui_navigation |
| map-prologue-first-start-once (신규) | pass | pass | 13/– | cutscene, startup, tutorial, account_save |
| settings-credits-and-ending-replay (신규) | pass | pass | 21/– | credits, cutscene, settings_support, ui_navigation |
| debug-test-room (신규) | pass | pass | 20/– | test_room, cutscene, ui_navigation |

기존 기대 약화 여부: `outgame_journey.gd`에서 지운 줄은 `commonVersion == "1.1.0"`을 `"1.2.0"`으로 바꾼 한 줄뿐이고(설계의 계약 1.2.0 변경 목록), 나머지는 새 시나리오 3개 추가다. `ui_navigation_probe.gd`, `e2e_scroll_probe.gd`, `camp_probe.gd`, `e2e_driver.gd`, 다른 common probe는 origin/main과 같다. `ui_kit_probe.gd`는 컷신 검사만 더했고 기존 48항목은 그대로다(후보 102 = 48 + 컷신 27 x 2).

| AC | 결과 | 근거 |
|---|---|---|
| AC-8 | pass | `ui-kit.json` 컷신 54항목(motion 27, reduced 27) 모두 통과: 다음 컷, 잠긴 컷의 스킵·탭·Esc·Enter 무시, 시간 경과로 넘어감, 다시 보기 잠금 해제, 크레딧 단계, 카운트업 표기 주입(`N12345`), 그림 누락 시 빈 배경 진행(`missing_art` 기록, `push_warning`만), 한 프레임 0.1초 상한, 앱·창 포커스 정지 후 같은 컷 재개, 효과음 꺼짐에도 자막 표시 |
| AC-9 | pass | `map-prologue-first-start-once`: 첫 시작에 프롤로그, 스킵하면 play, `intro_seen` 저장과 `version == SAVE_VERSION`(3, 미변경), 재실행하면 프롤로그 없이 play. skyway·windharbor 설정에 `introScript`·`endingScript` 없음. 기존 10개 시나리오 통과 |
| AC-10 | pass | `settings-credits-and-ending-replay`: skyway도 글꼴 라이선스 4종, map은 제품 문구와 AI 고지와 4종, `set_ending_seen(true)` 전에는 "Replay ending" 없음, 뒤에는 있음, 다시 보기 뒤 저장 바이트 동일. 캡처 credits, credits-end, settings-ending |
| AC-11 | pass | `dev.json` 21항목 통과(두 번 눌러 적용, 다른 버튼으로 무장 해제, 결과 줄 52.0px 고정, 버튼 위치 불변, 막힌 행동 토스트와 저장 무변경, 막힌 다시 보기, 다시 보기 뒤 저장 바이트 동일, 닫기, Esc). 여정 `debug-test-room`: F9 열기·닫기, 재생 중 F9 무시, 판 진행 중 막힌 행동 토스트 |
| AC-12(기반 몫) | pass | `test_export_presets.py` 통과, 로컬 웹 export에 `dev/` 항목 없음, `seorilabs_game`의 어떤 `.gd`도 `dev/`를 preload하지 않음(`outgame_main.gd:22`는 경로 문자열 상수와 런타임 `load()`만 사용) |
| AC-13 | pass(이번 회차 크기 390x844, 1280x720) | 아래 화면 판정. 320x568, 844x390은 이번 회차 범위 밖(not assessed) |
| AC-14(기반 몫) | pass | `test_bundle.py`, `test_ui_contract.py`, `bundle.py verify` |

코드 확인:

| 항목 | 결과 | 근거 |
|---|---|---|
| `cutscene_player` 공개 API | pass | `play(script, options := {})`, `signal finished(skipped)`, `signal cut_changed(index)`, `state()`, `can_skip()`, `current_cut()`, `request_next()`, `request_skip()`, 주입 `audio`·`text`·`number_format`·`art_loader`·`title_text`·`colors`·`ui_scale`, 관찰 `missing_art`·`cue_log`·`paused`가 설계와 같다(`cutscene_player.gd:11-46, 78-146`) |
| `push_error` | pass | 새 파일에 없음. `seorilabs_game` 안의 유일한 사용은 기존 `ui_kit/build_theme.gd:14`(origin/main과 동일, 편집기 도구) |
| `class_name` | pass | `seorilabs_game` 전체에 없음 |
| `intro_seen` | pass | `state.gd`의 `intro_seen()`이 `data.get("intro_seen", false)`를 bool로만 인정, `mark_intro_seen()`은 `commit`. `valid()`와 `SAVE_VERSION := 3` 미변경 |
| 뒤로 가기 순서 | pass | `layers`는 `outgame_main`의 자식이라 `propagate_notification`에서 호스트가 먼저 받아 컷신·테스트실이 열려 있으면 `_back()`을 건너뛰고(`outgame_main.gd:287`), 그다음 컷신·테스트실이 처리한다 |

## 화면 판정

캡처 위치: `build/qa-r1-390x844/`, `build/qa-r1-1280x720/`(영어, check.py 여정), `build/review-r1-ko/390x844/`, `build/review-r1-ko/1280x720/`(한국어, 검수자 보조 스크립트). 터치 목표는 코드 값과 캡처의 버튼 위치로 확인했다.

| 캡처 | 390x844 | 1280x720 | 근거 |
|---|---|---|---|
| prologue-1 | pass | pass | 자막이 아래 그림자 위 흰 글자+외곽선으로 읽힘. 스킵은 오른쪽 위 124x56(390), 174x78(1280, 배율 1.4)이고 자막과 떨어져 있음 |
| prologue-2 | pass | pass | 밝은 양피지 그림 위에서도 외곽선과 아래 그림자로 자막이 읽힘. 1280에서 점선 위를 지나지만 가독성 유지 |
| prologue-title | pass | pass | "SKY ATLAS" 표시 서체와 그림자, 부제 "Chart the lost skies"가 잘리지 않음 |
| credits | pass | pass | 제품 문구, AI 고지, 글꼴 4종이 프레임 안에 있고 잘리지 않음. 다만 본문이 가죽 띠 안쪽 끝에서 1~2px 떨어져 붙어 있고 1280에서는 왼쪽 정렬 줄이 전체 폭 패널의 왼쪽 절반에만 몰림(F-1) |
| credits-end | pass | pass | 390은 마지막 줄 "SIL Open Font License 1.1"이 아래 띠 위까지 스크롤됨. 1280은 스크롤 없이 모두 보임 |
| settings-ending | pass | pass | "Replay ending", "Credits", "Test room"이 기존 설정 버튼과 같은 판·크기(세로 48px 기준)로 목록 끝에 들어감 |
| ending-1 | pass | pass | 다시 보기라 잠긴 첫 컷에서도 스킵이 활성. 390에서는 정사각 그림을 덮기 비율로 잘라 기구가 왼쪽 가장자리에서 잘림(그림 구도, F-6) |
| ending-count | pass | pass | "12,800"이 공용 재화 칩 표기로 자막 위에 보임 |
| ending-credits | pass | pass | 크레딧 줄이 스킵 버튼 아래(`Credits.offset_top`)에서만 보이도록 잘려 버튼과 겹치지 않음. 가운데 정렬, 폭 342px(390), 1148px(1280) |
| ending-end | pass | pass | 금색 주 버튼 "Continue" 260x56(390), 364x78(1280)가 가운데. 끝 화면의 Esc·뒤로 가기는 동작 없음(F-2) |
| test-room | pass | pass | 390은 2열, 1280은 폭 760px 3열로 늘어나지 않음. 행동, 시점, 다시 보기, 봐줄 점 순서가 첫 화면에 모두 보이고 닫기 56x56 |
| test-room-armed | pass | pass | 무장한 버튼만 금색 "Tap again to apply"로 바뀌고 다른 버튼 위치 불변, 결과 줄 "Coins 0 → 100" |
| test-room-blocked | pass | pass | 토스트 "Finish the current round first"가 위쪽에 뜨고 결과 줄(10-minute preset…)은 그대로. 390에서 토스트가 프레임 위 띠에 겹치지만 제목·닫기는 가리지 않음 |
| ko 변형 11장(ko-prologue-1, ko-prologue-title, ko-credits, ko-settings-ending, ko-ending-1, ko-ending-count, ko-ending-credits, ko-ending-end, ko-test-room, ko-test-room-armed, ko-ending-locked) | pass | pass | "건너뛰기", "계속하기", "한 번 더 누르면 적용", "프롤로그 다시 보기", "이번 빌드에서 봐줄 점" 모두 한 줄 또는 단어 단위로 줄바꿈되고 버튼·프레임 안에 있음. 잠긴 엔딩 첫 컷은 회색 비활성 스킵이 표시됨 |
| 320x568, 844x390 | not assessed | not assessed | 이번 회차 범위 밖. 2·3회차에서 판정 |

## 발견 사항

- F-1 (수정 권장, `godot/addons/seorilabs_game/flow/outgame_main.gd:789`의 `_credits_screen()`, 여백은 `:401`의 `_clear()` 공용 모달 여백, 캡처 `credits.png` 390x844·1280x720): 설정 크레딧 본문이 가죽 띠 안쪽 끝(약 x=32)에서 1~2px 떨어진 x=34에서 시작한다. 1280x720에서는 세로형 제품의 모달이 창 전체 폭(약 1210px)으로 늘어나 왼쪽 정렬된 줄(최대 약 610px)이 왼쪽 절반에만 몰리고, 글꼴 이름("Jua", "Noto Sans KR")이 저작권 줄과 같은 14px·같은 색이라 라이선스 묶음의 시작이 구분되지 않는다. 실패 시나리오: PC 창에서 설정 → 크레딧을 연 플레이어는 왼쪽 프레임에 붙은 글자 덩어리를 보고, 특정 글꼴의 라이선스를 찾으려면 줄을 하나씩 읽어야 한다. 같은 여백은 기존 설정 설명문에도 있어 이번 변경이 만든 회귀는 아니지만, 글자만 있는 새 화면이라 가장 크게 드러난다. 제안: 크레딧 목록에 안쪽 여백(예: 좌우 12~16px)과 최대 폭을 주고 엔딩 크레딧 롤처럼 가운데 정렬하거나, 글꼴 이름을 굵은 제목 줄로 분리한다. AC-10, AC-13(잘림 없음, 읽힘)은 충족한다.
- F-2 (수정 권장, `godot/addons/seorilabs_game/ui_kit/cutscene_player.gd:119-122`의 `can_skip()`이 `end`에서 거짓, `:138-141`의 `request_skip()`, 호스트 `outgame_main.gd:287`): 후보 `0dbc661`의 끝 화면(계속하기)에서 Esc와 OS 뒤로 가기가 아무 일도 하지 않는다. 검수자 스크립트로 끝 화면에서 Esc를 넣고 `NOTIFICATION_WM_GO_BACK_REQUEST`를 전파한 뒤 상태가 그대로 `end`, 아래 화면은 `settings`였다. 호스트는 컷신이 idle이 아니면 뒤로 가기를 넘기지 않으므로 입력이 그냥 사라진다. 실패 시나리오: Android 플레이어가 엔딩 크레딧 뒤 끝 화면에서 시스템 뒤로 가기를 눌러도 반응이 없다(탭, Space, Enter, 계속하기 버튼은 동작). 참고: 구현자 브랜치 최신 `bc6b342`(이 후보 이후 커밋 `acebc53` "끝 화면의 뒤로 가기")에 `request_back()`으로 고친 변경이 있으나 이번 회차는 `0dbc661`만 검수했으므로 2회차에서 확인한다.
- F-3 (참고, 렌더 캡처 `build/qa-r1-390x844/navigation/journey.json`, `build/qa-r1-390x844-rerun/journey.json`): 390x844 렌더 check.py가 후보에서 6회 중 2회 실패했고 origin/main에서는 6회 중 0회 실패했다. 실패 지점은 바뀌지 않은 기존 경로(`ui_navigation_probe`의 순위 열기 탭, `first-play`의 Collect +10 탭)이며 드라이버의 탭은 참으로 끝났지만 버튼 동작이 일어나지 않았다. 후보의 새 노드는 idle에서 숨김·`MOUSE_FILTER_IGNORE`이고 새 입력 처리는 키 이벤트뿐이라 탭을 가로채는 경로를 찾지 못했다. 두 실패는 세션 초반(10:38–10:44)에 다른 세션의 렌더링 Godot 창이 반복해서 뜨던 때 일어났고, 이후 후보 4회 연속 통과했다. 통계적으로 후보 탓이라고 볼 근거는 부족하다(2/6 대 0/6). 실패 시나리오: 리뷰 캡처를 한 번만 돌리면 후보가 이유 없이 실패로 보이거나, 반대로 실제 회귀가 간헐 실패에 묻힐 수 있다. 또 `ui_navigation_probe`는 단계가 실패하면 `held` 콜백이 비어 있는 채로 호출해 종료하지 못하고 180초 제한까지 멈춘다(`ui_navigation_probe.gd:46`, 기존 코드). 2·3회차는 다른 렌더 창이 없는 상태에서 후보와 main을 각각 3회 이상 돌려 비교할 것을 권한다.
- F-4 (참고, 추정, `cutscene_player.gd:250`): 스킵 버튼은 화면 위 16px에 놓이고 공용 기반 전체에 안전 영역(노치, 상태 표시줄) 처리가 없다(`get_display_safe_area` 사용 0건). 기기 export가 상태 표시줄 아래까지 그리면 390x844 아이폰에서 스킵 버튼(y 16–72)이 상단 안전 영역(약 47pt)과 겹칠 수 있다. 기존 타이틀 설정 버튼도 같은 방식이라 이번 변경의 회귀는 아니며, 개발 환경에서 확인할 수 없어 소비 게임 단계의 확인 항목으로 남긴다.
- F-5 (참고, `godot/tests/reference/outgame_journey.gd` 새 시나리오): 새 화면의 여정 캡처가 영어뿐이다. 검수자가 ko-KR로 따로 찍은 11장은 모두 통과했으나, 한국어 문구가 길어질 때의 회귀는 자동 캡처에 남지 않는다. 기존 `settings-ko`, `large-text-ko`처럼 컷신 한 장과 테스트실 한 장의 ko 캡처를 여정에 더하는 것을 권한다.
- F-6 (참고, `godot/reference/assets/cutscene/*.svg`, 캡처 `ending-1.png` 390x844): 레퍼런스 컷 그림이 1200x1200 정사각이라 덮기 비율(`stretch_mode = 6`)에서 세로 화면은 좌우가, 가로 화면은 위아래가 잘린다. 390x844 ending-1에서 주인공 격인 기구가 왼쪽 가장자리에서 잘린다. 재생기 결함이 아니라 예제 그림 구도 문제이며, 제품 그림은 안전 영역을 가운데에 두거나 `pan`으로 초점을 옮기라는 안내가 README에 있으면 좋다.

## 판정

pass. 후보 `0dbc661`은 AC-8~AC-12, AC-14와 이번 회차 크기(390x844, 1280x720)의 AC-13을 직접 재현해 통과했다. 새 시나리오 3개와 기존 10개 시나리오가 통과하고 기존 기대는 약해지지 않았다. 컷신, 크레딧, 테스트실 캡처는 영어와 한국어 모두 잘림 없이 읽히며 스킵과 자막이 겹치지 않고 새 버튼은 56px 이상이다. 웹 export에 `dev/`가 없다. 차단 결함은 없고, 크레딧 화면 여백과 PC 배치(F-1), 끝 화면의 Esc·뒤로 가기 무반응(F-2, 최신 브랜치에서 수정 시도 있음)은 수정을 권한다. 390x844 렌더 캡처의 간헐 실패(F-3)는 origin/main에서 재현되지 않았고 원인을 확정하지 못했으므로 2·3회차에서 반복 실행으로 다시 확인한다.

검수 캡처와 로그 원본은 이 worktree의 `build/` 아래에만 있다(`qa-r1-390x844`, `qa-r1-390x844-rerun`, `qa-r1-390x844-navrerun1`·`2`, `qa-r1-390x844-run3`~`run6`, `qa-r1-1280x720`, `qa-r1-export`, `review-r1-ko`). NAS1dual 이관은 PR 정리 단계에서 한다.

## 증적 보관

본문의 `build/` 경로는 검수용 임시 worktree였고 지웠다. 원본(캡처, 로그, 측정 결과)은 NAS1dual `agent-artifacts/game-foundation/2026-11-26/0dbc661c1f154b417ac8cb038e6cb89e96a6ce08/cutscene-test-room-review-r1`에 옮겼고, 같은 폴더의 `MANIFEST.txt`가 파일별 크기와 SHA-256과 검증 완료를 적는다(2026-11-26). starter 복사본과 묶음 tar, export 패키지처럼 다시 만들 수 있는 파일은 옮기지 않았다.
