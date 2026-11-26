# 컷신 재생기, 크레딧, 테스트실 독립 검수 5회차

- 검수자: 독립 검수 에이전트 5 (구현자, 1~4회차 검수자와 다른 에이전트)
- 승인 근거: 2026-11-26 사용자 "5회차 진행"(4회차 fail 뒤 추가 회차 승인)
- 대상: seorilabs/game-foundation `cutscene-test-room`, 후보 SHA `33dbf93b18a0bb40a3ac1a20570ca906a3e11111`, 기준 main `e7e905df9aefe8f50f917ba103f6bcdcf240f60e`(fetch 뒤 origin/main, 후보의 merge-base와 같음)
- 4회차 이후 변경(`git log 14d8acc..HEAD`): `9d03bf6`(긴 토스트가 `NumberLabel` 변형을 지우지 않고 글꼴만 덮어씀, ui-kit probe가 층에 스킨 테마를 주고 글자색·외곽선·글꼴 확인, dev_probe가 390 막힌 이유 한 줄·본문 글꼴 확인과 id 경계 확인, 테스트실 id→버튼 사전, 설계 게이트 문장), `ff332f7`(덮어쓸 글꼴을 `get_theme_default_font()`로), 잠금 갱신 `650bee1`, `33dbf93`
- 크기: 390x844, 320x568, 844x390, 1280x720 (4개 모두 판정). 부속 probe는 도구 고정값. 소비 저장소는 starter 기준 크기 1280x720. 1.1.0 토스트 비교는 390x844
- 실행 시각: 2026-11-26 13:55–14:20 UTC
- 실행 환경: dev headless 검증 + 렌더링 캡처. Godot 4.7.2.stable.official.ed1daf0bf(Compatibility, Apple M3), macOS 27.2.1, Python 3.14.7, Node 24.16.0. 격리 worktree `game-foundation.worktrees/review-r5`(detached `33dbf93`), 비교용 임시 worktree `review-r5-main`(detached `e7e905d`, 비교 뒤 삭제). 소비 저장소는 starter-template-game `markets-v2`(`811a87b`, 기준 화면 1280x720 `canvas_items`/`expand`, 잠금 1.1.0)를 `build/consumer/`에 복사해 그 안에 검사용 git 저장소를 만들었다(무시 대상 파일은 복사본 안에서만 `git clean -X`로 지워 깨끗한 checkout과 같게 했다). 저장은 여정과 보조 스크립트의 격리 프로필만 썼고, 실행 뒤 이번 실행이 만든 Godot 사용자 폴더 항목 40개(레퍼런스 36개, starter 4개, 생성 시각으로 확인)를 지웠다. 렌더 실행 동안 별도 감시 루프(`build/logs/godot-monitor.log`, 14:01:10부터 2초 간격)가 이 worktree 밖의 Godot 프로세스를 기록했다
- 설계: `docs/design/2026-11-26-cutscene-test-room/design.md` AC-8~AC-14, "사용자 흐름·화면 상태", "품질 요구사항", "데이터·인터페이스·실패 처리"(노출 게이트). 상위 설계 agent-config `docs/design/2026-11-26-game-skill-system-v2/design.md` AC-8~AC-14. 테스트 계획 `test-plan.json` L3, dev, redesign, release null. 이전 기록 1~4회차(4회차 fail, R4-1~R4-3)

## 검수 계획

실행 전에 적은 계획이다(13:56 UTC). 이번 회차는 4회차 차단 지적 R4-1(긴 토스트 글자가 갈색 칩 위에서 안 보임)이 실제 픽셀에서 사라졌는지, 그 수정이 화면 안에 드는 1.1.0 토스트를 바꾸지 않았는지, R4-2(테스트실 버튼 찾기)와 R4-3(설계 문장)이 해결됐는지를 중심으로 전체 회귀를 다시 본다.

