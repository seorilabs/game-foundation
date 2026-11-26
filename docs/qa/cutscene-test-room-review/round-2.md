# 컷신 재생기, 크레딧, 테스트실 독립 검수 2회차

- 검수자: 독립 검수 에이전트 2 (구현자, 1회차 검수자와 다른 에이전트)
- 대상: seorilabs/game-foundation `cutscene-test-room`, 후보 SHA `c6da5afff4d589c44d673b72d146d183ba273eef`, 기준 main `e7e905df9aefe8f50f917ba103f6bcdcf240f60e`(후보의 merge-base와 같음)
- 1회차 이후 변경: `acebc53`(끝 화면 `request_back()`, 길이 0 프롤로그의 `finished` 선연결), `db888b3`(크레딧 640px 가운데 칸과 안쪽 여백, 글꼴 이름 굵게, 한국어 여정 `korean-cutscene-test-room-credits`), 잠금 갱신 `bc6b342`, `c6da5af`
- 크기: 이번 회차 판정 크기 320x568(작은 세로), 844x390(낮은 가로). F-1 재확인용 390x844, 1280x720. 부속 probe는 도구 고정값(캠프 568x320 등)
- 실행 시각: 2026-11-26 11:01–11:20 UTC
- 실행 환경: dev headless 검증 + 렌더링 캡처. Godot 4.7.2.stable.official.ed1daf0bf(Compatibility, OpenGL 4.1 Metal, Apple M3), macOS 27.2.1, Python 3.14.7, Node 24.16.0. 격리 worktree `game-foundation.worktrees/review-r2`(detached), 비교용 임시 worktree `review-r2-main`(detached `e7e905d`, 실행 후 삭제). 저장은 여정과 보조 스크립트의 격리 프로필만 썼고 실행 뒤 지웠다
- 설계: `docs/design/2026-11-26-cutscene-test-room/design.md` AC-8~AC-14, "사용자 흐름·화면 상태", "품질 요구사항". 상위 설계 agent-config `docs/design/2026-11-26-game-skill-system-v2/design.md`. 테스트 계획 L3·dev·redesign·release null

## 검수 계획

실행 전에 적은 계획이다. 이번 회차는 1회차 지적의 수정 확인, 1회차가 판정하지 않은 320x568과 844x390, 렌더 모드 간헐 실패(1회차 F-3)의 원인 판단에 집중한다.

| 순서 | 영역 | 내용 | 통과 기준 |
|---|---|---|---|
| 0 | 환경 | 렌더 실행 전마다 `pgrep -fl -i godot`로 다른 Godot 렌더 창이 없는지 확인하고, 있으면 기다렸다가 다시 확인한다. 본 것을 기록한다 | 렌더 실행 중 다른 Godot 렌더 프로세스 없음 |
| 1 | 기능 | `godot --headless --path godot --import --quit-after 2`, `npm test` 1회 | 종료 0 |
| 2 | 렌더링 | `check.py --capture --size 320x568 --out build/qa-r2-320x568`, `--size 844x390 --out build/qa-r2-844x390`, F-1 재확인용 `--size 390x844`, `--size 1280x720` | 종료 0 |
| 3 | 화면 | 새 화면 캡처 16종(prologue-1/2/title, credits, credits-end, settings-ending, ending-1, ending-count, ending-credits, ending-end, test-room, test-room-armed, test-room-blocked, prologue-1-ko, test-room-ko, credits-ko)을 320x568, 844x390에서 판정. 잘림, 프레임 띠 안 글자와 안쪽 여백, 스킵과 자막 겹침, 터치 목표 48dp 이상(새 버튼은 설계상 56px, 캠프 가로는 56px), 위계. `credits.png`는 390x844, 1280x720에서도 다시 본다(F-1: PC에서 가운데 읽기 칸, 왼쪽 띠와의 여백, 글꼴 이름 구분) | 모두 pass |
| 4 | 수정 확인 | `ui-kit.json`의 `back on the end screen continues`, `zero-length cut finishes inside play`(motion, reduced), `journey.json`의 `zero-length prologue still enters the game`, `zero-length prologue is recorded as seen`. 실제 입력 경로로 끝 화면에서 Esc를 누르는 검수자 보조 스크립트(`build/` 아래) | 모두 참 |
| 5 | 간헐 실패 | 다른 Godot 렌더 창이 없을 때 `check.py --capture --size 390x844`를 후보 3회, origin/main 3회(임시 detached worktree, 끝나면 제거) 번갈아 실행. 실행마다 통과 여부와 실패 단계를 적는다. 후보가 main보다 더 실패하면 실패 단계를 조사해 새 코드(idle 때 숨김·`MOUSE_FILTER_IGNORE`인지, 새 키 입력 처리, 디버그 빌드의 테스트실 부착)가 관여할 수 있는지 판단한다 | 후보 실패율이 main과 같거나, 다르면 원인을 새 코드와 연결하거나 배제할 근거가 있음 |

