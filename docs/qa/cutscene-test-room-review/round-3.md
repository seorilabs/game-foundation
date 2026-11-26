# 컷신 재생기, 크레딧, 테스트실 독립 검수 3회차

- 검수자: 독립 검수 에이전트 3 (구현자, 1회차·2회차 검수자와 다른 에이전트)
- 대상: seorilabs/game-foundation `cutscene-test-room`, 후보 SHA `1c73506b334011fb898691fbc1cdf66565b7e2fd`, 기준 main `e7e905df9aefe8f50f917ba103f6bcdcf240f60e`(fetch 뒤 origin/main, 후보의 merge-base와 같음)
- 2회차 이후 변경(`git log c6da5af..HEAD`): `d07944a`(공용 `ui_kit/hud_layers.gd`의 `toast()`가 화면 폭 − 양옆 16px보다 긴 문장을 줄바꿈, 설정 크레딧의 글꼴 묶음 사이 간격, `ui_kit_probe` 긴 토스트 항목), 잠금 갱신 `1c73506`
- 크기: 390x844, 320x568, 844x390, 1280x720 (4개 모두 판정). 부속 probe는 도구 고정값(캠프 568x320 등). 소비 저장소 확인은 starter 기준 크기 1280x720
- 실행 시각: 2026-11-26 11:26–11:47 UTC
- 실행 환경: dev headless 검증 + 렌더링 캡처. Godot 4.7.2.stable.official.ed1daf0bf(Compatibility), macOS 27.2.1, Python 3.14.7, Node 24.16.0. 격리 worktree `game-foundation.worktrees/review-r3`(detached `1c73506`), 비교용 임시 worktree `review-r3-main`(detached `e7e905d`, 실행 뒤 삭제). 소비 저장소는 starter-template-game `markets-v2`(`811a87b`)를 `build/consumer/`에 rsync로 복사하고 그 안에 검사용 임시 git 저장소를 만들어 썼다(`check.py`와 `test_fresh_start.py`가 `git ls-files`를 쓰기 때문). 저장은 여정과 보조 스크립트의 격리 프로필만 썼고 실행 뒤 이번 실행이 만든 사용자 폴더 항목을 지웠다
- 설계: `docs/design/2026-11-26-cutscene-test-room/design.md` AC-8~AC-14, "사용자 흐름·화면 상태", "품질 요구사항", "적용·운영·되돌리기" 2번(소비 게임). 상위 설계 agent-config `docs/design/2026-11-26-game-skill-system-v2/design.md`(AC-14의 starter 설치 포함). 테스트 계획 L3·dev·redesign·release null

## 검수 계획

실행 전에 적은 계획이다. 이번 회차는 최종 후보의 전체 회귀와 소비 게임이 겪을 위험에 집중한다.

| 순서 | 영역 | 내용 | 통과 기준 |
|---|---|---|---|
| 0 | 환경 | 렌더 실행 전마다 `pgrep -fl -i godot`로 다른 Godot 렌더 프로세스가 없는지 확인한다(godot-mcp 서버는 제외). 있으면 기다렸다가 다시 확인하고 본 것을 기록한다 | 렌더 실행 시작 시 다른 Godot 렌더 프로세스 없음 |
| 1 | 기능 | `npm test`, `python3 tools/bundle.py verify` | 종료 0, verify ok |
| 2 | 렌더링 | `check.py --capture --size 390x844`, `320x568`, `844x390`, `1280x720`, 각각 `--out build/qa-r3-<크기>`. 기존 단계에서 실패하면 다른 Godot 프로세스가 없는 상태에서 한 번 더 돌리고 두 결과를 모두 적는다 | 4개 크기 종료 0 |
| 3 | 화면 | 새 화면 캡처 16종(prologue-1/2/title, credits, credits-end, settings-ending, ending-1, ending-count, ending-credits, ending-end, test-room, test-room-armed, test-room-blocked, prologue-1-ko, test-room-ko, credits-ko)을 4개 크기에서 Read로 직접 본다. R2-1(320x568 영어 막힌 행동 토스트가 줄바꿈되어 모두 보임)과 R2-4(크레딧 글꼴 묶음 간격)를 확인한다 | 64장 모두 pass, R2-1 해결 |
| 3a | 토스트 회귀 | `layers.toast` 호출처를 grep한다. origin/main 임시 detached worktree에서 390x844 렌더 check.py 1회를 돌려 바뀌지 않은 화면을 후보 캡처와 픽셀 비교한다. 레퍼런스의 기존 화면에 토스트가 없으면, 검수자 보조 스크립트(`build/` 아래)로 짧은 토스트(영어, 한국어, 숫자)를 후보와 main에서 같은 크기로 찍어 픽셀 비교한다. 비교가 끝나면 main worktree를 지운다 | 짧은 토스트와 바뀌지 않은 화면이 main과 같음 |
| 4 | 소비 저장소 | `godot/addons/seorilabs_game/README.md`, `README.md`, 설계의 소비 게임 항목을 읽는다. starter-template-game `markets-v2` worktree를 `rsync -a --exclude .git --exclude build --exclude .godot`로 `build/consumer/`에 복사하고, `tools/bundle.py`, `tools/test_bundle.py`, `tools/validate_outgame.py` 사본을 후보에서 갱신한다. 후보에서 `bundle.py pack --commit <SHA> --out build/consumer.tar.gz`, 복사본의 `tools/bundle.py --root <복사본> install --bundle <tar>`로 설치하고, 필요하면 `tests/common/dev_probe.gd`를 검사 목록에 넣고 `outgame-profile.json`의 `uiStandard.version`을 1.2.0으로 바꾼 뒤 복사본에서 `npm test`(headless)를 돌린다. 설정 버튼 수, Tab 순서, `_unhandled_key_input` 재정의 같은 깨짐이 있는지 본다 | 소비 게임이 바꿔야 할 것을 빠짐없이 적고, 설치 뒤 `npm test`가 통과하거나 실패 원인을 특정 |
| 5 | API 경계 | 코드 읽기와 `build/` 아래 일회용 스크립트로 확인: 재생 중 `play_cutscene` → 막힘 쌍, 빈 `cuts`, `register_snapshots`의 apply가 `ok=false` 반환, `set_notes`에 일반 문자열, 테스트실 노출 게이트(디버그 또는 `playtest`, 그리고 `ResourceLoader.exists`) | 각 경우가 설계대로 막히거나 처리되고 오류 로그가 없음 |

