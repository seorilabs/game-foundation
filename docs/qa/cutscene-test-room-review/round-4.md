# 컷신 재생기, 크레딧, 테스트실 독립 검수 4회차

- 검수자: 독립 검수 에이전트 4 (구현자, 1~3회차 검수자와 다른 에이전트)
- 승인 근거: 2026-11-26 사용자 "4회차 진행"(3회차 fail 뒤 추가 회차 승인)
- 대상: seorilabs/game-foundation `cutscene-test-room`, 후보 SHA `14d8acca034a7d404b22356595f70c9962bc83f9`, 기준 main `e7e905df9aefe8f50f917ba103f6bcdcf240f60e`(fetch 뒤 origin/main, 후보의 merge-base와 같음)
- 3회차 이후 변경(`git log 1c73506..HEAD`): `18a9a24`(두 공용 probe가 390x844 루트를 정하기 전에 루트 배율을 끔, `tools/test_consumer_scale.py` 추가, `hud_layers.toast()`의 폭 판단을 호출 뒤로 미루고 가장 긴 줄로 판단, 줄바꿈 전에 본문 글꼴 시도, 줄바꿈할 때만 가운데 정렬, 테스트실의 null 반환 완료 처리와 id 정리, `test_room_setup`이 있을 때만 테스트실 연결, README), 잠금 갱신 `14d8acc`
- 크기: 390x844, 320x568, 844x390, 1280x720 (4개 모두 판정). 부속 probe는 도구 고정값(캠프 568x320 등). 소비 저장소는 starter 기준 크기 1280x720. 토스트 비교는 390x844, 320x568
- 실행 시각: 2026-11-26 12:00–12:26 UTC
- 실행 환경: dev headless 검증 + 렌더링 캡처. Godot 4.7.2.stable.official.ed1daf0bf(Compatibility), macOS 27.2.1, Python 3.14.7, Node 24.16.0. 격리 worktree `game-foundation.worktrees/review-r4`(detached `14d8acc`), 비교용 임시 worktree `review-r4-main`(detached `e7e905d`, 실행 뒤 삭제). 소비 저장소는 starter-template-game `markets-v2`(`811a87b`, 기준 화면 1280x720 `canvas_items`/`expand`, 잠금 1.1.0 `17984c9`)를 `build/consumer/`에 복사하고 그 안에 검사용 git 저장소를 만들었다. 깨끗한 checkout과 같게 하려고 복사본의 무시 대상 파일(`.import`, `.uid` 등 255개)을 복사본 안에서만 지웠다. 저장은 여정과 보조 스크립트의 격리 프로필만 썼고 실행 뒤 이번 실행이 만든 사용자 폴더 항목 36개를 지웠다
- 설계: `docs/design/2026-11-26-cutscene-test-room/design.md` AC-8~AC-14, "사용자 흐름·화면 상태", "품질 요구사항", "적용·운영·되돌리기" 2번. 상위 설계 agent-config `docs/design/2026-11-26-game-skill-system-v2/design.md` AC-8~AC-14. 테스트 계획 `test-plan.json` L3, dev, redesign, release null. 이전 기록 1~3회차(3회차 fail, R3-1~R3-5)

## 검수 계획

실행 전에 적은 계획이다. 이번 회차는 3회차 지적(R3-1~R3-5)의 해결 여부와, 토스트 변경이 1.1.0 토스트와 새 화면에 주는 영향을 중심으로 전체 회귀를 다시 본다.