실행 중 계획에 더한 것: 보조 측정 스크립트(버튼 실측, 크레딧 칸 좌표, 끝 화면의 Esc·KEY_BACK·OS 뒤로 가기), 막힌 행동 토스트의 폭 측정(320x568 캡처에서 잘림을 본 뒤), 간헐 실패 원인을 가르기 위한 간섭 재현 실험(후보와 main 각 2회).

## 실행 명령과 결과

모든 명령은 격리 worktree 루트에서 실행했다. 렌더 실행 기록은 `build/logs/runs.log`에 있다.

| 순서 | 명령 | 결과 |
|---|---|---|
| 0 | `pgrep -fl -i godot` (11:01:35) | Godot 실행 파일 프로세스 0개. 잡힌 것은 godot-mcp 서버(`npm exec @coding-solo/godot-mcp`와 `node …/godot-mcp` 4쌍)뿐이라 렌더 창이 아니다. 이후 렌더 실행마다 `ps`로 `Godot.app/Contents/MacOS/Godot` 프로세스가 없는지 확인하고 시작했다(모든 실행에서 0개, 대기 없음). 확인은 실행 시작 시점에만 했다 |
| 1 | `godot --headless --path godot --import --quit-after 2` | 종료 0 (11:01:52–11:01:56), ERROR 0 |
| 2 | `npm test` | 종료 0 (11:01:58–11:02:33). 단위 테스트 34개 OK(`test_export_presets`, `test_bundle`, `test_ui_contract` 포함), check.py `{"ok": true, "scenarios": 14}` |
| 3 | `check.py --capture --size 320x568 --out build/qa-r2-320x568` | 종료 0 (11:02:51–11:03:42), 14개 시나리오 |
| 4 | `check.py --capture --size 844x390 --out build/qa-r2-844x390` | 종료 0 (11:03:44–11:04:51), 14개 시나리오 |
| 5 | `check.py --capture --size 1280x720 --out build/qa-r2-1280x720` | 종료 0 (11:05:01–11:05:52), 14개 시나리오 |
| 6 | 후보 `check.py --capture --size 390x844` 3회(`qa-r2-390x844-c1`~`c3`), main 3회(`main-runs/qa-r2-main-390x844-m1`~`m3`) 번갈아 | 6회 모두 종료 0 (11:05:53–11:10:07). 아래 간헐 실패 표. main 실행 사이 11:06:44, 11:07:30의 exit=1 두 줄은 main worktree에 `build/`가 없어 check.py가 시작도 못 한 무효 실행이라 집계에서 뺐다(`runs.log`에 주석) |
| 7 | 보조 측정 `godot --path godot --script build/review-r2/measure.gd -- --size <4개 크기> --capture` | 4개 크기 모두 종료 0 (11:10–11:13). 결과 `build/review-r2/<크기>/measure.json`, 열림 애니메이션이 끝난 뒤 다시 잰 테스트실 값은 `build/review-r2/settled-<크기>/measure.json` |
| 8 | 보조 측정 `build/review-r2/blocked.gd`(판 진행 중 막힌 행동 토스트), 320x568·360x640·390x844 × en-US·ko-KR | 6회 모두 종료 0. 결과 `build/review-r2/blocked-<크기>/` |
| 9 | 간섭 재현: 작은 Godot 창을 2.5초마다 띄우는 `build/review-r2/interfere_loop.sh`를 켠 채 `check.py --capture --size 390x844`를 후보 2회(`ci1`, `ci2`), main 2회(`mi1`, `mi2`) | 4회 모두 종료 1 (11:17:19–11:19:38). 아래 간헐 실패 표 |
| 10 | `python3 tools/bundle.py verify` | ok, version 1.2.0, files 87, source commit `db888b3…` |