실행 중 계획에 더한 것: 소비 게임들이 실제로 쓰는 토스트 호출 모양(명시적 `\n`, 호출 뒤 글꼴 교체, 호출 뒤 글자 크기 변경)을 후보와 main에서 찍어 비교했다(3a에서 짧은 단일 줄 토스트는 같지만 여러 줄 토스트가 달라질 수 있음을 코드에서 본 뒤). 소비 저장소에서 공용 probe가 실패한 뒤 원인을 가르려고 기준 화면 크기(`window/size/viewport_*`)만 바꿔 probe를 단독 실행했고, 수정안 두 가지를 복사본에서 시험한 뒤 되돌렸다. AC-12 재확인용 로컬 웹 `--export-pack`도 돌렸다.

## 실행 명령과 결과

모든 명령은 격리 worktree 루트에서 실행했다. 렌더 실행 기록은 `build/logs/runs.log`에 있다. 렌더 실행은 시작 시 다른 Godot 프로세스 수를 세고, 실행 중 2초마다 이 worktree 밖의 Godot 프로세스를 표본으로 남겼다.

| 순서 | 명령 | 결과 |
|---|---|---|
| 0 | `pgrep -fl -i godot` (11:26:46) | Godot 실행 파일 프로세스 0개. 잡힌 것은 godot-mcp 서버 3쌍뿐이다. 이후 렌더 실행마다 시작 시 0개였고 실행 중 표본도 0줄이었다(대기 없음). 11:42:34부터 다른 세션의 렌더 Godot(`--resolution 1280x720 res://tests/e2e_capture.tscn`, 다른 프로젝트)이 떴는데, 그때는 렌더 실행이 모두 끝난 뒤였고 이후에는 headless 실행만 했다 |
| 1 | `godot --headless --path godot --import --quit-after 2` | 종료 0 (11:26:51), ERROR 0 |
| 2 | `npm test` | 종료 0 (11:26:58–11:27:30). 단위 테스트 34개 OK, check.py `{"ok": true, "scenarios": 14}`. headless ui-kit 109/0(2회차 108 + 긴 토스트 1), dev 21/0, ui-contract 87/0 |
| 3 | `python3 tools/bundle.py verify` | ok, version 1.2.0, files 87, source commit `d07944a…`(잠금이 가리키는 직전 커밋) |
| 4 | `check.py --capture --size 390x844 --out build/qa-r3-390x844` | 종료 0 (11:27:42–11:28:26), 14개 시나리오 |
| 5 | `check.py --capture --size 320x568 --out build/qa-r3-320x568` | 종료 0 (11:28:41–11:29:32), 14개 시나리오 |
| 6 | `check.py --capture --size 844x390 --out build/qa-r3-844x390` | 종료 0 (11:29:35–11:30:41), 14개 시나리오 |
| 7 | `check.py --capture --size 1280x720 --out build/qa-r3-1280x720` | 종료 0 (11:30:41–11:31:30), 14개 시나리오 |
| 8 | origin/main `e7e905d` 임시 worktree에서 `check.py --capture --size 390x844` | 종료 0 (11:31:44–11:32:19), 10개 시나리오. json·로그와 캡처 사본 `build/main-run/` |
| 9 | 보조 `build/review-r3/toast_compare.gd`(짧은·중간·긴 토스트, en-US·ko-KR), 후보와 main, 390x844·320x568 | 8회 모두 종료 0, ERROR 0 (11:33:13–11:33:44). 결과 `build/review-r3/toast-<트리>-<크기>/` |
| 10 | 보조 `build/review-r3/toast_consumer.gd`(소비 게임 호출 모양), 후보와 main, 360x640·390x844 | 4회 모두 종료 0 (11:36:27–11:36:38). 결과 `build/review-r3/consumer-toast-<트리>-<크기>/` |
| 11 | 소비 복사본 설치 전 `npm test` | 종료 0 (11:39:14–11:39:40). 단위 29개 OK, `check_native` ok, check.py 8개 시나리오 |
| 12 | 후보 `bundle.py pack --commit 1c73506… --out build/consumer.tar.gz`, 복사본 `bundle.py --root build/consumer install --bundle …` | 둘 다 ok(1.2.0, 87 files). 복사본 `bundle.py verify` ok. 변경 53개 경로 |
| 13 | 설치 직후 복사본 `npm test` | 종료 1. `test_evidence`(missing_ui_standard `bundle lock version/files`)와 `test_fresh_start`(새 파일이 git에 없어 `outgame_main.gd` 파싱 실패) 2건. 둘 다 소비 쪽 절차 문제라 아래 설치 절차 3, 4번으로 해결 |
| 14 | 새 파일 git 추가, `uiStandard.version` 1.2.0 뒤 복사본 `npm test` | **종료 1** (11:40:39–11:40:51). 단위 30개 OK, `check_native` ok, check.py가 공용 `tests/common/ui_kit_probe.gd`에서 멈춤: 109 checks, 6 failed(컷신 motion·reduced의 `tap goes to the next cut`, `Space on the last cut finishes`, `continue finishes after skipped credits`). 발견 사항 R3-1 |
| 15 | 진단용 check.py 사본(`build/review-r3/check_diag.py`: `dev_probe` 추가, 두 공용 probe 실패는 기록만 하고 계속) | ui_kit 6 failed, dev_probe 21 checks 10 failed. 나머지(계약 probe, 계정 probe, starter 여정 8개, 플랫폼 여정, 증거 검증)는 `{"ok": true, "scenarios": 8}` (11:43:10–11:43:37) |
| 16 | 복사본에서 `window/size/viewport_*`만 바꿔 공용 probe 단독 실행 | ui_kit: 360x640·390x844·568x320 0 failed, 1280x720 6 failed. dev: 390x844 0 failed, 1280x720 10 failed |
| 17 | 수정안 시험(복사본에서만 고치고 되돌림, 되돌린 뒤 `bundle.py verify` ok) | `_press`의 `root.push_input(event, true)`: ui_kit 1280x720 0 failed, dev 1 failed(결과 줄 검사). 두 probe에서 `root.size = Vector2i(390, 844)` 앞에 `root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED`: 1280x720·390x844·360x640 모두 ui_kit 109/0, dev 21/0 |
| 18 | 보조 `build/review-r3/edge.gd`(API 경계, headless) | 종료 0, ERROR 0 (11:44:46). 결과 `build/review-r3/edge/edge.json` |
| 19 | `godot --headless --path godot --export-pack "Web" build/qa-r3-export/web.zip` | 종료 0, 175개 항목. `addons/seorilabs_game/dev/` 0개, `tests/` 0개, `cutscene_player` 4개 포함. 목록 `build/qa-r3-export/filelist.txt` |