| 순서 | 영역 | 내용 | 통과 기준 |
|---|---|---|---|
| 0 | 환경 | 렌더 실행 전마다 `pgrep -fl -i godot`로 다른 Godot 렌더 프로세스가 없는지 확인한다(MCP 서버는 제외). 있으면 기다렸다가 다시 확인하고 본 것을 기록한다 | 렌더 시작 시 다른 렌더 프로세스 없음 |
| 1 | 기능 | `npm test`, `python3 tools/bundle.py verify` | 종료 0, 단위 테스트 건너뜀 없음, verify ok |
| 2 | 렌더링 | `python3 tools/check.py --capture --size <크기> --out build/qa-r5-<크기>`를 390x844, 320x568, 844x390, 1280x720으로 | 4개 모두 종료 0 |
| 3 | 화면 | Read 도구로 새 화면 16종(prologue-1/2/title, credits, credits-end, settings-ending, ending-1, ending-count, ending-credits, ending-end, test-room, test-room-armed, test-room-blocked, prologue-1-ko, test-room-ko, credits-ko)을 4개 크기 모두 본다 | 잘림 없음, 글자 읽힘 |
| 3a | 토스트 대비 | 캡처에 보이는 모든 토스트에서 글자 픽셀과 칩 배경 픽셀을 PNG에서 뽑아 WCAG 대비를 잰다. 390, 320에서 막힌 이유 토스트가 테스트실 제목과 닫기 버튼을 덮지 않는지 사각형으로 확인한다 | 글자 대비 4.5:1 이상(4회차 1.2~1.3:1이 사라짐), 겹침 없음 |
| 4 | 1.1.0 토스트 비교 | origin/main 임시 detached worktree에서 390x844 렌더 `check.py` 1회. 토스트가 보이는 화면을 후보와 비교한다. `build/` 아래 일회용 스크립트로 짧은 한 줄, 명시적 `\n` 두 줄(`"Could not save.\nTap again to retry."`), 호출 뒤 글꼴을 바꾸는 토스트, 폭을 넘는 토스트를 후보와 main에서 같은 390x844 렌더로 찍어 칩 사각형, 글자색, 픽셀을 비교한다. 비교 뒤 main worktree를 지운다 | 화면 안에 드는 토스트는 main과 픽셀 동일, 폭을 넘는 토스트는 화면 안이고 글자가 읽힘 |
| 5 | 소비 저장소 | starter `markets-v2`를 `rsync -a --exclude .git --exclude build --exclude .godot`로 `build/consumer/`에 복사, `git init`과 커밋, 후보의 `tools/bundle.py`, `tools/test_bundle.py`, `tools/validate_outgame.py` 복사, 후보 `bundle.py pack`, 복사본에 설치, `uiStandard.version` 1.2.0, 복사본 `tools/check.py`에 후보와 같은 `dev_probe` 명령과 `checks` 항목, 커밋, `npm test` | 종료 0, ui-kit·dev probe 0 failed |
| 6 | R4-2 | `build/` 아래 일회용 스크립트로 id `a.b`와 `a_b` 두 번 누름, `*`와 `?`가 든 id(와일드카드로 다른 버튼과 겹칠 수 있는 이름 포함)를 실제 마우스 이벤트로 눌러 각자 자기 버튼이 무장하고 자기 행동만 실행되는지 본다 | 각 버튼이 자기 무장·적용, 다른 행동 실행 0회 |
| 7 | R4-3 | 설계 문장과 인터페이스 줄이 코드(`outgame_main`의 게이트)와 같은지 읽어서 확인한다 | 일치 |
| 8 | 판정 | 4회차 지적별 해결 여부, 새 발견 사항을 실패 시나리오와 함께 적는다 | |

실행 중 계획에 더한 것: 렌더 check.py 1차 실행에서 390x844와 844x390이 후보와 무관한 부속 probe의 탭 무시로 실패해, 같은 명령을 한 번 더 돌리고 실패한 출력은 `-try1`로 남겼다(아래 R5-2). 이후 렌더 실행 동안 다른 Godot 프로세스를 2초 간격으로 기록하는 감시 루프를 켰다. 3a의 닫기 버튼 겹침은 캡처만으로 사각형을 정할 수 없어, 레퍼런스 map 제품을 여정과 같은 SubViewport 크기로 여는 headless 보조 스크립트(`build/review-r5/rects_probe.gd`)로 칩, 제목, 닫기 버튼 사각형을 재고 토스트 아래 닫기 버튼 윗부분을 눌러 봤다. 토스트 비교(4)는 320x568도 함께 찍었고, 호출 문구에 `outgame_main`이 실제로 띄우는 문구("A scene is already playing", "Could not save. Try again.", "저장하지 못했습니다. 다시 시도해 주세요.", "Not available right now", "지금은 할 수 없어요")와 두 토스트가 쌓이는 경우를 더했다. 회귀 방지 검사가 R4-1을 실제로 잡는지 보려고, 후보 프로젝트 사본의 `_fit_toast`만 4회차 코드(변형 지우기)로 되돌려 두 probe를 돌렸다.

## 실행 명령과 결과

모든 명령은 격리 worktree 루트에서 실행했다. 실행 시각과 종료 코드는 `build/logs/runs.log`, 렌더 전 확인은 `build/logs/guard.log`, 명령별 출력은 `build/logs/<이름>.log`에 있다.