### 간헐 실패 비교 (390x844 렌더 check.py)

| 조건 | 후보 `c6da5af` | main `e7e905d` |
|---|---|---|
| 다른 렌더 창 없음 | 3/3 통과(`c1`, `c2`, `c3`). 같은 조건의 다른 크기 3회(320x568, 844x390, 1280x720)도 통과 | 3/3 통과(`m1`, `m2`, `m3`) |
| 작은 Godot 창을 2.5초마다 띄움(창 10~14번) | 2/2 실패. `ci1`: 여정 `settings-support-language-restart` 9단계(첫 실패 `turn analytics off`), `commerce-pending-reconcile-restore` 3단계(`return to existing purchase` 등). `ci2`: 여정 `leaderboard-states-and-pagination`의 `state failed` | 2/2 실패. `mi1`: 여정 `first-play-reward-and-replay`의 `restart starts at home`, `leaderboard-states-and-pagination`의 `state closed`. `mi2`: 여정은 통과, `e2e_scroll_probe`의 `tap reaches a button that overflows the content by under a pixel` |

간섭 조건의 실패는 모두 1회차와 같은 모양이다. 드라이버의 탭은 참으로 끝났는데 버튼 동작이 일어나지 않고, 실패 위치는 실행마다 다르며, 이번 변경과 무관한 기존 경로(설정, 구매, 순위, 스크롤 probe)에서 난다. main도 같은 비율로 실패하므로 1회차의 후보 2/6 대 main 0/6 차이는 후보 코드가 아니라 같은 시간대에 뜬 다른 세션의 렌더 창 때문이라고 판단한다. 새 코드가 탭을 가로챌 경로도 다시 확인했다. 컷신은 `_finish()`에서 `mouse_filter = MOUSE_FILTER_IGNORE`로 바꾸고 사라진 뒤 숨으며(`cutscene_player.gd:448-466`), `_input`은 idle이거나 키 이벤트가 아니면 바로 돌아간다(`:156-158`). 테스트실은 디버그 빌드에서 모든 제품에 붙지만 닫혀 있으면 숨김이다(`test_room.gd:70-74`). 호스트의 `_unhandled_key_input`은 F9 키만 처리한다(`outgame_main.gd:291-297`). 창 포커스 이동이 탭을 삼키는 구체적인 엔진 경로는 확인하지 않았다(추정).

## 기능 결과