렌더 check.py 5회(후보 4, main 1)와 보조 렌더 캡처 12회는 모두 다른 렌더 창이 없을 때 돌았고 한 번도 실패하지 않았다. 2회차가 정리한 간헐 실패 원인(다른 Godot 창)과 맞는 결과다.

## 기능 결과

| 항목 | 결과 | 근거 |
|---|---|---|
| 여정 | 14/14 passed, 4개 크기 모두 | 단계 수 221(1280x720은 가로 검사가 더해져 222). 2회차와 같다 |
| ui-kit probe | 109 checks, 0 failed, 4개 크기 모두 | 2회차 108 + `layers: long toast wraps inside the screen`. 렌더 실행 기록 예: 844 폭에서 칩 `[16, 55]–812x73` |
| dev probe | 21 checks, 0 failed | 4개 크기 모두 |
| ui-contract probe | 87 checks, 0 failed | 4개 크기 모두 |
| 부속 probe | camp 2/2, navigation 3/3, scroll-boundary 1/1 | 4개 크기 모두 |
| main과 바뀌지 않은 화면 비교(390x844) | 차이는 설명 가능 | 공통 캡처 45장 중 18장이 픽셀 동일하다. 나머지 27장 중 `settings-ko`는 설정 목록 끝에 "크레딧", "테스트실"이 더해져 스크롤 위치가 달라졌고, `navigation/keyboard-support-focus`, `native-after-late-callback`, `camp/camp-settings`는 같은 이유로 스크롤 막대 길이만 다르다. 나머지 23장(순위, 팝업, 오퍼, 보상 등)은 같은 SHA끼리 비교해도(1회차·2회차의 같은 후보 반복 실행) 비슷하거나 더 크게 달라지는 전환 중간 프레임이다. 예: `popup-open`은 같은 SHA 반복끼리 최대 246,542픽셀이 다르고 이번 main 대비는 20,869픽셀 |
| 짧은 토스트(단일 줄) | main과 픽셀 동일 | "Saved", "+10 coins", "12,800", "저장했어요"를 en-US·ko-KR, 390x844·320x568에서 찍은 캡처 4장이 main과 같다. 칩 사각형도 같다(예: 390에서 "Saved" 94x30 at x=148) |
| 긴 토스트 | 화면 안에서 줄바꿈 | main은 화면 밖으로 나간다(예: 390에서 1045px 한 줄). 후보는 칩 358px(390), 288px(320)로 줄바꿈된다. "Finish the current round first"는 320에서 288x59 두 줄로 모두 보인다(R2-1 해결) |
| 여러 줄·호출 뒤 수정 토스트 | **main과 다름** | 아래 R3-2 |
| 묶음·export | pass | `bundle.py verify` ok, `test_export_presets` 통과, 로컬 웹 pack에 `dev/` 없음 |