| 순서 | 명령 | 결과 |
|---|---|---|
| 0 | 렌더 실행 전마다 `build/review-r5/guard.sh`(`pgrep -fl -i godot`에서 godot-mcp를 뺀 Godot 실행 파일 프로세스가 없을 때까지 대기) | 13회 모두 대기 0회. 잡힌 것은 godot-mcp 서버(npm exec와 node, 9~13줄)뿐이었다. 감시 루프는 14:03:44 이후 다른 세션의 smash-and-slice Godot 실행(headless와 `--resolution 1280x720` 렌더)을 기록했지만 다른 세션의 렌더 실행(14:06:36–14:07:53)은 이번 렌더 실행 사이에 있었고 겹치지 않았다. 겹친 것은 1280x720 렌더 실행 끝 22초 동안 뜬 다른 세션의 headless 프로세스 3개뿐이고 그 실행은 통과했다 |
| 1 | `npm test` | 종료 0 (13:56:40–13:57:31). 단위 테스트 35개 OK(건너뜀 0, `test_consumer_scale`, `test_export_presets` 포함), check.py `{"ok": true, "scenarios": 14}`. headless ui-kit 111/0, dev 26/0, ui-contract 87/0 |
| 2 | `python3 tools/bundle.py verify` | ok, version 1.2.0, files 87, source commit `ff332f7…`(잠금이 가리키는 직전 커밋) |
| 3 | `check.py --capture --size 390x844 --out build/qa-r5-390x844` 1차 | **종료 1** (13:57:48–14:01:29). 여정 14/14, ui-kit·dev·ui-contract 0 failed까지 통과한 뒤 마지막 부속 `ui_navigation_probe`(도구 고정 320x568)의 "request provider UI" 탭이 무시되고 180초 제한에 걸렸다. 출력 `build/qa-r5-390x844-try1/` |
| 4 | 같은 명령 320x568 | 종료 0 (14:01:29–14:02:21), 14개 시나리오 |
| 5 | 같은 명령 844x390 1차 | **종료 1** (14:02:21–14:03:17). 부속 `e2e_scroll_probe`(도구 고정 390x844, 후보 코드를 쓰지 않는 ScrollContainer 고정물)의 첫 끌기와 탭이 무시됐다. 같은 시간대 다른 Godot 프로세스 없음(감시 기록). 출력 `build/qa-r5-844x390-try1/` |
| 6 | 같은 명령 1280x720 | 종료 0 (14:03:17–14:04:06), 14개 시나리오 |
| 7 | 390x844 2차 | 종료 0 (14:04:12–14:04:57), 14개 시나리오, navigation 3/3 |
| 8 | 844x390 2차 | 종료 0 (14:04:57–14:06:04), 14개 시나리오, scroll-boundary 1/1 |
| 9 | 보조 `rects_probe.gd`(headless, 4개 크기) | 4회 종료 0, ERROR 0. 결과 `build/review-r5/rects-<크기>.json` |
| 10 | 보조 `r42_probe.gd`(headless) | 종료 0, `ok: true`, ERROR 0. 결과 `build/review-r5/r42.json` |
| 11 | origin/main `e7e905d` 임시 worktree에서 `check.py --capture --size 390x844` | 종료 0 (14:08:31–14:09:13), 10개 시나리오. 캡처 사본 `build/main-run/qa-main-390x844/` |
| 12 | 보조 `toast_probe.gd`(토스트 18개 호출, 19개 칩), 후보와 main, 390x844와 320x568 렌더 | 4회 모두 종료 0 (14:09:14–14:10:19). 결과 `build/review-r5/toast-<cand|main>-<크기>/`, 비교표 `build/review-r5/toast-compare.txt` |
| 13 | main worktree 삭제(`git worktree remove`) | 삭제. 추적 파일 변경 없음을 먼저 확인했다 |
| 14 | 소비 복사본 준비와 설치(아래 소비 저장소 결과) | 커밋 `4939256`(starter `811a87b` 복사본), 설치 커밋 `afc315e` |
| 15 | 복사본 `npm test` | **종료 0** (14:11:59–14:12:57) |
| 16 | 감도 확인: 후보 `godot/` 사본의 `_fit_toast`를 4회차 코드로 되돌리고 `ui_kit_probe`, `dev_probe` headless | ui-kit 111 checks **1 failed**(`layers: long toast switches only the font and keeps the chip text color and outline`), dev 26/0. 확인 뒤 사본 삭제 |

## 기능 결과

| 항목 | 결과 | 근거 |
|---|---|---|
| 여정 | 14/14 passed, 4개 크기 모두(최종 실행) | 단계 수 221, 1280x720은 가로 검사가 더해져 222. 4회차와 같다 |
| ui-kit probe | 111 checks, 0 failed, 4개 크기, headless, 소비 복사본 모두 | 4회차의 긴 토스트 항목이 "글꼴만 바꾸고 칩 글자색과 외곽선을 유지"로 바뀌었다. 4회차 코드로 되돌리면 이 항목이 실패한다(순서 16) |
| dev probe | 26 checks, 0 failed, 4개 크기, headless, 소비 복사본 모두 | 4회차 21 + `blocked reason fits one line in the body font at 390`, `action without a return value counts as done`, `a_b arms its own button, not a.b`, `a_b applies on the second tap`, `ids with * and ? arm and apply` |
| ui-contract probe | 87 checks, 0 failed | 4개 크기 모두 |
| 부속 probe | camp 2/2, navigation 3/3, scroll-boundary 1/1 | 최종 실행 4개 크기 모두. 1차 실행의 두 실패는 R5-2 |
| main과 바뀌지 않은 화면(390x844) | 토스트 없음, 차이는 설명 가능 | 공통 캡처 26장 중 5장 픽셀 동일, 21장이 다르다. 채널 차이 16 이하를 빼면 10장이 0픽셀이다. 남은 11장 중 `settings-ko`는 설정 목록에 "Credits", "Test room"이 더해진 차이다. `popup-open`, `purchase-pending`, `ranking-closed`, `ranking-empty`, `ranking-unranked`, `reward-impact`, `reward-settle` 7장은 후보 1차와 2차 실행끼리도 main과 비슷한 크기(46~51,000픽셀)로 달라 전환 중간 프레임의 흔들림으로 본다. `support`, `ranking-offline`, `large-text-ko` 3장은 후보 두 실행끼리는 같지만(0~16픽셀) main과는 판 테두리와 나뭇결 가장자리 1px 안팎만 다르고 글자, 버튼, 배치는 같다(`build/review-r5/crops/main-vs-cand-*.png`). main에는 `layers.toast` 호출이 없어 main 캡처에는 토스트가 없고, 후보 여정에서 토스트가 보이는 캡처는 `test-room-blocked` 하나다 |
| 묶음·export | pass | `bundle.py verify` ok, `test_export_presets` 2개 통과 |