| 항목 | 결과 | 근거 |
|---|---|---|
| 여정 | 14/14 passed, 4개 크기 모두 | 기존 10개 + 1회차 신규 3개 + 한국어 `korean-cutscene-test-room-credits`(7단계). 단계 수 221(1280x720은 가로 검사 1단계가 더해져 222). `map-prologue-first-start-once`는 13 → 16단계(길이 0 프롤로그용 `map ready`와 두 단계 추가) |
| ui-kit probe | 108 checks, 0 failed, 4개 크기 모두 | 1회차 102 = 48 + 27×2에서 모드마다 3개(`skip with credits reaches the end screen before back`, `back on the end screen continues [true]`, `zero-length cut finishes inside play [false]`)가 더해졌다. motion, reduced 모두 통과 |
| dev probe | 21 checks, 0 failed | 1회차와 같다 |
| 부속 probe | camp 2/2, navigation 3/3, scroll-boundary 1/1 | 4개 크기, main 3회 모두 같다 |
| 길이 0 프롤로그 | pass | 여정 `zero-length prologue still enters the game`, `zero-length prologue is recorded as seen`가 4개 크기에서 참. 코드도 `finished`를 `play_cutscene` 전에 `CONNECT_ONE_SHOT`으로 잇고 재생이 막히면 끊는다(`outgame_main.gd:545-552`) |
| 끝 화면 Esc(실제 입력) | pass | `measure.gd`가 `SubViewport.push_input`으로 Esc 누름·뗌을 넣었다. 4개 크기 모두 `state idle`, 화면 `settings`(엔딩 다시 보기를 연 화면) |
| 끝 화면 KEY_BACK, OS 뒤로 가기 | pass | KEY_BACK 키 이벤트와 `root.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)` 모두 `idle`, 화면 `settings`. 호스트가 먼저 알림을 받아 컷신이 열려 있으면 `_back()`을 건너뛰므로 뒤로 가기가 두 번 처리되지 않는다. 계속한 뒤 다음 뒤로 가기는 설정에서 홈으로 한 단계만 간다 |
| 프롤로그 Esc, 테스트실 Esc | pass | 프롤로그 첫 컷에서 Esc로 넘기면 `play`로 간다. 열린 테스트실은 Esc로 닫히고 아래 홈 화면은 그대로다 |
| 크기 실측(애니메이션 끝난 뒤) | pass | 스킵 124x56(320, 390, 844), 173.6x78.4(1280). 계속하기 260x56, 1280에서 364x78.4. 테스트실 닫기 56x56, 행동 버튼 높이 56, 4개 크기 모두 56 미만 0개. 테스트실 프레임은 화면 안. 열림 직후 5프레임에 재면 팝인 배율 때문에 55.5~55.8로 나오므로 40프레임 뒤 값으로 판정했다 |
| 스킵과 자막 겹침 | pass | 4개 크기 모두 사각형이 겹치지 않는다(예: 320x568 스킵 y 16–72, 자막 y 473–534) |
| 묶음·export | pass | `bundle.py verify` ok(1.2.0, 87 files), 단위 테스트의 `test_export_presets` 통과. 1회차 이후 `dev/`, export preset, 공통 코드의 preload는 바뀌지 않았다(diff 5개 파일) |

| AC | 결과 | 근거 |
|---|---|---|
| AC-8 | pass | ui-kit 컷신 60항목(모드별 30) 통과. 새 항목 3개 포함 |
| AC-9 | pass | `map-prologue-first-start-once` 16단계 통과, 길이 0 프롤로그 포함. 기존 10개 시나리오 통과 |
| AC-10 | pass | `settings-credits-and-ending-replay` 21단계 통과. 크레딧 캡처 4개 크기 |
| AC-11 | pass | dev 21항목, `debug-test-room` 20단계 통과 |
| AC-12(기반 몫) | pass | `test_export_presets` 통과, 관련 파일 변경 없음 |
| AC-13 | 부분 pass | 이번 회차 크기 320x568, 844x390과 재확인 크기에서 컷신, 크레딧, 테스트실 본체는 잘림 없이 읽힌다. 다만 320x568 영어 테스트실의 막힌 행동 토스트가 화면 밖으로 잘린다(R2-1) |
| AC-14(기반 몫) | pass | `test_bundle`, `test_ui_contract` 통과, `bundle.py verify` ok |

## 화면 판정

캡처 위치: `build/qa-r2-320x568/`, `build/qa-r2-844x390/`, 재확인 `build/qa-r2-390x844-c1/`, `build/qa-r2-1280x720/`, 확대 crop `build/review-r2/crops/`. 터치 목표는 `measure.json` 실측값이다.