| AC | 결과 | 근거 |
|---|---|---|
| AC-8 | pass(이 저장소) | ui-kit 컷신 항목 motion·reduced 통과. 다만 같은 probe가 기준 크기 1280x720 소비 프로젝트에서는 실패한다(R3-1) |
| AC-9 | pass | `map-prologue-first-start-once` 16단계, 기존 10개 시나리오 통과 |
| AC-10 | pass | `settings-credits-and-ending-replay` 21단계 통과, 크레딧 캡처 4개 크기 |
| AC-11 | pass(이 저장소) | dev 21항목, `debug-test-room` 20단계 통과. dev probe도 1280x720 소비 프로젝트에서는 10건 실패한다(R3-1) |
| AC-12(기반 몫) | pass | `test_export_presets` 통과, 로컬 웹 pack에 `dev/` 0개, 공통 코드가 `dev/`를 preload하지 않음(`outgame_main.gd:22`는 경로 문자열과 런타임 `load()`) |
| AC-13 | pass, 4개 크기 | 아래 화면 판정 64장 pass |
| AC-14(기반 몫) | pass | `test_bundle`, `test_ui_contract` 통과, `bundle.py verify` ok. 상위 AC-14의 starter 설치는 `bundle.py verify`까지 통과하지만 starter의 `npm test`는 R3-1로 실패한다 |

API 경계(`build/review-r3/edge/edge.json`):

| 경우 | 결과 | 판정 |
|---|---|---|
| 재생 중 `play_cutscene` | 첫 호출 `{ok: true}`, 둘째 `{ok: false, blocked_reason_pair: ["A scene is already playing", "이미 연출이 재생 중이에요"]}`, 상태는 계속 `cut` | 설계대로 |
| 빈 `cuts`, `cuts` 없음, `cuts`가 문자열, 크레딧만 | 네 경우 모두 `["This scene has no cuts", "재생할 컷이 없어요"]`로 막히고 상태 `idle` | 설계대로("컷이 없으면 막는다"). 재생기 자체는 크레딧만 있는 스크립트도 재생하지만 호스트가 막는다 |
| `register_snapshots`의 apply가 `ok=false` | 첫 탭에 "Tap again to apply", 둘째 탭에 apply 1회, 토스트 "Preset could not apply", 결과 줄 그대로, 저장 바이트 동일 | 설계대로 |
| `set_notes`에 일반 문자열, 짝, 한 원소 배열 | "• Plain string note", "• Pair note", "• Single item" | 설계대로 |
| 반환값 없는 행동 callable | 행동은 실행되는데(부수 효과 1회) 토스트는 "Not available right now" | R3-4(참고) |
| 점이 든 id(`dot.id`)의 두 번 누름 행동 | 버튼 이름이 `test_action_dot_id`로 바뀌고 `_confirmed`가 원래 id로 찾지 못해 무장도 적용도 안 된다. 경고 없음 | R3-4(참고) |
| 노출 게이트 | `_attach_test_room()`(`outgame_main.gd:300-312`)이 `OS.is_debug_build() or OS.has_feature("playtest")`와 `ResourceLoader.exists(TEST_ROOM)`이 모두 참일 때만 `load()`한다. 아니면 `test_room`이 null이라 설정 항목(`:783`)과 F9(`:291-297`)가 생기지 않는다. `class_name` 없음, `dev/`를 preload하는 곳 없음, 웹 preset `exclude_filter`에 `addons/seorilabs_game/dev/**` | 설계대로. 출시 빌드 실행은 headless로 흉내 낼 수 없어 코드로만 확인 |

## 화면 판정

캡처 위치: `build/qa-r3-390x844/`, `build/qa-r3-320x568/`, `build/qa-r3-844x390/`, `build/qa-r3-1280x720/`. 크기별 묶음 보기 `build/review-r3/sheets/<캡처>-portrait.png`(390x844 | 320x568), `<캡처>-landscape.png`(844x390 위, 1280x720 아래). 확대 crop `build/review-r3/crops/`.