| 순서 | 영역 | 내용 | 통과 기준 |
|---|---|---|---|
| 0 | 환경 | 렌더 실행 전마다 `pgrep -fl -i godot`로 다른 Godot 렌더 프로세스가 없는지 확인한다(MCP 서버는 제외). 있으면 기다렸다가 다시 확인하고 본 것을 기록한다 | 렌더 실행 시작 시 다른 Godot 렌더 프로세스 없음 |
| 1 | 기능 | `godot --headless --import`, `npm test`(새 `tools/test_consumer_scale.py` 포함), `python3 tools/bundle.py verify` | 종료 0, `test_consumer_scale`이 건너뛰지 않고 통과, verify ok |
| 2 | R3-1 소비 게임 | starter `markets-v2`를 `rsync -a --exclude .git --exclude build --exclude .godot`로 `build/consumer/`에 복사, `git init`과 커밋, 후보의 `tools/bundle.py`, `tools/test_bundle.py`, `tools/validate_outgame.py`를 복사, 후보에서 `bundle.py pack --commit <SHA>`, 복사본에 설치, `uiStandard.version` 1.2.0, 복사본 `tools/check.py`에 후보와 같은 방식의 `dev_probe` 명령과 `checks` 항목 추가, 커밋, `npm test` | 종료 0, 두 공용 probe(ui_kit, dev) 0 failed |
| 2a | R3-5 소비 게임 | starter는 `test_room_setup`을 주지 않으므로 설정에 "Test room"이 없어야 한다. 복사본 여정 결과나 보조 headless 스크립트로 설정 버튼 목록과 `test_room == null`을 확인한다 | "Test room" 없음, F9 무반응 |
| 3 | 렌더링 | `check.py --capture --size 390x844`, `320x568`, `844x390`, `1280x720`, 각각 `--out build/qa-r4-<크기>` | 4개 크기 종료 0 |
| 4 | 화면 | Read로 직접 본다: test-room, test-room-armed, test-room-blocked, test-room-ko, credits, credits-ko, prologue-1, ending-end, 토스트가 보이는 설정 화면. 나머지 새 화면(prologue-2, prologue-title, credits-end, settings-ending, ending-1, ending-count, ending-credits, prologue-1-ko)도 4개 크기에서 본다. R3-3: 390x844 test-room-blocked 토스트가 한 줄이고 제목과 닫기를 덮지 않는지 본다 | 새 화면 잘림 없음, 글자 읽힘, R3-3 해결 |
| 4a | 1.1.0 토스트 보존 | origin/main 임시 detached worktree에서 390x844 렌더 `check.py` 1회. 같은 캡처 중 토스트가 있는 화면을 후보와 픽셀 또는 칩 사각형으로 비교한다. 보조 스크립트(`build/` 아래)로 짧은 단일 줄 토스트, 명시적 `\n` 여러 줄 토스트, 호출 뒤 글꼴과 크기를 바꾸는 토스트를 후보와 main에서 찍어 비교한다. 비교 뒤 main worktree를 지운다 | 화면 안에 드는 토스트는 main과 같음 |
| 5 | R3-4 | `build/` 아래 일회용 스크립트: 반환값 없는 행동 → 결과 줄 "Done", "Not available right now" 토스트 없음. id에 `.`가 든 두 번 누름 행동과 시점 프리셋 → 무장 뒤 적용 | 설계대로 동작, ERROR 없음 |
| 6 | 판정 | 3회차 지적별 해결 여부, 새 발견 사항을 실패 시나리오와 함께 적는다 | |

실행 중 계획에 더한 것: 4번에서 390x844 막힌 행동 토스트의 글자가 어두운 칩 위에서 거의 보이지 않아, 토스트 비교(4a)에 바뀐 맞춤 경로를 타는 호출 3개(`outgame_main`이 새로 띄우는 "A scene is already playing", 저장 오류 문구 영어·한국어)를 더하고 캡처 픽셀로 대비를 쟀다. `test_consumer_scale.py`가 실제 회귀를 잡는지 보려고, 후보 프로젝트 사본에서 두 probe의 배율 끄기 줄만 지우고 같은 `override.cfg`(1280x720)로 probe를 돌렸다.

## 실행 명령과 결과

모든 명령은 격리 worktree 루트에서 실행했다. 렌더 실행 기록은 `build/logs/runs.log`, 명령별 출력은 `build/logs/<이름>.log`에 있다.