| 캡처 | 320x568 | 844x390 | 근거 |
|---|---|---|---|
| prologue-1 | pass | pass | 흰 글자와 외곽선, 아래 그림자로 자막이 읽힌다. 320은 두 줄로 단어 단위 줄바꿈, 844는 한 줄. 스킵 124x56은 오른쪽 위에 있고 자막과 떨어져 있다 |
| prologue-2 | pass | pass | 밝은 양피지 위에서도 외곽선 덕분에 읽힌다. 844에서 점선이 자막 끝 뒤를 지나지만 글자를 가리지 않는다 |
| prologue-title | pass | pass | "SKY ATLAS" 표시 서체와 부제가 잘리지 않는다. 844에서 등대 줄무늬 위에 놓여도 그림자로 구분된다 |
| credits | pass | pass | 320은 본문이 가죽 띠 안쪽 끝(약 x=34)에서 12px 떨어진 x=46에서 시작한다. 844는 640px 칸이 가운데(x 98–738)에 있다. 섹션 제목 19px 굵게, 글꼴 이름 16px 굵게, 본문 14px로 세 단계가 구분된다 |
| credits-end | pass | pass | 마지막 줄 "SIL Open Font License 1.1"까지 스크롤된다. 위쪽 줄이 스크롤 경계에서 잘리는 것은 목록 스크롤이라 정상이다 |
| settings-ending | pass | pass | "Replay ending", "Credits", "Test room"이 기존 설정 버튼과 같은 판·높이(48px)로 목록 끝에 들어간다. 844에서는 설정 버튼이 프레임 폭(약 760px)으로 늘어나는데 기존 설정 화면과 같은 배치다 |
| ending-1 | pass | pass | 다시 보기라 첫 컷에서도 스킵이 활성이다. 320에서 기구가 왼쪽 가장자리에 닿는다(1회차 F-6, 그림 구도) |
| ending-count | pass | pass | "12,800"이 공용 숫자 표기로 자막 위에 있다 |
| ending-credits | pass | pass | 롤은 스킵 아래(y 80)부터만 보여 버튼과 겹치지 않는다. 경계가 페이드 없이 딱 잘려 반쯤 잘린 제목이 보이는 순간이 있다(R2-4, 참고) |
| ending-end | pass | pass | 금색 "Continue" 260x56이 가운데에 있다. Esc, KEY_BACK, OS 뒤로 가기가 계속하기와 같이 동작한다 |
| test-room | pass | pass | 320은 2열, 844는 3열(프레임 760px). 844는 높이 390에서 제목과 두 줄 결과 줄 아래 스크롤 영역이 170px이라 첫 화면에 "Add 100 coins"와 진행 행 일부가 보이고 나머지는 스크롤한다. 설계의 "낮은 화면에서도 첫 화면에 버튼이 보인다"를 충족한다 |
| test-room-armed | pass | pass | 무장한 버튼만 금색 "Tap again to apply"로 바뀌고 다른 버튼 위치는 그대로다. 결과 줄 "Coins 0 → 100" |
| test-room-blocked | **fail** | pass | 320에서 토스트 "Finish the current round first"가 폭 364px이라 화면(320px) 밖으로 나가 "…round fir"까지만 보인다(R2-1). 844는 토스트가 프레임 위 띠 안에 다 들어간다. 결과 줄은 두 줄 고정 높이를 지킨다 |
| prologue-1-ko | pass | pass | "건너뛰기"가 버튼 안에 한 줄로 들어간다. 자막 "오래전, 하늘 군도의 바람 지도가 / 흩어졌다."는 어절 단위로 줄바꿈된다 |
| test-room-ko | pass | pass | 버튼과 구역 제목이 프레임 안에 있다. 320에서 "코인 100 추 / 가"처럼 단어 안에서 줄이 바뀐다(R2-2). 844는 모두 한 줄 |
| credits-ko | pass | pass | 칸과 여백은 영어와 같다. 320에서 "만들었습니 / 다"처럼 마지막 음절 하나가 줄로 떨어진다(R2-2). 844는 한 줄씩 들어간다 |