| AC | 결과 | 근거 |
|---|---|---|
| AC-8 | pass | ui-kit 컷신 항목 motion·reduced 통과(4개 크기, headless, 기준 1280x720 소비 복사본) |
| AC-9 | pass | `map-prologue-first-start-once` 16단계, 기존 10개 시나리오 통과 |
| AC-10 | pass | `settings-credits-and-ending-replay` 21단계, 크레딧 캡처 4개 크기 |
| AC-11 | pass | dev 26항목, `debug-test-room` 20단계. 막힌 행동 토스트가 이제 4개 크기 모두 읽힌다(아래 대비 표) |
| AC-12(기반 몫) | pass | `test_export_presets` 통과. 이번 변경은 preset을 건드리지 않았다 |
| AC-13 | **pass(4개 크기)** | 아래 화면 판정 |
| AC-14(기반 몫) | pass | `test_bundle` 7개, `test_ui_contract` 2개 통과, `bundle.py verify` ok. 상위 AC-14의 starter 설치도 `npm test`까지 통과 |

R4-2 보조 결과(`build/review-r5/r42.json`). 행동 7개를 모두 `confirm: "double_tap"`으로 등록하고, 와일드카드로 해석하면 먼저 등록한 버튼과 겹치는 이름(`x1` 뒤 `x*`, `abc` 뒤 `a?c`)을 일부러 뒤에 등록했다. 버튼은 390x844 창에 마우스 누름과 뗌 이벤트를 넣어 눌렀다.

| 경우 | 첫 탭 | 둘째 탭 | 판정 |
|---|---|---|---|
| `a_b`(노드 이름이 `@Button@8`로 자동 지정됨)와 `a.b`(노드 이름 `test_action_a_b`) | 누른 버튼만 "Tap again to apply", 상대는 그대로, 실행 0회 | 누른 행동만 1회, 결과 줄 "Applied a_b"/"Applied a.b", 이름 복원 | 해결(양쪽 순서 모두) |
| `x*`와 `x1` | 같음 | 같음 | 해결 |
| `a?c`와 `abc` | 같음 | 같음 | 해결 |
| `w*?`와 `a_b` | 같음 | 같음 | 해결 |
| `a.b` 무장 뒤 `a_b` 탭 | `a.b` 원래 이름으로, `a_b` 무장, 실행 0회 | | 해결 |
| 무장 중 닫기 | 원래 이름으로 돌아감 | | 해결 |

## 화면 판정

캡처 위치: `build/qa-r5-390x844/`, `build/qa-r5-320x568/`, `build/qa-r5-844x390/`, `build/qa-r5-1280x720/`(최종 실행). 묶음 보기 `build/review-r5/sheets/`(`p390-1..4`, `p320-1..4`, `l844-1..4` 0.9배, `l1280-1..4` 0.6배), 확대 crop `build/review-r5/crops/`. 390x844 `test-room-blocked`는 원본 크기로, 390과 320의 테스트실 윗부분은 3배와 4배로, 1280x720의 `test-room-blocked` 윗부분과 `credits` 가운데는 원본 크기로 봤다. 390x844 1차 실행 캡처도 같은 방식으로 본 뒤 2차와 픽셀로 비교했다. 테스트실과 설정 화면은 두 실행이 픽셀 동일했고, 컷신과 크레딧은 움직임 위치만 달라 2차 캡처를 다시 봤다.