| 순서 | 명령 | 결과 |
|---|---|---|
| 0 | `pgrep -fl -i godot` (12:02:03, 이후 렌더 실행마다 `build/review-r4/render_runs.sh`가 확인) | Godot 실행 파일 프로세스 0개. 잡힌 것은 godot-mcp 서버(npm exec와 node 4쌍)뿐이다. 렌더 실행 10회 모두 시작 시 다른 렌더 프로세스가 없었고 대기는 0회였다 |
| 1 | `godot --headless --path godot --import --quit-after 2` | 종료 0 (12:02:08–12:02:52), ERROR 0 |
| 2 | `npm test` | 종료 0 (12:02:56–12:11:38). 단위 테스트 35개 OK(건너뜀 0, `test_shared_probes_pass_with_1280x720_base_size` ok), check.py `{"ok": true, "scenarios": 14}`. headless ui-kit 111/0, dev 21/0, ui-contract 87/0 |
| 3 | `python3 tools/bundle.py verify` | ok, version 1.2.0, files 87, source commit `18a9a24…`(잠금이 가리키는 직전 커밋) |
| 4 | 소비 복사본 준비: rsync 복사, `git init`, 커밋, 무시 대상 파일 정리 | 커밋 `01c0b77`(starter `811a87b` 복사본) |
| 5 | 후보 `bundle.py pack --commit 14d8acc… --out build/consumer.tar.gz`, 복사본에 도구 3개 복사, 복사본 `bundle.py --root . install --bundle ../consumer.tar.gz` | 둘 다 ok(1.2.0, 87 files). 복사본 `bundle.py verify` ok. 변경 53개 경로 |
| 6 | 복사본 `uiStandard.version` 1.2.0, `tools/check.py`에 `dev_probe` 명령(`ui_kit_probe` 다음 줄, `--out <out>/dev.json`)과 `checks`의 `'dev_probe': True`, 커밋 | 커밋 `069f2ea` |
| 7 | 복사본 `npm test` | **종료 0** (12:11:53–12:14:08). 단위 30개 OK, `check_native` ok, check.py `{"ok": true, "scenarios": 8}`. 공용 ui-kit 111/0, dev 21/0, ui-contract 87/0, `automated.json`의 `dev_probe: true` |
| 8 | 보조 `build/review-r4/consumer_r35.gd`(복사본, headless) | 종료 0. 9단계 통과(아래 R3-5) |
| 9 | 보조 `build/review-r4/r34_probe.gd`(후보, headless) | 종료 0, 11개 항목 통과, ERROR 0. 결과 `build/review-r4/r34.json` |
| 10 | `check.py --capture --size 390x844 --out build/qa-r4-390x844` | 종료 0 (12:14:57–12:15:54), 14개 시나리오 |
| 11 | `check.py --capture --size 320x568 --out build/qa-r4-320x568` | 종료 0 (12:15:54–12:16:56), 14개 시나리오 |
| 12 | `check.py --capture --size 844x390 --out build/qa-r4-844x390` | 종료 0 (12:16:56–12:18:30), 14개 시나리오 |
| 13 | `check.py --capture --size 1280x720 --out build/qa-r4-1280x720` | 종료 0 (12:18:30–12:20:12), 14개 시나리오 |
| 14 | origin/main `e7e905d` 임시 worktree에서 `check.py --capture --size 390x844` | 종료 0 (12:20:12–12:21:09), 10개 시나리오. 캡처 사본 `build/main-run/qa-main-390x844/` |
| 15 | 보조 `build/review-r4/toast_cmp.gd`(토스트 15종), 후보와 main, 390x844와 320x568 렌더 | 4회 모두 종료 0 (12:21:10–12:22:00). 결과 `build/review-r4/toast-<cand|main>-<크기>/` |
| 16 | 보조 `consumer_r35.gd` 렌더 1280x720 | 종료 0 (12:22:01–12:22:05). 캡처 `build/review-r4/consumer-r35-1280x720/settings-end.png` |
| 17 | 감도 확인: 후보 `godot/` 사본(`build/review-r4/sens/`)에 1280x720 `override.cfg`를 넣고 두 probe의 `root.content_scale_mode = …DISABLED` 줄만 지운 뒤 probe 실행 | ui-kit 111 checks 6 failed, dev 21 checks 10 failed(3회차 R3-1과 같은 수). 수정 줄이 있으면 통과하고 없으면 실패하므로 `test_consumer_scale.py`가 회귀를 잡는다 |
| 18 | `python3 -m unittest tools/test_consumer_scale.py` 단독 | 종료 0, 10.6초 |

## 기능 결과

| 항목 | 결과 | 근거 |
|---|---|---|
| 여정 | 14/14 passed, 4개 크기 모두 | 단계 수 221(1280x720은 가로 검사가 더해져 222). 3회차와 같다 |
| ui-kit probe | 111 checks, 0 failed, 4개 크기와 headless 모두 | 3회차 109 + `layers: long toast switches to the body font before wrapping`, `layers: fitting multi-line toast keeps the 1.1.0 look` |
| dev probe | 21 checks, 0 failed | 4개 크기 모두 |
| ui-contract probe | 87 checks, 0 failed | 4개 크기 모두 |
| 부속 probe | camp 2/2, navigation 3/3, scroll-boundary 1/1 | 4개 크기 모두 |
| main과 바뀌지 않은 화면 비교(390x844) | 차이는 설명 가능 | 공통 캡처 45장 중 21장이 픽셀 동일하다. 나머지 24장은 설정 목록에 "Credits", "Test room"이 더해진 화면(`settings-ko`, 스크롤 막대만 다른 `camp-settings`, `keyboard-support-focus`, `native-after-late-callback`)과 전환 중간 프레임(순위, 팝업, 오퍼, 보상 등)이다. 같은 계열 코드인 3회차 후보 캡처와 이번 캡처를 비교해도 `popup-open` 241,771픽셀, `offer` 71,411픽셀이 달라 전환 프레임의 흔들림으로 본다. `settings-ko`, `test-room`, `test-room-armed`는 3회차 후보와 픽셀 동일하고 `test-room-blocked`는 토스트 영역(16,24)–(374,83)만 다르다. 두 실행의 바뀌지 않은 화면에는 토스트가 없다 |
| 화면 안에 드는 토스트 | main과 픽셀 동일 | 아래 토스트 비교의 9종(390), 6종(320) |
| 화면 폭을 넘는 토스트 | 화면 안에 들어오지만 **글자가 보이지 않음** | 아래 R4-1 |
| 묶음·export | pass | `bundle.py verify` ok, `test_export_presets` 통과(단위 35개에 포함) |