F-1 재확인:

| 캡처 | 390x844 | 1280x720 | 근거 |
|---|---|---|---|
| credits | pass | pass | 390은 본문이 x=46에서 시작해 띠 안쪽 끝에서 12px 떨어진다(1회차는 1~2px). 1280은 640px 칸이 가운데(x 320–960)에 있고 프레임 양쪽에서 305px씩 떨어진다. 글꼴 이름이 굵은 16px로 저작권 줄과 구분된다 |
| credits-end(1280) | pass | – | 마지막 라이선스까지 스크롤 없이 모두 보인다 |
| credits-ko(390) | pass | pass | 칸과 여백 정상. 390에서 "AI 도구로 만들 / 고 팀이"처럼 단어 안 줄바꿈이 있다(R2-2) |

## 1회차 지적 확인

| 지적 | 상태 | 근거 |
|---|---|---|
| F-1 크레딧 여백, PC 배치, 글꼴 이름 구분 | 해결 | `CreditsColumn` MarginContainer가 좌우 `max(12×배율, (폭 − 640×배율)/2)` 여백을 준다(`outgame_main.gd:792-824`). 실측 본문 시작점이 띠 안쪽에서 12px(320, 390), 1280에서 가운데 640px 칸. 글꼴 이름은 제목 글꼴 16px 줄로 분리됐다 |
| F-2 끝 화면 Esc·뒤로 가기 무반응 | 해결 | `request_back()`이 끝 화면에서 `_finish`를 부른다(`cutscene_player.gd:137-143`). probe 새 항목과 검수자의 실제 Esc 키, KEY_BACK, OS 뒤로 가기 알림이 모두 계속하기와 같이 동작하고 아래 화면이 한 번 더 뒤로 가지 않는다 |
| F-3 렌더 모드 간헐 실패 | 해결(원인 확인) | 다른 렌더 창이 없을 때 후보 3/3(다른 크기 포함 6/6), main 3/3 통과. 작은 Godot 창을 반복해 띄우면 후보 2/2, main 2/2가 같은 모양으로 실패한다. 후보 코드 탓이 아니라 실행 환경의 다른 창이 원인이다. `ui_navigation_probe`가 실패 시 180초까지 멈추는 기존 문제는 그대로다(R2-3) |
| F-4 안전 영역 | 남음(참고) | 공용 기반의 안전 영역 처리는 바뀌지 않았다. 개발 환경에서 확인할 수 없어 소비 게임 단계 항목으로 남긴다 |
| F-5 한국어 캡처 | 해결 | 여정 `korean-cutscene-test-room-credits`가 `prologue-1-ko`, `test-room-ko`, `credits-ko`를 4개 크기에서 찍는다. 다만 "Korean subtitle" 단계는 영어 문장과 다르다는 것만 본다 |
| F-6 정사각 컷 그림 잘림 | 남음(참고) | 그림과 README 안내는 바뀌지 않았다. 320x568 ending-1에서 기구가 왼쪽 가장자리에 닿는다 |

## 발견 사항