| 캡처 | 390x844 | 320x568 | 844x390 | 1280x720 | 근거 |
|---|---|---|---|---|---|
| prologue-1 | pass | pass | pass | pass | 흰 자막과 외곽선이 아래 그림자 위에서 읽힌다. 세로는 단어 단위 두 줄, 가로는 한 줄. 스킵은 오른쪽 위, 자막과 떨어져 있다 |
| prologue-2 | pass | pass | pass | pass | 밝은 양피지 위에서도 외곽선으로 읽힌다. 844에서 자막 끝에 섬 그림이 겹치지만 글자를 가리지 않는다 |
| prologue-title | pass | pass | pass | pass | "SKY ATLAS"와 "Chart the lost skies"가 잘리지 않는다. 844에서 등대 줄무늬 위에 놓여도 그림자로 구분된다 |
| credits | pass | pass | pass | pass | 글꼴 이름 앞 간격이 이름과 저작권 줄 사이보다 넓어졌다(1280 캡처를 눈으로 잰 줄 간격: 앞 묶음의 "SIL Open Font License 1.1"에서 "Fredoka"까지 약 47px, "Fredoka"에서 저작권 줄까지 약 31px). 이름이 아래 줄의 머리로 읽힌다(R2-4 크레딧 몫 해결). 1280은 640px 가운데 칸 |
| credits-end | pass | pass | pass | pass | 마지막 "SIL Open Font License 1.1"까지 스크롤된다. 1280은 스크롤 없이 모두 보인다 |
| settings-ending | pass | pass | pass | pass | "Replay ending", "Credits", "Test room"이 기존 설정 버튼과 같은 판으로 목록 끝에 있다. 320·844는 목록 스크롤로 아래 항목이 경계에 걸린다(정상). 1280은 버튼이 프레임 폭으로 늘어나는 기존 배치 |
| ending-1 | pass | pass | pass | pass | 스킵 활성. 390에서 기구가 왼쪽 가장자리에 붙고 자막이 말하는 등대가 화면 밖이다(F-6, 그림 구도) |
| ending-count | pass | pass | pass | pass | "12,800"이 외곽선 덕분에 어두운 하늘과 밝은 책 위 모두에서 읽힌다 |
| ending-credits | pass | pass | pass | pass | 롤은 스킵 아래에서만 보인다. 320·844에서 위 경계가 페이드 없이 잘려 반쯤 잘린 제목이 보이는 순간이 있다(R2-4 롤 몫, 남음) |
| ending-end | pass | pass | pass | pass | 금색 "Continue"가 가운데에 있다. 끝 화면에 다른 문구는 없다 |
| test-room | pass | pass | pass | pass | 320·390은 2열, 844·1280은 3열. 844는 첫 화면에 "Add 100 coins"와 진행 행이 보이고 나머지는 스크롤 |
| test-room-armed | pass | pass | pass | pass | 무장한 버튼만 금색 "Tap again to apply", 다른 버튼 위치 불변, 결과 줄 "Coins 0 → 100" |
| test-room-blocked | pass | pass | pass | pass | 320: 토스트가 "Finish the current / round first" 두 줄로 화면 안(x 16–304)에 모두 보인다(R2-1 해결). 390: 같은 문장이 두 줄(358x59)이 되어 2초 동안 "Test room" 제목과 닫기 버튼 대부분을 덮는다(2회차는 한 줄 364x30이라 위 띠만 덮었다, R3-3). 844·1280은 한 줄로 프레임 위 띠 안 |
| prologue-1-ko | pass | pass | pass | pass | "건너뛰기"가 버튼 안 한 줄, 자막은 어절 단위 줄바꿈 |
| test-room-ko | pass | pass | pass | pass | 버튼과 구역 제목이 프레임 안. 320 "코인 100 추 / 가", 390 "적용해 / 요."처럼 음절 단위 줄바꿈이 남는다(R2-2, 이슈 #26, 범위 밖). 글자는 모두 보인다 |
| credits-ko | pass | pass | pass | pass | 칸과 여백은 영어와 같다. 320 "만들었습니 / 다", 390 "만들 / 고"(R2-2, 범위 밖) |

## 1·2회차 지적 확인

| 지적 | 상태 | 근거 |
|---|---|---|
| F-1 크레딧 여백, PC 배치, 글꼴 이름 구분 | 해결 유지 | 4개 크기 credits 캡처. 이번 회차에 묶음 사이 간격까지 더해졌다 |
| F-2 끝 화면 Esc·뒤로 가기 | 해결 유지 | ui-kit `back on the end screen continues` 4개 크기 통과 |
| F-3 렌더 간헐 실패 | 해결 유지 | 다른 렌더 창이 없을 때 렌더 check.py 5회 모두 통과 |
| F-4 안전 영역 | 남음(참고) | 바뀌지 않음. 소비 게임 단계 항목 |
| F-5 한국어 캡처 | 해결 유지 | `prologue-1-ko`, `test-room-ko`, `credits-ko` 4개 크기 |
| F-6 정사각 컷 그림 잘림 | 남음(참고) | 390 ending-1에서 등대가 화면 밖 |
| R2-1 320 막힌 행동 토스트 잘림 | 해결 | 320에서 두 줄로 모두 보인다. 다만 같은 수정이 390에서 제목과 닫기를 덮는 두 줄 토스트를 만들고(R3-3), 여러 줄 토스트의 모양을 바꾼다(R3-2) |
| R2-2 한국어 음절 줄바꿈 | 범위 밖 | 이슈 seorilabs/game-foundation#26으로 추적. 이번 캡처에도 그대로 있다 |
| R2-3 검수 환경 간섭, navigation probe 180초 멈춤 | 남음(참고) | 기존 코드, 바뀌지 않음 |
| R2-4 시각 완성도 | 일부 해결 | 설정 크레딧 묶음 간격은 해결. 엔딩 크레딧 롤 위 경계 페이드는 그대로(참고) |

## 소비 저장소 설치 결과

starter-template-game `markets-v2`(`811a87b`, 기준 화면 1280x720, 잠금 1.1.0 `17984c9`)의 복사본에 후보 묶음을 설치했다. 바꿔야 한 것과 결과는 다음과 같다.

| 순서 | 소비 게임이 할 일 | 이번 실행 결과 |
|---|---|---|
| 1 | `tools/bundle.py`, `tools/test_bundle.py`, `tools/validate_outgame.py`를 후보 사본으로 바꾼다. starter 사본은 `17984c9` 것이라 main에서 들어간 `marketServices`, `--market` 검사도 함께 들어온다 | 교체 |
| 2 | foundation에서 `python3 tools/bundle.py pack --commit <검수 SHA> --out <tar>`, starter에서 `python3 tools/bundle.py --root <starter> install --bundle <tar>` | ok. 53개 경로 변경: `dev/` 2개, `cutscene_player` 2개, `tests/common/dev_probe.gd` 추가, 스킨 svg 15개 삭제와 png 15개 추가(그린 스킨 전환분), `outgame_main`, `state`, `hud_layers`, `juice`, `theme_builder`, `currency_chip`, `camp_home`, `e2e_driver`, `ui_kit_probe` 변경, `seorilabs_platform` SDK 1.1.0 → 1.1.1, 잠금. starter는 1.2.0 기능만이 아니라 그 사이 main 변경까지 한 번에 받는다 |
| 3 | 새 파일을 모두 git에 추가한다 | 추가 전에는 `test_fresh_start`가 추적 파일만 복사해 `cutscene_player.tscn`이 없어 `Could not resolve class "res://addons/seorilabs_game/flow/outgame_main.gd"`로 실패했다. 추가 뒤 통과 |
| 4 | `godot/data/outgame/outgame-profile.json`의 `uiStandard.version`을 `1.2.0`으로 바꾼다 | 바꾸기 전 `test_evidence`가 `missing_ui_standard: bundle lock version/files`로 실패. 바꾼 뒤 단위 30개 OK |
| 5 | `tools/check.py` 명령 목록에 `res://tests/common/dev_probe.gd -- --out <out>/dev.json`을 더하고 `checks`에 `dev_probe`를 넣는다(설계 적용 2번) | 진단 사본으로 확인. dev probe 21개 중 10개 실패(R3-1) |
| 6 | 출시 export preset `exclude_filter`에 `addons/seorilabs_game/dev/**`, 웹 플레이테스트 preset만 `custom_features="playtest"` | `markets-v2`에 이미 있다. `test_release_presets_exclude_test_room`, `test_web_playtest_keeps_test_room`, `test_playtest_feature_only_on_web` 통과 |
| 7 | 로컬 정리: `skins/soft_adventure/*.svg.import` 고아 파일 10개(gitignore 대상)를 지운다 | 복사본에 남아 있었다. 깨끗한 checkout과 CI에는 없지만, 그린 스킨 3회차 D1처럼 지워진 그림을 가린 사례가 있어 지우는 편이 안전하다 |
| 8 | (막힘) 공용 probe 수정이 필요하다 | `tests/common/ui_kit_probe.gd` 6건, `dev_probe.gd` 10건 실패. 소비 게임은 잠금 해시 때문에 이 파일을 고칠 수 없다(R3-1) |

깨지지 않은 것: starter 여정 8개, 플랫폼 여정, 계약·계정 probe, 증거 검증이 1.2.0 설치 뒤에도 통과했다(진단 실행 `{"ok": true, "scenarios": 8}`). 설정 목록에 "Credits"(항상)와 "Test room"(디버그 실행)이 더해져도 starter 여정의 설정 흐름은 그대로 통과했다. starter, betta-raising, malang, my-little-parasite, slot-defense의 `outgame_main` 하위 스크립트에 새 멤버 이름(`credits`, `cutscene`, `test_room`, `play_cutscene`, `_enter_game` 등 `outgame_main` 23개와 `state` 2개)과 겹치는 선언이 없고, `_unhandled_key_input`을 재정의한 곳도 없다. malang과 slot-defense는 `_input`(Esc, Tab, 화살표)과 `_notification`을 정의한다. 컷신과 테스트실은 호스트보다 깊은 자식이라 `_input`을 먼저 받아 처리 완료로 표시하고, `_notification`은 상위 스크립트 것도 함께 불리며 두 게임의 처리는 시각 기록과 광고 일시정지뿐이라 겹치지 않는다(코드로 확인, 두 게임에서 실행하지는 않음).

starter 화면 참고: starter는 `test_room_setup`을 주지 않는다. 그래도 디버그 실행에서는 테스트실이 붙어 설정에 "Test room"이 생기고, 열면 제목과 "Action results appear here."만 있는 빈 방이 나온다(`_rebuild`는 등록이 없으면 구역을 만들지 않는다). 또 `_attach_test_room()`은 `_ready()`에서 한 번 `test_room_setup`을 부르므로 제품은 레퍼런스처럼 `_init()`에서 `test_room_setup`을 정해야 한다. README에는 이 시점이 적혀 있지 않다.

## 발견 사항

- R3-1 (차단, 소비 호환, `godot/tests/common/ui_kit_probe.gd:237-247`의 `_press`와 `:269`, `godot/tests/common/dev_probe.gd:28`과 `:60-70`의 `_press`, 근거 `build/logs/consumer-after-install-2.log`, `build/logs/consumer-diag-headless-2.log`, `build/review-r3/consumer-uikit-*.log`, `consumer-dev-*.log`, `fix2-*.log`): 두 공용 probe는 headless 루트 창을 `root.size = Vector2i(390, 844)`로 맞춘 뒤, 컨트롤의 캔버스 좌표로 만든 마우스 이벤트를 `root.push_input(event)`로 넣는다. `push_input`은 이 좌표를 창 좌표로 보고 프로젝트의 늘이기 변환(`canvas_items`, `expand`)을 거꾸로 적용한다. 레퍼런스는 기준 크기가 390x844라 변환이 없어 통과하지만, starter처럼 기준 크기가 1280x720이면 배율이 약 0.305가 되어 화면 가운데를 누른 탭이 캔버스 (640, 1385)로 옮겨져 390x844 호스트 밖에 떨어진다. 그래서 ui_kit의 컷신 탭·계속하기 6건과 dev probe의 버튼 누름 10건이 실패한다. 기준 크기만 바꾼 실험에서 360x640, 390x844, 568x320은 통과하고 1280x720만 실패했다. 실패 시나리오: 설계 적용 2번대로 starter가 1.2.0을 설치하면 `npm test`와 CI의 `check.py`가 `Godot failed: … ui_kit_probe.gd`로 멈추고, `dev_probe`를 더하면 10건이 더 실패한다. `tests/common`은 잠금 해시로 묶여 있어 starter가 고칠 수 없고, 검사에서 빼면 컷신·테스트실 계약 검사가 사라진다. 기준 크기 1280x720인 we-moore도 1.2.0을 설치하면 같은 probe가 실패할 것으로 본다(추정, 직접 실행하지 않음). 이 저장소의 AC-8, AC-11은 기준 크기 390x844에서만 확인되어 이 문제를 잡지 못했다. 시험한 수정: 두 probe에서 `root.size = Vector2i(390, 844)` 바로 앞에 `root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED`를 넣으면 1280x720, 390x844, 360x640 모두 ui_kit 109/0, dev 21/0이다. `push_input(event, true)`만 바꾸면 ui_kit은 통과하지만 dev probe의 `result line keeps a fixed two-line height`가 남는다. 테스트실이 1280 폭 캔버스에 배치되어 긴 결과 문구가 두 줄에 들어가기 때문이다. 재발 방지로 기준 크기를 1280x720으로 바꾼 임시 프로젝트 사본에서 두 probe를 돌리는 단위 테스트를 권한다.
- R3-2 (수정 권장, 공용 `godot/addons/seorilabs_game/ui_kit/hud_layers.gd:18-37`의 `toast()`, 근거 `build/review-r3/consumer-toast-*/toast-consumer.json`, crop `build/review-r3/crops/consumer-toast-360-main-vs-candidate.png`): 새 `toast()`는 문장 폭을 호출 시점에 한 번, 전체 문자열을 한 줄로 보고 `NumberLabel` 글꼴로 잰다. 또 모든 토스트에 가운데 정렬을 준다. 그래서 단일 줄 짧은 토스트는 main과 픽셀이 같지만 다음 세 경우는 모양이 바뀐다. (a) 명시적 `\n`이 있는 짧은 두 줄 토스트: my-little-parasite의 "Could not save.\nTap again to retry."는 두 줄을 이어 잰 폭이 화면을 넘는 것으로 계산되어 칩이 246px에서 화면 폭(360에서 328px, 390에서 358px)으로 넓어진다. (b) 여러 줄 토스트의 각 줄이 왼쪽 정렬에서 가운데 정렬로 바뀐다("A memory kept / +100 sparkles" 등). (c) 호출 뒤 라벨을 바꾸는 소비 게임: we-moore처럼 호출 뒤 본문 글꼴로 바꾸면 "Finish the current round first"가 본문 글꼴로는 261px인데 칩이 358px로 고정된다. malang처럼 호출 뒤 글자 크기를 키우는 경우는 오히려 화면 밖으로 나가던 것이 화면 안에 들어온다(436px 한 줄 → 358px 두 줄). 실패 시나리오: my-little-parasite가 1.2.0으로 올리면 저장 실패 알림이 작은 칩에서 화면 폭 띠로 바뀐다. 코드 주석의 "짧은 안내의 모양은 그대로다"가 여러 줄 토스트에는 맞지 않는다. 지금 1.2.0을 쓰는 소비 게임은 없다. 제안: 줄마다 폭을 재서 가장 긴 줄로 판단하고(`text.split("\n")`), 가운데 정렬은 줄바꿈을 켤 때만 주고, 폭 맞춤을 `call_deferred`나 `resized`로 미뤄 호출 뒤 바뀐 글꼴과 크기를 반영한다.
- R3-3 (참고, 같은 `toast()`와 `dev/test_room.gd:270-272`, 캡처 `build/qa-r3-390x844/test-room-blocked.png`, crop `build/review-r3/crops/blocked-toast-top-r3-vs-r2.png`): 레퍼런스 기준 크기 390x844에서 "Finish the current round first"는 2회차에 한 줄(364x30, 양옆 13px)로 프레임 위 띠만 덮었는데, 이번에는 양옆 16px 기준을 넘어 두 줄(358x59)이 되어 2초 동안 "Test room" 제목과 닫기 버튼 대부분을 덮는다. 토스트는 입력을 가로채지 않으므로 닫기는 눌린다. 두 줄 칩은 스킨의 가운데 띠 무늬가 두 줄 사이로 늘어나 보인다. 문장을 숫자용 고정폭 글꼴로 쓰는 것이 폭을 키우는 원인이다. 본문 글꼴이면 같은 문장이 261px이라 320과 390 모두 한 줄에 들어간다(측정값 `build/review-r3/consumer-toast-*`). 2회차 제안대로 문장 토스트는 본문 글꼴을 쓰고 숫자 토스트만 `NumberLabel`을 유지하기를 권한다. R3-2와 같은 곳이라 함께 고치면 된다.
- R3-4 (참고, `godot/addons/seorilabs_game/dev/test_room.gd:221-249`, 근거 `build/review-r3/edge/edge.json`): 테스트실 API 오용 두 가지가 조용히 실패한다. 반환값 없는 행동 callable은 실행되는데 토스트가 "Not available right now"라고 알려 플레이테스터가 실패로 오해한다. id에 `.`처럼 노드 이름에 못 쓰는 문자가 있으면 버튼 이름이 `_`로 바뀌어 두 번 누름 행동과 시점 프리셋이 무장도 적용도 되지 않고 경고도 없다. 제안: null 반환은 `push_warning`을 남기고 "Done"으로 보거나, 등록 시 반환 계약을 검사한다. 무장 상태는 버튼 참조로 들고 있거나 id를 `validate_node_name()`으로 바꿔 쓴다.
- R3-5 (참고, `godot/addons/seorilabs_game/flow/outgame_main.gd:194`, `:300-312`, `:783`): 디버그 실행에서는 제품이 `test_room_setup`을 주지 않아도 테스트실이 붙고 설정에 "Test room"이 생겨 빈 방이 열린다. starter가 이 상태다. 또 `test_room_setup`은 `_ready()`에서 한 번만 불리므로 `_init()`에서 정해야 한다. 제안: 등록된 것이 없으면 설정 항목과 F9를 숨기거나, README에 `_init()`에서 정하라고 적는다.
- 남은 참고: 엔딩 크레딧 롤 위 경계의 페이드 없음(R2-4 롤 몫), F-4 안전 영역, F-6 정사각 그림 구도, R2-2 한국어 음절 줄바꿈(#26), R2-3 navigation probe 180초 멈춤.

## 판정

fail. 이 저장소 안에서는 후보 `1c73506`이 AC-8~AC-14를 모두 다시 통과했다. 4개 크기 렌더 check.py가 한 번에 통과했고(여정 14개, ui-kit 109, dev 21, ui-contract 87), 새 화면 16종 64장이 잘림 없이 읽힌다. R2-1은 고쳐졌고 크레딧 묶음 간격도 좋아졌다. 바뀌지 않은 화면과 단일 줄 짧은 토스트는 main과 같다.

차단 판정의 근거는 R3-1 하나다. 이 후보가 묶음으로 내보내는 공용 probe 두 개가 기준 크기 1280x720인 starter에서 결정적으로 실패하고, starter는 잠금 해시 때문에 이 파일을 고칠 수 없다. 설계 적용 2번(starter 설치와 `dev_probe` 추가)과 상위 AC-14의 starter 설치가 이 후보로는 `npm test`를 통과할 수 없다. 수정은 두 probe에 한 줄씩이고 복사본에서 효과를 확인했다. 고친 뒤 확인할 것은 이 저장소의 `npm test`, starter 복사본(기준 1280x720)에서 `dev_probe`를 넣은 `npm test`, 그리고 R3-2와 R3-3을 함께 고친다면 3a의 토스트 비교와 test-room-blocked 4개 크기 캡처다. 화면 판정은 토스트를 바꾸지 않는 한 이번 결과를 그대로 쓸 수 있다.

AC-13 최종 판정: 390x844 pass, 320x568 pass, 844x390 pass, 1280x720 pass. 컷신, 크레딧, 테스트실이 네 크기 모두에서 잘리지 않고 읽힌다. 390x844 test-room-blocked의 토스트가 2초 동안 제목과 닫기를 덮는 점(R3-3)과 한국어 음절 줄바꿈(R2-2, #26)은 글자를 가리거나 자르지 않아 AC-13 실패로 보지 않았다.

검수 캡처와 로그 원본은 이 worktree의 `build/` 아래에만 있다(`qa-r3-390x844`, `qa-r3-320x568`, `qa-r3-844x390`, `qa-r3-1280x720`, `main-run/`(main 390x844 실행 사본), `qa-r3-export/`, `review-r3/`(보조 스크립트, 토스트 비교, 크기별 묶음 보기, crop, 소비 probe 실험 로그), `consumer/`(starter 복사본과 검사용 임시 git), `consumer.tar.gz`, `logs/`). main 비교용 worktree는 삭제했다. 이번 실행이 Godot 사용자 폴더에 만든 격리 저장 항목(레퍼런스 43개, starter 9개)을 지웠다. NAS1dual 이관은 PR 정리 단계에서 한다.

## 증적 보관

본문의 `build/` 경로는 검수용 임시 worktree였고 지웠다. 원본(캡처, 로그, 측정 결과)은 NAS1dual `agent-artifacts/game-foundation/2026-11-26/1c73506b334011fb898691fbc1cdf66565b7e2fd/cutscene-test-room-review-r3`에 옮겼고, 같은 폴더의 `MANIFEST.txt`가 파일별 크기와 SHA-256과 검증 완료를 적는다(2026-11-26). starter 복사본과 묶음 tar, export 패키지처럼 다시 만들 수 있는 파일은 옮기지 않았다.