토스트 비교(`build/review-r4/toast-*/toast.json`, 묶음 보기 `build/review-r4/crops/toast-cand-vs-main.png`). 칩은 [x, y, 폭, 높이] 픽셀, 글자는 라벨 변형과 글자색이다.

| 호출 | 390x844 후보 | 390x844 main | 320x568 후보 | 320x568 main |
|---|---|---|---|---|
| "Saved", "+10 coins", "12,800", "저장했어요" | main과 픽셀 동일 | 숫자 글꼴, #fff7df | main과 픽셀 동일 | 같음 |
| "Could not save.\nTap again to retry." 등 my-little-parasite 두 줄 3종 | main과 픽셀 동일(왼쪽 정렬, 246x59 등) | 같음 | main과 픽셀 동일 | 같음 |
| we-moore 방식(호출 뒤 본문 글꼴과 밝은 색) "Finish the current round first" | main과 픽셀 동일(261x28) | 같음 | main과 픽셀 동일 | 같음 |
| "진행 중인 판을 먼저 끝내 주세요" | main과 픽셀 동일(297x30) | 같음 | [33,24,254,28] 본문, **#244e5c** | [11,24,297,30] 숫자 |
| "A scene is already playing"(`outgame_main`의 엔딩 다시 보기 막힘) | main과 픽셀 동일(321x30) | 같음 | [42,24,236,28] 본문, **#244e5c** | [0,24,321,30] 숫자 |
| "Finish the current round first"(테스트실 막힘) | [64,24,261,28] 본문, **#244e5c** | [13,24,364,30] 숫자 | [29,24,261,28] 본문, **#244e5c** | [0,24,364,30] 숫자, 화면 밖으로 나감 |
| malang 방식(호출 뒤 글자 크기 22) "Could not save. Check storage space" | [16,24,358,73] 두 줄 가운데, 본문, **#244e5c** | [0,24,502,35] 화면 밖 | [16,24,288,73] 같은 모양 | 화면 밖 |
| 긴 문장, 저장 오류 문구(영어·한국어) | 358 폭 두 줄 또는 한 줄, 본문, **#244e5c** | 화면 밖 | 288 폭 두~세 줄, 본문, **#244e5c** | 화면 밖 |

| AC | 결과 | 근거 |
|---|---|---|
| AC-8 | pass | ui-kit 컷신 항목 motion·reduced 통과. 이번에는 기준 크기 1280x720 소비 복사본과 `test_consumer_scale`에서도 통과(R3-1 해결) |
| AC-9 | pass | `map-prologue-first-start-once` 16단계, 기존 10개 시나리오 통과 |
| AC-10 | pass | `settings-credits-and-ending-replay` 21단계 통과, 크레딧 캡처 4개 크기 |
| AC-11 | pass | dev 21항목, `debug-test-room` 20단계 통과. 막힌 행동은 토스트를 띄우고 저장을 바꾸지 않는다(기능 기준). 토스트 글자가 읽히는지는 AC-13에서 본다 |
| AC-12(기반 몫) | pass | `test_export_presets` 통과. 이번 변경은 preset을 건드리지 않았다 |
| AC-13 | **fail(390x844, 320x568의 test-room-blocked)** | 아래 화면 판정과 R4-1 |
| AC-14(기반 몫) | pass | `test_bundle`, `test_ui_contract` 통과, `bundle.py verify` ok. 상위 AC-14의 starter 설치도 이번에는 `npm test`까지 통과 |

R3-4 보조 결과(`build/review-r4/r34.json`, 버튼은 dev_probe와 같은 방식으로 390x844 창에 마우스 이벤트를 넣어 눌렀다):

| 경우 | 결과 | 판정 |
|---|---|---|
| 반환값 없는 행동(`func() -> void`) | 1회 실행, 결과 줄 "Done", 토스트 없음 | 해결 |
| id `reset.coins`의 두 번 누름 행동 | 버튼 이름 `test_action_reset_coins`. 첫 탭 "Tap again to apply"로 무장, 실행 0회, 저장 바이트 동일. 둘째 탭 1회 실행, 결과 줄 "Dot reset done", 원래 이름으로 돌아옴 | 해결 |
| id `day.1`, `day.2` 시점 프리셋 | 첫 탭 무장만, 다른 프리셋 탭으로 첫 무장 해제와 새 무장, 둘째 탭 `day.2` 적용(코인 2000), 새 두 번 탭 `day.1` 적용(코인 1000) | 해결 |
| 참고: 정리 뒤 이름이 겹치는 id(`a.b`와 `a_b`) | 둘째 버튼은 Godot가 자동 이름을 붙여 `test_action_a_b`가 하나만 남는다. `a_b`를 두 번 누르면 `a_b` 행동이 1회 실행되고 `a.b`는 실행되지 않는다. 다만 첫 탭의 "Tap again to apply" 표시는 `find_child`가 먼저 찾은 `a.b` 버튼에 붙는다(코드로 확인) | 참고(R4-2) |