- R2-1 (수정 권장, `godot/addons/seorilabs_game/ui_kit/hud_layers.gd:15-27`의 `toast()`, 호출 `dev/test_room.gd:270-272`, `flow/outgame_main.gd:382-384`의 `_toast_blocked`, 캡처 `build/qa-r2-320x568/test-room-blocked.png`, crop `build/review-r2/crops/320-blocked-toast.png`, 측정 `build/review-r2/blocked-*/`): 공용 토스트는 숫자용 고정폭 글꼴(`NumberLabel`)의 한 줄 Label이고 줄바꿈과 최대 폭이 없다. 이번 변경이 처음으로 문장 길이의 안내를 이 토스트로 보낸다(main의 `outgame_main.gd`에는 `toast(` 호출이 없다). 영어 "Finish the current round first"는 칩 폭이 364px이라 뷰포트 폭 320과 360에서 x=0부터 화면 밖으로 나가 "Finish the current round fir"까지만 보인다. 한국어 "진행 중인 판을 먼저 끝내 주세요"는 297px이라 들어간다. 실패 시나리오: 320 폭 화면에서 플레이테스터가 판 진행 중 테스트실의 "Add 100 coins"를 누르면 막힌 이유 끝이 잘린다. 같은 토스트로 가는 제품의 `blocked_reason_pair`(설정의 "Replay ending" 경로는 플레이어에게 보인다)도 28자를 넘으면 같은 일이 생긴다. 영향 범위: 레퍼런스 프로젝트는 기준 크기 390x844에 `canvas_items`·`expand` 늘이기라 실제 기기에서 논리 폭이 390 아래로 내려가지 않으므로 이 저장소 레퍼런스에서는 드물다. 그러나 설계가 320x568을 판정 크기로 정했고, 다른 기준 크기를 쓰는 소비 게임에서는 실제로 생긴다. 제안: 토스트에 화면 폭 − 32px 최대 폭과 줄바꿈을 주고, 문장 안내에는 본문 글꼴을 쓴다(숫자 토스트만 `NumberLabel` 유지).
- R2-2 (수정 권장, 새 화면의 한국어 Label·Button 줄바꿈, 캡처 `qa-r2-320x568/credits-ko.png`, `qa-r2-320x568/test-room-ko.png`, `qa-r2-390x844-c1/credits-ko.png`, `qa-r2-390x844-c1/test-room-ko.png`, 비교 crop `build/review-r2/crops/ko-credits-r1-vs-r2.png`): 한국어 문장이 어절이 아니라 음절 사이에서 줄바꿈된다. 320 크레딧 "만들었습니 / 다", 320 테스트실 버튼 "코인 100 추 / 가", 390 크레딧 "AI 도구로 만들 / 고", 390 테스트실 봐줄 점 "적용해 / 요.", "라이선스 / 가 있어요." 1회차 390 캡처에도 "팀 / 이 검토했습니다"가 있어 이번 수정의 회귀가 아니라 공용 Label 줄바꿈(`AUTOWRAP_WORD_SMART`)의 기존 동작이다. 실패 시나리오: 작은 폰에서 설정 → 크레딧을 연 한국어 플레이어가 "다" 한 글자만 있는 줄을 보고, 테스트실 버튼 "추 / 가"는 버튼 문구가 깨진 것처럼 보인다. 글자는 모두 보이므로 AC-13의 "잘리지 않음"은 충족한다. 제안: 공용 키트에서 한국어 어절 유지 줄바꿈 방법(ICU 줄바꿈 옵션이 Godot에서 먹는지, 또는 어절 안 음절 사이에 단어 결합 문자 U+2060을 넣는 방식)을 확인해 적용하고, 그 전까지는 테스트실 행동 버튼을 폭 360 미만에서 1열로 두거나 문구를 줄인다(예: "코인 +100").
- R2-3 (참고, 검수 환경, `tests/reference/ui_navigation_probe.gd:46`, `tests/common/e2e_driver.gd:94-108`): 렌더 check.py는 같은 기기에서 다른 Godot 창이 뜨면 후보와 main 모두 탭이 무시되어 실패한다(위 간섭 표). 실패 위치가 실행마다 달라 실제 회귀처럼 보일 수 있다. 3회차와 CI 밖 로컬 검수는 렌더 실행 전에 다른 Godot 창이 없는지 확인하고, 실패하면 같은 조건에서 main과 나란히 다시 돌려 구분할 것을 권한다. 드라이버가 실행 중 창 포커스 이탈을 기록해 그 실행을 무효로 표시하면 판단이 쉬워진다(제안, 구현 범위 밖). `ui_navigation_probe`가 단계 실패 뒤 180초 제한까지 멈추는 1회차 지적은 기존 코드라 그대로다.
- R2-4 (참고, 시각 완성도): 엔딩 크레딧 롤은 스킵 아래 y=80에서 페이드 없이 잘려 반쯤 잘린 제목이 보이는 순간이 있다(`ending-credits.png` 320, 844, crop `320-ending-credits-top.png`). 설정 크레딧은 글꼴 이름 줄이 앞 묶음의 마지막 줄과 자기 저작권 줄에서 같은 간격(10px 분리)이라 이름이 어느 묶음에 속하는지 근접성으로는 약하게 드러난다. 둘 다 읽기를 막지 않는다. 제안: 롤 위 경계에 짧은 알파 그라데이션, 글꼴 묶음 사이 간격을 묶음 안 간격보다 넓게.