| 캡처 | 390x844 | 320x568 | 844x390 | 1280x720 | 근거 |
|---|---|---|---|---|---|
| prologue-1 | pass | pass | pass | pass | 흰 자막과 외곽선이 어두운 아래 띠에서 읽힌다. 세로 두 줄, 가로 한 줄. 스킵은 오른쪽 위 판 안 |
| prologue-2 | pass | pass | pass | pass | 밝은 양피지 그림 아래 어두운 띠 위에서 외곽선으로 읽힌다 |
| prologue-title | pass | pass | pass | pass | "SKY ATLAS"와 "Chart the lost skies"가 잘리지 않는다 |
| credits | pass | pass | pass | pass | 제목, 제품 문구, AI 고지, 글꼴 이름과 저작권 줄이 판 안에 있고 아래는 스크롤로 이어진다. 1280은 원본 크기에서 13~14px 본문이 읽힌다 |
| credits-end | pass | pass | pass | pass | 마지막 "Noto Sans Mono"의 "SIL Open Font License 1.1"까지 보인다 |
| settings-ending | pass | pass | pass | pass | "Replay ending", "Credits", "Test room"이 기존 설정 버튼과 같은 판으로 목록 끝에 있다. 844는 목록 스크롤 중이라 "Test room"이 아래 경계에 걸린다(스크롤 목록 상태) |
| ending-1 | pass | pass | pass | pass | 자막이 읽힌다. 390, 320에서 등대가 화면 밖(F-6, 그림 구도, 참고) |
| ending-count | pass | pass | pass | pass | "12,800"이 금색 숫자와 외곽선으로 읽힌다 |
| ending-credits | pass | pass | pass | pass | 롤 글자가 어두운 바탕에서 읽힌다. 320에서 롤 맨 윗줄이 스킵 버튼 높이를 지날 때 페이드 없이 잘린다(R2-4, 참고) |
| ending-end | pass | pass | pass | pass | 금색 "Continue"가 가운데에 있다 |
| test-room | pass | pass | pass | pass | 320·390 2열, 844·1280 3열. 844에서도 첫 화면에 행동 버튼이 보인다 |
| test-room-armed | pass | pass | pass | pass | 무장한 프리셋만 금색 "Tap again to apply", 결과 줄 "Coins 0 → 100" |
| test-room-blocked | pass | pass | pass | pass | 390·320: "Finish the current round first"가 본문 글꼴 한 줄, 밝은 글자(#fff7df)와 청록 외곽선으로 갈색 칩 위에서 읽힌다(대비 10.95:1). 제목과 6px 떨어져 있고, 닫기 버튼은 그림 위 테두리 4px만 칩에 닿는다(× 글자와 누르는 면은 보이고 눌린다, R5-1). 844·1280: 숫자 글꼴 한 줄, 11.01:1, 제목·닫기와 겹치지 않는다 |
| prologue-1-ko | pass | pass | pass | pass | "건너뛰기"가 버튼 안 한 줄, 한국어 자막 읽힘 |
| test-room-ko | pass | pass | pass | pass | 글자는 모두 보인다. 320 "코인 100 추 / 가", 390 "적용해 / 요."처럼 음절 단위 줄바꿈은 그대로(R2-2, #26, 범위 밖) |
| credits-ko | pass | pass | pass | pass | 320 "만들었습니 / 다", 390 "만들 / 고"(R2-2, 범위 밖) |

## 토스트 대비 측정

측정 방법(`build/review-r5/contrast.py`): 칩의 글자 영역(라벨 사각형, 여정 캡처에서는 막힌 화면과 같은 테스트실 기본 화면의 차이로 찾은 칩에서 칩 내용 여백만큼 안쪽)에서 휘도 중앙값 근처 픽셀의 채널별 중앙값을 바탕, 바탕과 휘도 차이가 가장 큰 상위 5% 픽셀의 채널별 중앙값을 글자로 잡고 WCAG 대비를 계산했다. 비교 기준은 4회차 측정값(390·320 `test-room-blocked` 약 1.2~1.3:1, 글자 #244e5c, 외곽선 0)과 WCAG 본문 기준 4.5:1이다.

여정 캡처의 토스트(`build/review-r5/capture-toast.json`, 칩 배치는 `rects-<크기>.json`):

| 크기 | 칩(레이아웃 x0,y0–x1,y1) | 글꼴, 줄 수 | 글자 / 칩 바탕(픽셀) | 대비 |
|---|---|---|---|---|
| 390x844 | 51,24–339,55 (288x31) | 본문(Noto Sans KR), 1줄, 외곽선 4 | #fff7df / #4f311f | **10.95:1** |
| 320x568 | 16,24–304,55 (288x31) | 본문, 1줄, 외곽선 4 | #fff7df / #4f311f | **10.95:1** |
| 844x390 | 240,24–604,54 (364x30) | 숫자(Noto Sans Mono), 1줄, 외곽선 4 | #fff7df / #4e311e | 11.01:1 |
| 1280x720 | 458,24–822,54 (364x30) | 숫자, 1줄, 외곽선 4 | #fff7df / #4e311e | 11.01:1 |

보조 토스트 비교(후보, `toast-compare.txt`): 390x844와 320x568에서 찍은 칩 19개 모두 글자 #fff7df(한국어 두 줄과 짧은 한국어는 안티앨리어싱으로 #f2edd8~#f8f2db), 외곽선 4(we-moore 방식만 호출한 쪽이 정한 대로 외곽선 0)이고 대비는 9.41~11.69:1이다. 폭을 넘어 본문 글꼴로 바뀐 칩만 보면 9.88~11.69:1이다.

| 호출 | 390 후보 | 320 후보 |
|---|---|---|
| "Saved", "+10 coins", "12,800", "저장했어요" | 10.11~11.0:1, main과 픽셀 동일 | 같음 |
| "Could not save.\nTap again to retry.", 한국어 두 줄 | 10.79:1, 9.41:1, main과 픽셀 동일 | 같음 |
| "Finish the current round first" | 10.94:1 본문 1줄 | 10.94:1 본문 1줄 |
| malang 방식(호출 뒤 글자 크기 22) | 11.01:1 본문 2줄 가운데 | 11.06:1 본문 2줄 |
| 긴 영어 문장 | 10.22:1 본문 2줄 | 11.69:1 본문 3줄 |
| "저장하지 못했습니다. 다시 시도해 주세요." | 10.09:1 본문 1줄 | 11.53:1 본문 2줄 |
| "Finish the round before replaying" | 10.79:1 본문 1줄 | 11.43:1 본문 2줄 |

390과 320의 막힌 이유 토스트와 테스트실 머리 줄(`rects-390x844.json`, `rects-320x568.json`):

| 항목 | 390x844 | 320x568 |
|---|---|---|
| 칩 | 51,24–339,55 | 16,24–304,55 |
| 제목 "Test room" 글자 | 44,61–142,89, 칩 아래 끝과 6px 간격, 겹침 없음 | 같음 |
| 닫기 버튼 | 290,47–346,103. 레이아웃은 칩과 49x8px 겹치지만 그림 기준으로는 버튼 위 테두리(y 49–52) 4px만 칩에 덮인다. 버튼 면(y 53부터)과 × 글자는 그대로다 | 220,47–276,103. 56x8px 겹침, 그림 기준 위 테두리 4px |
| 토스트 아래를 누름 | 칩과 버튼이 겹친 점(318,52)을 누르면 테스트실이 닫힌다 | (248,52) 누르면 닫힌다 |

## 4회차 지적 확인

| 지적 | 상태 | 근거 |
|---|---|---|
| R4-1 긴 토스트 글자가 갈색 칩 위에서 안 보임 | **해결** | `_fit_toast`가 변형을 지우지 않고 `label.get_theme_default_font()`로 글꼴만 덮어쓴다(`hud_layers.gd:60-62`). 390·320 `test-room-blocked` 글자 대비 1.2~1.3:1 → 10.95:1. 폭을 넘는 토스트 칩 6개(390), 10개(320)가 모두 #fff7df와 외곽선 4로 그려지고 9.88~11.69:1이다. 4회차 코드로 되돌리면 ui-kit probe가 실패해 같은 회귀를 잡는다 |
| R4-2 테스트실 버튼을 `find_child`로 찾음 | **해결** | id→버튼 사전(`test_room.gd:27`, `:212`, `:230`, `:241`). 이름이 겹치는 `a.b`/`a_b`, 와일드카드로 겹치는 `x*`/`x1`, `a?c`/`abc`, `w*?` 모두 자기 버튼만 무장하고 자기 행동만 1회 실행한다 |
| R4-3 설계 게이트 문장 | **해결** | 설계의 "노출 게이트" 문장과 인터페이스 `test_room(test_room_setup이 없거나 디버그·playtest 빌드가 아니면 null)`이 코드(`outgame_main.gd:302`)와 같다. 상태 그림 한 줄과 코드 주석 한 곳은 짧은 표현이 남았다(R5-4, 참고) |
| R3-3 390 막힌 행동 토스트가 제목과 닫기를 덮음 | 해결 유지 | 제목과 겹치지 않고 닫기는 위 테두리 4px만 닿는다(R5-1) |
| R2-1 320 막힌 행동 토스트 | **해결** | 칩이 화면 안(16–304)에 있고 글자가 읽힌다 |
| R2-2 한국어 음절 줄바꿈 | 범위 밖 | #26. 320에서 줄을 바꾼 한국어 토스트에도 같은 현상("시도 / 해 주세요.") |
| F-4 안전 영역, F-6 정사각 그림 구도, R2-3 렌더 probe 입력 무시, R2-4 롤 위 페이드 | 남음(참고) | 바뀌지 않음. R2-3은 이번에도 재현(R5-2) |

## 1.1.0 토스트 비교

같은 스크립트(`build/review-r5/toast_probe.gd`)를 후보와 main에 같은 렌더 크기로 돌렸다. 바탕은 단색(#6d8f6a)이고 칩마다 0.8초 뒤 찍었다.

| 구분 | 390x844 | 320x568 |
|---|---|---|
| main과 픽셀 동일 | 12개: 짧은 한 줄 4종, 명시적 `\n` 두 줄 2종(영어 "Could not save.\nTap again to retry." 246x59 왼쪽 정렬 포함), "A scene is already playing", "진행 중인 판을 먼저 끝내 주세요", we-moore 방식(호출 뒤 변형을 지우고 색을 준 칩), "Could not save. Try again.", "Not available right now", "지금은 할 수 없어요" | 8개: 짧은 한 줄 4종, 두 줄 2종, we-moore 방식, "지금은 할 수 없어요" |
| 다름(모두 숫자 글꼴의 가장 긴 줄이 화면 폭에서 양옆 16px를 뺀 칸을 넘는 칩) | 5개와 쌓인 둘째 칩: main은 칩이 x 0~13에서 시작해 화면 끝에 닿거나(최대 775px) 밖으로 나간다. 후보는 본문 글꼴로 한 줄에 들어가거나(288x31 등) 칩 폭 358로 줄을 바꿔 가운데 정렬한다 | 10개와 쌓인 둘째 칩: 같은 방식, 칩 폭 최대 288 |
| 쌓인 두 토스트 | "Saved" 칩은 main과 같고 둘째 칩만 다르다 | main은 넘치는 둘째 칩이 쌓기 칸을 넓혀 "Saved"가 x 135로 밀리고, 후보는 화면 가운데 x 113에 있다 |

"다름" 중 1.1.0에서도 화면 안에 있던 칩이 둘 있다. 390의 "Finish the current round first"(main 13–377)와 320의 "Not available right now"(main 15–304)다. 1.1.0에서는 양옆 13~15px 여백으로 읽혔지만 후보는 16px 여백 규칙에 따라 본문 글꼴로 바꾼다. 설계와 코드 주석의 규칙("양옆 16px 제외")대로이고 바뀐 칩도 읽히므로 결함으로 보지 않았다(참고).

## 소비 저장소 결과

starter-template-game `markets-v2`(`811a87b`, 기준 화면 1280x720, 잠금 1.1.0)의 복사본(`build/consumer/`)에 후보 묶음을 설치했다.

| 순서 | 소비 게임이 할 일 | 이번 실행 결과 |
|---|---|---|
| 1 | `rsync -a --exclude .git --exclude build --exclude .godot`, `git init`, 커밋 | 커밋 `4939256` |
| 2 | 후보의 `tools/bundle.py`, `tools/test_bundle.py`, `tools/validate_outgame.py` 복사 | 교체 |
| 3 | 후보에서 `bundle.py pack --commit 33dbf93…`, 복사본에서 `bundle.py --root . install --bundle ../consumer.tar.gz` | 둘 다 ok(1.2.0, 87 files). 복사본 `bundle.py verify` ok. 변경 53개 경로(`dev/`, `cutscene_player`, `tests/common/dev_probe.gd`, 그린 스킨 svg→png, `outgame_main`, `state`, `hud_layers` 등) |
| 4 | `outgame-profile.json`의 `uiStandard.version` 1.2.0 | 바꿈 |
| 5 | 복사본 `tools/check.py`에 `ui_kit_probe` 다음 줄로 `res://tests/common/dev_probe.gd -- --out <out>/dev.json`, `checks`에 `'dev_probe': True` | 더함, 커밋 `afc315e` |
| 결과 | `npm test` | **종료 0**: 단위 30개 OK, `check_native` ok, check.py 8개 시나리오 통과(headless 568x320), ui-kit 111/0, dev 26/0, ui-contract 87/0, `automated.json`의 `dev_probe: true`. 실행 뒤 추적 파일 변경 없음 |

## 발견 사항

차단 지적과 수정 권장 지적은 없다.

- R5-1 (참고, `godot/addons/seorilabs_game/ui_kit/hud_layers.gd`의 토스트 쌓기 위치와 `dev/test_room.gd`의 머리 줄 배치, 근거 `build/review-r5/rects-390x844.json`, `rects-320x568.json`, crop `build/review-r5/crops/blocked-top-390x844-x3.png`, `blocked-top-320x568-x4.png`): 본문 글꼴에 숫자 글자 크기를 그대로 쓰면서 칩 높이가 31px(y 24–55)가 되어, 390·320에서 막힌 이유 토스트가 테스트실 닫기 버튼의 그림 위 테두리 4px(y 49–52)에 2초 동안 얹힌다. × 글자와 누르는 면은 가려지지 않고, 겹친 점을 눌러도 닫기가 동작한다(토스트는 입력을 통과시킨다). 실패 시나리오: 기능 실패는 없다. 플레이테스터가 토스트가 떠 있는 2초 동안 닫기 버튼 윗선이 끊겨 보인다고 느낄 수 있다. 손볼 경우 Popup 층이 열려 있을 때 쌓기 시작 높이를 내리는 방법이 있지만, 1.1.0 토스트 위치를 바꾸므로 지금 고칠 필요는 낮다.
- R5-2 (참고, 검수 환경, R2-3과 같은 계열, 근거 `build/qa-r5-390x844-try1/navigation/journey.json`, `build/qa-r5-844x390-try1/scroll-boundary/journey.json`, `build/logs/capture-*-try1.log`, `build/logs/godot-monitor.log`): 렌더 check.py 6회 중 2회가 후보 변경과 무관한 부속 probe에서 실패했다. 390x844 1차는 `ui_navigation_probe`의 첫 탭이 무시된 뒤 180초 제한까지 멈췄고, 844x390 1차는 `e2e_scroll_probe`의 끌기와 탭이 무시됐다. 두 probe와 `e2e_driver.gd`는 main과 같고, `e2e_scroll_probe`는 후보 코드를 전혀 쓰지 않는다. 같은 명령의 2차 실행은 모두 통과했고 headless에서도 통과한다. 844x390 1차 실패 시간대에는 다른 Godot 프로세스가 없었으므로(감시 기록), 2회차 기록의 "다른 Godot 창" 설명만으로는 원인을 다 설명하지 못한다. 원인은 확인하지 못했다. 실패 시나리오: 다음 회차나 로컬 검수가 이 실패를 후보 회귀로 오인하거나, 반대로 실제 회귀를 "환경 탓"으로 다시 돌려 넘길 수 있다. 2회차 제안대로 드라이버가 실행 중 창 포커스 이탈을 기록해 그 실행을 무효로 표시하면 구분이 쉬워진다(범위 밖).
- R5-3 (참고, `godot/tests/common/dev_probe.gd:148-154`): 새 dev 항목 `blocked reason fits one line in the body font at 390`은 글꼴과 줄 수만 보므로 4회차 코드(변형 지우기)로 되돌려도 통과한다(순서 16). 같은 회귀는 ui-kit 항목이 잡으므로 지금 공백은 없다. dev 항목에도 글자색을 더하면 테스트실 쪽에서 직접 잡는다.
- R5-4 (참고, 문서): 설계 상태 그림의 `Settings --> TestRoom: 테스트실(디버그·playtest 빌드)`(`design.md:32`)와 `outgame_main.gd:46`의 주석 "디버그·playtest 빌드에서만 생기는 테스트실"은 `test_room_setup` 조건을 적지 않는다. 정본 문장(`design.md:90`)과 인터페이스 줄(`:82`), README, 게이트 바로 위 주석(`outgame_main.gd:299-300`)은 맞다.
- R5-5 (참고, `dev/test_room.gd:211`): 정리 뒤 이름이 겹치는 id의 둘째 버튼은 Godot 자동 이름(`@Button@8`)을 받는다. 테스트실 동작은 맞지만, 여정이나 제품 테스트가 노드 이름(`find_child("test_action_a_b")`)으로 버튼을 찾으면 첫 버튼을 잡는다. 제품이 정하는 개발용 id라 가능성은 낮다.
- 참고(설계 판단, 4회차와 같음): 같은 막힘 문구가 844·1280에서는 숫자 글꼴, 390·320에서는 본문 글꼴로 보인다. 또 1.1.0에서 양옆 13~15px 여백으로 화면 안에 있던 칩 2종이 16px 규칙으로 본문 글꼴이 된다(위 1.1.0 토스트 비교).
- 남은 참고: 엔딩 크레딧 롤 위 경계 페이드 없음(R2-4 롤 몫), F-4 안전 영역, F-6 정사각 그림 구도, R2-2 한국어 음절 줄바꿈(#26, 이번에 줄을 바꾼 한국어 토스트에서도 보임).

## 판정

pass. 4회차의 차단 지적 R4-1이 해결됐다. 긴 토스트가 `NumberLabel`의 밝은 글자색과 외곽선을 유지한 채 글꼴만 본문으로 바꿔, 390x844와 320x568의 막힌 이유 토스트 대비가 약 1.2~1.3:1에서 10.95:1이 됐고, 폭을 넘는 다른 토스트(엔딩 다시 보기 막힘, 저장 오류 영어·한국어, 호출 뒤 글자를 키우는 방식, 긴 문장)도 화면 안에서 9.88~11.69:1로 읽힌다. 화면 안에 드는 1.1.0 토스트(짧은 한 줄, 명시적 줄바꿈 두 줄, 호출 뒤 변형을 바꾸는 방식)는 main과 픽셀까지 같다. ui-kit probe는 4회차 코드로 되돌리면 실패해 같은 회귀를 잡는다. R4-2와 R4-3도 해결됐다.

4개 크기 렌더 check.py는 최종 실행이 모두 통과했다. 390x844와 844x390 1차 실패는 main과 같은 부속 probe의 입력 무시이고 재실행에서 통과했다(R5-2). 기준 1280x720 starter 복사본의 `npm test`도 dev 26/0, ui-kit 111/0으로 통과했다. 새 화면 64장은 모두 잘림 없이 읽힌다. 남은 지적은 모두 참고 등급이다.

AC-13 최종 판정: 390x844 pass, 320x568 pass, 844x390 pass, 1280x720 pass. 컷신, 크레딧, 테스트실(기본, 무장, 막힘, 한국어)이 네 크기 모두 잘리지 않고 글자가 읽힌다. 막힌 행동 토스트는 네 크기 모두 대비 10.95:1 이상이고 390·320에서 테스트실 제목을 덮지 않는다. 닫기 버튼은 위 테두리 4px만 닿고 × 글자와 누르는 면은 보이며 눌린다(R5-1). 한국어 음절 줄바꿈(R2-2, #26)은 글자를 가리거나 자르지 않아 AC-13 실패로 보지 않았다.

검수 캡처와 로그 원본은 이 worktree의 `build/` 아래에만 있다(`qa-r5-390x844`, `qa-r5-320x568`, `qa-r5-844x390`, `qa-r5-1280x720`, 1차 실패 출력 `qa-r5-390x844-try1`, `qa-r5-844x390-try1`, main 390x844 실행 사본 `main-run/qa-main-390x844`, `review-r5/`(보조 스크립트, 토스트 비교, 대비 측정, 사각형 측정, 묶음 보기, crop), `consumer/`(starter 복사본과 검사용 git), `consumer.tar.gz`, `logs/`). main 비교용 worktree와 감도 확인 사본은 지웠다. NAS1dual 이관은 PR 정리 단계에서 한다.

## 증적 보관

본문의 `build/` 경로는 검수용 임시 worktree였고 지웠다. 원본(캡처, 로그, 측정 결과)은 NAS1dual `agent-artifacts/game-foundation/2026-11-26/33dbf93b18a0bb40a3ac1a20570ca906a3e11111/cutscene-test-room-review-r5`에 옮겼고, 같은 폴더의 `MANIFEST.txt`가 파일별 크기와 SHA-256과 검증 완료를 적는다(2026-11-26). starter 복사본과 묶음 tar, export 패키지처럼 다시 만들 수 있는 파일은 옮기지 않았다.