## 화면 판정

캡처 위치: `build/qa-r4-390x844/`, `build/qa-r4-320x568/`, `build/qa-r4-844x390/`, `build/qa-r4-1280x720/`. 묶음 보기 `build/review-r4/sheets/`(`p320-1..4`, `p390-1..2`, `l844-1..4`, `l1280-1..4`, 1280은 0.6배), 확대 crop `build/review-r4/crops/`. 390x844의 test-room, test-room-armed, test-room-blocked, test-room-ko, credits, credits-ko, prologue-1, ending-end와 1280x720 test-room-blocked는 원본 크기로 봤다.

설정 화면의 토스트: 레퍼런스 여정에서 토스트가 보이는 캡처는 test-room-blocked 하나다. main의 `outgame_main`에는 `layers.toast` 호출이 없고, 후보가 새로 더한 설정 쪽 토스트(엔딩 다시 보기 막힘, 프롤로그 뒤 저장 실패)는 여정 캡처에 없다. 그래서 설정 화면 토스트는 캡처 대신 위 토스트 비교의 "A scene is already playing"과 저장 오류 문구로 판정했다.

| 캡처 | 390x844 | 320x568 | 844x390 | 1280x720 | 근거 |
|---|---|---|---|---|---|
| prologue-1 | pass | pass | pass | pass | 흰 자막과 외곽선이 어두운 아래 띠에서 읽힌다. 세로 두 줄, 가로 한 줄. 스킵은 오른쪽 위 |
| prologue-2 | pass | pass | pass | pass | 밝은 양피지 위에서도 외곽선으로 읽힌다 |
| prologue-title | pass | pass | pass | pass | "SKY ATLAS"와 부제가 잘리지 않는다 |
| credits | pass | pass | pass | pass | 3회차와 같다. 글꼴 묶음 사이 간격이 이름과 저작권 줄 사이보다 넓다. 1280은 640px 가운데 칸 |
| credits-end | pass | pass | pass | pass | 마지막 "SIL Open Font License 1.1"까지 보인다 |
| settings-ending | pass | pass | pass | pass | "Replay ending", "Credits", "Test room"이 기존 설정 버튼과 같은 판으로 목록 끝에 있다 |
| ending-1 | pass | pass | pass | pass | 390에서 등대가 화면 밖(F-6, 그림 구도, 참고) |
| ending-count | pass | pass | pass | pass | "12,800"이 외곽선으로 읽힌다 |
| ending-credits | pass | pass | pass | pass | 롤 위 경계 페이드 없음은 그대로(R2-4 롤 몫, 참고) |
| ending-end | pass | pass | pass | pass | 금색 "Continue"가 가운데에 있다 |
| test-room | pass | pass | pass | pass | 3회차 후보와 픽셀 동일(390). 320·390 2열, 844·1280 3열 |
| test-room-armed | pass | pass | pass | pass | 무장한 버튼만 금색 "Tap again to apply", 결과 줄 "Coins 0 → 100" |
| test-room-blocked | **fail** | **fail** | pass | pass | 390·320: 토스트가 한 줄(칩 261x28, y 24–52)이 되어 "Test room" 제목과 닫기 버튼을 덮지 않는다(R3-3의 배치 몫 해결). 그러나 글자가 어두운 청록 #244e5c, 외곽선 0으로 갈색 칩 위에 그려져 거의 보이지 않는다. 캡처에서 잰 대비는 약 1.2~1.3:1이다(같은 칩에 1.1.0 글자색 #fff7df는 약 10.5~11.2:1). 막힌 이유를 알리는 유일한 피드백이 읽히지 않는다(R4-1). 844·1280: 숫자 글꼴 #fff7df 한 줄로 프레임 위 띠 안에서 읽힌다 |
| prologue-1-ko | pass | pass | pass | pass | "건너뛰기"가 버튼 안 한 줄 |
| test-room-ko | pass | pass | pass | pass | 글자는 모두 보인다. 320 "코인 100 추 / 가", 390 "적용해 / 요."처럼 음절 단위 줄바꿈은 그대로(R2-2, #26, 범위 밖) |
| credits-ko | pass | pass | pass | pass | 320 "만들었습니 / 다"(R2-2, 범위 밖) |

## 3회차 지적 확인

| 지적 | 상태 | 근거 |
|---|---|---|
| R3-1 공용 probe가 기준 1280x720 소비 게임에서 실패 | **해결** | starter 복사본(기준 1280x720) `npm test` 종료 0, ui-kit 111/0, dev 21/0. `test_consumer_scale.py`가 후보에서 통과하고, 수정 줄을 지운 사본에서는 3회차와 같은 6건, 10건으로 실패해 회귀를 잡는다 |
| R3-2 여러 줄과 호출 뒤 수정 토스트의 모양 변화 | **해결** | 화면 안에 드는 여러 줄 토스트(my-little-parasite 3종)와 we-moore 방식은 main과 픽셀 동일. malang 방식은 호출 뒤 바뀐 글자 크기로 판단한다(지연 판단 동작 확인). 다만 폭을 넘는 경로의 글자색 문제는 새 지적 R4-1 |
| R3-3 390x844 막힌 행동 토스트가 제목과 닫기를 덮음 | **배치는 해결, 새 결함 생김** | 390에서 한 줄 261x28이 되어 제목과 닫기를 덮지 않는다. 같은 수정(본문 글꼴로 바꾸기)이 글자색까지 본문 색으로 바꿔 글자가 보이지 않게 됐다(R4-1) |
| R3-4 테스트실 API 오용의 조용한 실패 | **해결** | 반환값 없는 행동은 "Done", 점이 든 id의 두 번 누름 행동과 시점 프리셋이 무장 뒤 적용된다. 정리 뒤 이름이 겹치는 id는 참고(R4-2) |
| R3-5 `test_room_setup` 없이도 테스트실이 붙음, 정할 시점 미기재 | **해결** | starter 복사본(디버그 실행)에서 `test_room_setup` 무효, `test_room == null`, 테스트실 노드 없음, 설정 버튼은 "Credits"로 끝나고 "Test room" 없음, F9 무반응(렌더 캡처 `consumer-r35-1280x720/settings-end.png`). README가 bootstrap `_init()`에서 정하라고 적는다. 레퍼런스는 `_init()`에서 정해 `debug-test-room`이 통과한다 |
| R2-1 320 막힌 행동 토스트 | **다시 남음** | 칩은 화면 안(x 29–290)에 들지만 글자가 읽히지 않아 "모두 보인다"는 목표를 채우지 못한다(R4-1) |
| R2-2 한국어 음절 줄바꿈 | 범위 밖 | 이슈 seorilabs/game-foundation#26 |
| F-4 안전 영역, F-6 정사각 그림 구도, R2-3 navigation probe 정지, R2-4 롤 위 페이드 | 남음(참고) | 바뀌지 않음 |

## 소비 저장소 설치 결과

starter-template-game `markets-v2`(`811a87b`, 기준 화면 1280x720, 잠금 1.1.0 `17984c9`)의 복사본에 후보 묶음을 설치했다.

| 순서 | 소비 게임이 할 일 | 이번 실행 결과 |
|---|---|---|
| 1 | `tools/bundle.py`, `tools/test_bundle.py`, `tools/validate_outgame.py`를 후보 사본으로 바꾼다 | 교체 |
| 2 | foundation에서 `bundle.py pack --commit <SHA>`, starter에서 `bundle.py --root <starter> install --bundle <tar>` | ok, 53개 경로 변경(`dev/` 2개, `cutscene_player` 2개, `tests/common/dev_probe.gd`, 그린 스킨 svg→png 15쌍, `outgame_main`, `state`, `hud_layers` 등, 플랫폼 SDK 1.1.1, 잠금) |
| 3 | 새 파일을 git에 추가한다 | 추가 후 커밋. `test_fresh_start` 통과 |
| 4 | `outgame-profile.json`의 `uiStandard.version`을 `1.2.0`으로 | 바꾼 뒤 `test_evidence` 통과 |
| 5 | `tools/check.py`에 `res://tests/common/dev_probe.gd -- --out <out>/dev.json` 명령과 `checks`의 `dev_probe` | 더함 |
| 6 | 출시 preset `exclude_filter`, 웹 플레이테스트 preset `playtest` | `markets-v2`에 이미 있다(관련 단위 테스트 통과) |
| 결과 | `npm test` | **종료 0**: 단위 30개 OK, `check_native` ok, check.py 8개 시나리오 통과, ui-kit 111/0, dev 21/0, ui-contract 87/0 |

starter는 `test_room_setup`을 주지 않으므로 디버그 실행에서도 테스트실과 설정 항목이 생기지 않는다(R3-5). starter 자체 코드는 `layers.toast`를 부르지 않는다. 다만 1.2.0의 `outgame_main`이 띄우는 토스트(엔딩 다시 보기 막힘, 프롤로그 뒤 저장 실패)는 starter 화면에서도 R4-1 경로를 탈 수 있다(starter는 지금 프롤로그와 엔딩이 없어 실제로 뜨지 않는다).

## 발견 사항

- R4-1 (**차단**, 공용 `godot/addons/seorilabs_game/ui_kit/hud_layers.gd:51-65`의 `_fit_toast`(변형을 지우는 줄 `:60`), 근거 `build/qa-r4-390x844/test-room-blocked.png`, `build/qa-r4-320x568/test-room-blocked.png`, crop `build/review-r4/crops/blocked-390-top-x4.png`, `blocked-320-top-x4.png`, `toast-cand-vs-main.png`, 측정 `build/review-r4/toast-cand-*/toast.json`): 폭을 넘는 토스트를 본문 글꼴로 바꾸려고 `label.theme_type_variation = &""`로 지우는데, 이 변형이 글꼴만이 아니라 `NumberLabel`의 밝은 글자색(#fff7df)과 외곽선(4)까지 함께 정하고 있었다. 변형을 지우면 기본 `Label`의 글자색 #244e5c(어두운 청록, `theme_builder.gd:93`의 `text`)와 외곽선 0이 적용되어, 어두운 갈색 칩(평균 약 #502E1D) 위 대비가 약 1.2~1.3:1로 떨어진다. 같은 칩에서 1.1.0 글자색은 약 10.5~11.2:1이다. 칩 폭과 줄 수를 보는 probe 항목(`long toast wraps inside the screen`, `long toast switches to the body font before wrapping`)은 색을 보지 않아 통과한다. 실패 시나리오: (1) 레퍼런스와 1.2.0을 쓰는 게임에서 390x844와 320x568 폭의 플레이테스터가 판 진행 중 테스트실 행동을 누르면 "Finish the current round first" 대신 빈 갈색 띠가 2초 보였다 사라진다. 저장은 바뀌지 않고 결과 줄도 그대로라 버튼이 고장 난 것으로 보인다. (2) 320 폭에서 설정의 "엔딩 다시 보기"가 막히면 "A scene is already playing"이, 프롤로그 뒤 저장이 실패하면 저장 오류 문구가 같은 방식으로 보이지 않는다(한국어 "저장하지 못했습니다. 다시 시도해 주세요."는 390에서도). (3) malang처럼 호출 뒤 글자 크기를 키우는 소비 게임이 1.2.0으로 올리면, 1.1.0에서 양옆이 잘려도 가운데는 읽히던 긴 알림이 화면 안에 들어오지만 전부 읽히지 않게 된다. 제안: 변형을 지우지 말고 `NumberLabel`의 색과 외곽선을 유지한 채 글꼴만 바꾼다(예: `label.add_theme_font_override("font", label.get_theme_font("font", &"Label"))`와 같은 방식의 글자 크기). 또는 밝은 글자색을 가진 토스트 전용 변형을 테마에 둔다. "이미 본문 글꼴인가"는 변형 이름 대신 글꼴 덮어쓰기 여부로 판단해야 we-moore처럼 호출 뒤 변형을 지운 경우와 겹치지 않는다. 재발 방지로 ui-kit probe의 긴 토스트 항목에 글자색(또는 칩 대비 4.5:1 이상)을 확인하는 항목을 더하기를 권한다. 고친 뒤 확인할 것: test-room-blocked 4개 크기 캡처, 토스트 비교 15종(화면 안에 드는 토스트가 main과 계속 픽셀 동일한지 포함), `npm test`.
- R4-2 (참고, `godot/addons/seorilabs_game/dev/test_room.gd:226`, `:237`, 근거 `build/review-r4/r34.json`의 notes): id를 노드 이름으로 정리한 뒤 겹치면(`a.b`와 `a_b`) 둘째 버튼은 Godot 자동 이름을 받고, `find_child`가 첫 버튼을 찾아 둘째 버튼을 눌러도 무장 표시("Tap again to apply")가 첫 버튼에 뜬다. 실행되는 행동은 맞다(둘째 탭에 `a_b`만 1회). 또 `find_child`는 `*`, `?`를 와일드카드로 해석하므로 그런 글자가 든 id도 다른 버튼을 잡을 수 있다. 제품이 정하는 개발용 id라 실제로 일어날 가능성은 낮다. 고친다면 무장 상태를 버튼 참조로 들고 있으면 이름 규칙과 무관해진다.
- R4-3 (참고, 문서): 설계 `design.md`의 "노출 게이트" 문장과 인터페이스의 `test_room(디버그·playtest 빌드가 아니면 null)`이 이번에 더해진 조건(`test_room_setup`이 있어야 붙음)을 적지 않는다. README와 코드 주석은 맞다. 설계 문서도 같은 조건으로 맞추기를 권한다.
- 참고(설계 판단): 같은 막힘 문구가 844·1280에서는 숫자용 고정폭 글꼴, 390·320에서는 본문 글꼴로 보인다. 1.1.0 모양을 지키려는 선택의 결과라 결함으로 보지 않았다. R4-1을 고칠 때 문장 토스트의 글꼴을 크기와 무관하게 정하는 방안(3회차 R3-3 제안)도 함께 검토할 수 있다.
- 남은 참고: 엔딩 크레딧 롤 위 경계 페이드 없음(R2-4 롤 몫), F-4 안전 영역, F-6 정사각 그림 구도, R2-2 한국어 음절 줄바꿈(#26), R2-3 navigation probe 정지.

## 판정

fail. 3회차의 차단 지적 R3-1은 해결됐다. 기준 크기 1280x720인 starter 복사본에 후보 묶음을 설치하고 `dev_probe`를 더한 `npm test`가 종료 0으로 통과했고(ui-kit 111/0, dev 21/0, 여정 8개), 새 `test_consumer_scale.py`는 수정 줄을 지우면 같은 실패를 재현해 회귀를 잡는다. R3-2, R3-4, R3-5도 해결됐다. 화면 안에 드는 1.1.0 토스트(짧은 한 줄, 명시적 줄바꿈 두 줄, 호출 뒤 글꼴을 바꾸는 방식)는 main과 픽셀까지 같다. 4개 크기 렌더 check.py가 모두 한 번에 통과했고 새 화면 64장 중 62장이 잘림 없이 읽힌다.

차단 판정의 근거는 R4-1 하나다. R3-3을 고치려고 넣은 "본문 글꼴로 바꾸기"가 토스트 글자색을 칩과 거의 같은 어두운 색으로 바꿔, 레퍼런스 기준 크기 390x844와 320x568에서 테스트실의 막힌 이유 토스트가 읽히지 않는다. 이 경로는 공용 `hud_layers.toast()`에 있어 폭을 넘는 모든 토스트(설정의 엔딩 다시 보기 막힘, 저장 오류, 소비 게임의 긴 알림)에 같은 문제가 생긴다. 수정 범위는 `_fit_toast`의 글꼴 교체 방식 한 곳이다. 고친 뒤 다음 회차가 확인할 것은 test-room-blocked 4개 크기 캡처의 글자 대비, 토스트 비교(화면 안에 드는 토스트의 main 픽셀 동일 유지, 폭을 넘는 토스트의 글자색), `npm test`다. 소비 복사본 확인은 토스트 변경이 probe 결과를 바꾸지 않는 한 이번 결과를 쓸 수 있다.

AC-13 최종 판정: 390x844 fail, 320x568 fail, 844x390 pass, 1280x720 pass. 컷신과 크레딧은 네 크기 모두 pass다. 테스트실은 기본, 무장, 한국어 화면이 네 크기 모두 pass이지만, 막힌 행동 상태(test-room-blocked)에서 390x844와 320x568의 토스트 글자가 읽히지 않는다(대비 약 1.2~1.3:1, R4-1). 한국어 음절 줄바꿈(R2-2, #26)은 글자를 가리거나 자르지 않아 AC-13 실패로 보지 않았다.

검수 캡처와 로그 원본은 이 worktree의 `build/` 아래에만 있다(`qa-r4-390x844`, `qa-r4-320x568`, `qa-r4-844x390`, `qa-r4-1280x720`, `main-run/qa-main-390x844`(main 390x844 실행 사본), `review-r4/`(보조 스크립트, 토스트 비교, 묶음 보기, crop, 소비 R3-5 결과, 감도 확인 사본), `consumer/`(starter 복사본과 검사용 git), `consumer.tar.gz`, `logs/`). main 비교용 worktree는 삭제했다. 이번 실행이 Godot 사용자 폴더에 만든 격리 저장 항목(레퍼런스 30개, starter 6개)을 지웠다. NAS1dual 이관은 PR 정리 단계에서 한다.

## 증적 보관

본문의 `build/` 경로는 검수용 임시 worktree였고 지웠다. 원본(캡처, 로그, 측정 결과)은 NAS1dual `agent-artifacts/game-foundation/2026-11-26/14d8acca034a7d404b22356595f70c9962bc83f9/cutscene-test-room-review-r4`에 옮겼고, 같은 폴더의 `MANIFEST.txt`가 파일별 크기와 SHA-256과 검증 완료를 적는다(2026-11-26). starter 복사본과 묶음 tar, export 패키지처럼 다시 만들 수 있는 파일은 옮기지 않았다.