## 판정

pass. 후보 `c6da5af`는 1회차의 수정 권장 두 건을 고쳤다. 크레딧은 띠에서 12px 떨어진 읽기 칸과 PC 가운데 640px 칸, 굵은 글꼴 이름으로 바뀌었고(F-1), 끝 화면의 Esc, KEY_BACK, OS 뒤로 가기는 실제 입력 경로에서 계속하기와 같이 동작하며 아래 화면을 한 번 더 움직이지 않는다(F-2). 길이 0 프롤로그도 게임으로 들어가고 본 기록이 남는다. 4개 크기에서 check.py가 통과했고 여정 14개, ui-kit 108항목, dev 21항목이 모두 통과했다. 새 버튼은 모든 크기에서 56px 이상이고 스킵과 자막은 겹치지 않는다.

1회차의 렌더 간헐 실패는 실행 환경의 다른 Godot 창이 원인이다. 다른 창이 없을 때 후보와 main 모두 3/3 통과했고, 창을 일부러 띄우면 둘 다 2/2 같은 모양으로 실패했다.

320x568 영어 테스트실의 막힌 행동 토스트 잘림(R2-1)은 AC-13의 "잘리지 않음"에 어긋나므로 test-room-blocked 320x568을 fail로 적었다. 그래도 차단으로 보지 않은 이유는 세 가지다. 잘린 것은 바뀌지 않은 공용 토스트이고 테스트실 본체(프레임, 버튼, 결과 줄)는 통과한다. 디버그·playtest 빌드에만 있는 화면이며 문장 뜻은 남는다. 이 저장소 레퍼런스의 늘이기 설정에서는 실제 논리 폭이 390 아래로 내려가지 않는다. 3회차 전에 R2-1과 R2-2를 고치기를 권하고, 고치지 않으면 3회차가 그 판단을 다시 확인한다.

검수 캡처와 로그 원본은 이 worktree의 `build/` 아래에만 있다(`qa-r2-320x568`, `qa-r2-844x390`, `qa-r2-1280x720`, `qa-r2-390x844-c1`~`c3`, `qa-r2-390x844-ci1`·`ci2`, `main-runs/`(main 실행의 json·로그 사본), `review-r2/`(보조 스크립트, 측정값, crop), `logs/`). main 비교용 worktree는 삭제했고, 실행이 만든 격리 저장 폴더 28개와 간섭용 프로젝트의 사용자 폴더도 지웠다. NAS1dual 이관은 PR 정리 단계에서 한다.

## 증적 보관

본문의 `build/` 경로는 검수용 임시 worktree였고 지웠다. 원본(캡처, 로그, 측정 결과)은 NAS1dual `agent-artifacts/game-foundation/2026-11-26/c6da5afff4d589c44d673b72d146d183ba273eef/cutscene-test-room-review-r2`에 옮겼고, 같은 폴더의 `MANIFEST.txt`가 파일별 크기와 SHA-256과 검증 완료를 적는다(2026-11-26). starter 복사본과 묶음 tar, export 패키지처럼 다시 만들 수 있는 파일은 옮기지 않았다.
