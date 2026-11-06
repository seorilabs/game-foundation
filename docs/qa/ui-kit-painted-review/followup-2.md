# 그린 스킨 후속 보정 재검수

- 검수자: 독립 검수 에이전트(구현자와 다르고, 이전 후보 03db1ea 검수와 별도로 실행)
- 저장소: seorilabs/game-foundation, 브랜치 fix/ui-kit-skin-followups
- 후보 SHA: e368889638547c2619b63ae164ec8417e14e72ad (코드 커밋 c648049, 그 뒤 잠금 갱신 e368889). 기준 main 860bae0, 이전 후보 03db1ea
- 크기: foundation check.py 390x844, 568x320, 844x390. camp_probe 추가 실행 844x390, 667x375, 1024x600, 1280x720. starter-template-game 7크기 390x844, 844x390, 667x375, 812x375, 960x540, 568x320, 1024x600
- 실행 시각: 2026-11-06 10:54~11:08 UTC
- 실행 환경: macOS 개발 환경, Godot 4.7.2.stable(headless와 렌더 캡처), Python 3.14와 Pillow 12.3, Node 24.16, npm. 기기 사용 없음
- 격리 저장: foundation은 후보 SHA를 새 worktree로, starter는 main bcb61a7을 detached worktree 두 개(묶음 설치용, 기준 비교용)로 띄웠다. check.py가 만드는 격리 저장소를 썼고, 저장소 밖 임시 프로브 3개는 `user://` 임시 저장 파일을 만든 뒤 지웠다. foundation worktree의 추적 파일 변경은 검수 뒤 0건이다. starter worktree의 변경은 묶음 설치 결과뿐이며 커밋하지 않고 worktree째 지웠다
- 증거 사본: 캡처 폴더 `gf-fu2-qa-captures/`(`foundation/` 3크기 check 캡처와 camp 추가 크기, `starter/` 7크기 캡처, `extra/`에 임시 프로브 스크립트와 측정 캡처, 비교 시트, 실행 로그, starter 기준 실패 기록)

## 검수 계획

이전 후보 03db1ea의 fail 사유(F1~F4)가 사라졌는지, 그리고 이번에 더해진 두 변경(E2E 드라이버의 1px 미만 넘침 허용, 가로 모드 `_ui_scale` 최소값)이 새 결함이나 검증 공백을 만들지 않았는지를 본다.

1. 기능: 새 체크아웃에서 import 뒤 `npm test`, `check.py --capture`를 390x844, 568x320, 844x390에서 돌려 ok와 scenarios 수, 하위 여정과 로그 오류를 적는다. `bundle.py verify`를 돌린다.
2. F1~F4: camp_probe의 새 시나리오 "landscape-currency-chip-with-shop" 결과와 캡처 `camp/camp-chip-shop.png`, `camp/camp-title.png`를 본다. check.py는 camp_probe를 568x320으로만 돌리므로 844x390 등은 camp_probe를 따로 돌린다. 칩과 헤드라인 비겹침, (+) 크기, 숫자 글자 12px 이상, 정보 잘림을 확인하고, 검사가 실제로 실패할 수 있는 구성인지 본다. 저장소 밖 임시 프로브로 재화 문자열(짧은 것, 두 재화, 세 재화, starter 형식)과 큰 글자 설정을 바꿔 칩을 직접 잰다. camp_home.gd 글자 줄이기 반복, manifest `expect_size`, test_ui_kit 검사를 읽는다.
3. 드라이버와 배율: 03db1ea...e368889 diff를 읽고, 1px 미만 허용이 1px 이상 가려진 컨트롤을 놓치지 않는지(e2e_scroll_probe 경계 검사), `_ui_scale` 새 식이 가로 화면에서 이전 값과 같은지 계산한다.
4. starter: 이 후보로 만든 묶음을 starter main에 설치해 7크기 check.py를 돌리고, 같은 main에 묶음을 설치하지 않은 기준을 2크기 돌려 원래 실패를 재현한다.
5. UX: 팝업 프레임 모달, 캠프 홈, starter 세로 390x844 튜토리얼 캡처를 본다.
6. 결함은 실패 시나리오로 적고, 이전 후보와 같은 것과 알려진 범위 밖 관찰은 따로 적는다.

## 실행 명령과 결과

모든 foundation 명령은 후보 worktree 안에서, starter 명령은 starter worktree 안에서 실행했다.

| 단계 | 명령 | 결과 |
|---|---|---|
| worktree | `git worktree add <격리 경로> e368889638547c2619b63ae164ec8417e14e72ad` | 성공, detached HEAD. 원격 main은 860bae0으로 기준과 같음 |
| import | `godot --headless --path godot --import --quit-after 2` | exit 0, 로그에 error, warning 없음 |
| 단위·E2E | `npm test` | exit 0, 25초. unittest 23개 OK(Pillow가 있어 skin_postprocess 테스트도 실행됨), 이어서 check.py ok true, scenarios 10 |
| 390x844 | `python3 tools/check.py --capture --size 390x844 --out build/r-390` | exit 0, ok true, scenarios 10, 34초 |
| 568x320 | `python3 tools/check.py --capture --size 568x320 --out build/r-568` | exit 0, ok true, scenarios 10, 56초 |
| 844x390 | `python3 tools/check.py --capture --size 844x390 --out build/r-844` | exit 0, ok true, scenarios 10, 50초 |
| 하위 결과 | 3크기 공통 | journey 10/10 passed, camp 2/2(landscape-account-buttons, landscape-currency-chip-with-shop), navigation 3/3, scroll-boundary 1/1(16단계). ui-kit 47항목 실패 0, ui-contract 87항목 실패 0. godot 로그 10개씩에 SCRIPT ERROR, ERROR, WARNING 없음. 크기마다 PNG 37장 |
| 묶음 | `python3 tools/bundle.py verify` | ok true, version 1.1.0, source commit c648049, files 82 |
| camp 추가 | `godot --path godot --script res://tests/reference/camp_probe.gd -- --out build/camp-<크기> --size <크기> --capture` | 844x390, 667x375, 1024x600, 1280x720 모두 exit 0, 두 시나리오 passed |
| 임시 프로브 1 | `godot --path godot --script <저장소 밖>/chip_matrix_probe.gd -- --out <scratch> --capture` | 상점 열림 캠프 홈을 4크기 x 4입력으로 재서 글자 크기, 줄 수, 칩·(+)·헤드라인·모험 시작 버튼 사각형과 겹침을 출력 |
| 임시 프로브 2 | `godot --headless --path godot --script <저장소 밖>/chip_tap_probe.gd -- --out <scratch>` | 568x320 두 재화, 세 재화에서 (+)를 탭하면 둘 다 screen "shop" |
| 임시 프로브 3 | `godot --path godot --script <저장소 밖>/chip_starter_probe.gd -- --out <scratch> --capture` | starter 재화 문자열 형식("%d    🎟 %s")을 568x320, 844x390에서 잰다 |
| 묶음 만들기 | `python3 tools/bundle.py pack --commit e368889638547c2619b63ae164ec8417e14e72ad --out <scratch>.tar.gz` | ok true, files 82 |
| starter 설치 | `python3 tools/bundle.py install --bundle <그 파일>` 뒤 `godot --headless --path godot --import --quit-after 2` | ok true, files 82. 잠금 원본 17984c9 → e368889, 추적 파일 변경 39건(SVG 스킨 삭제, PNG 스킨 추가 포함). import exit 0 |
| starter 7크기 | `python3 tools/check.py --capture --size <크기> --out build/s-<크기>` | 7크기 모두 exit 0, ok true(아래 표) |
| starter 기준 | 묶음 설치 없는 main worktree에서 `python3 tools/check.py --size <크기> --out build/b-<크기>` | 844x390 exit 1, platform 4/5(`check deletion status with a button` 실패). 390x844 exit 1, outgame_journey 180초 시간 초과, `collect reward`부터 6단계 실패 |

## F1~F4 재확인

| 이전 ID | 내용 | 이번 결과 | 근거 |
|---|---|---|---|
| F1 | 568x320 상점 열림 캠프 홈에서 칩이 자리 폭을 넘어 두 줄 헤드라인과 겹침 | 해소 | camp_probe "landscape-currency-chip-with-shop"이 5크기(568x320, 667x375, 844x390, 1024x600, 1280x720)에서 통과했다. 임시 프로브 16측정(4크기 x 짧은 문자열, 두 재화, 두 재화와 큰 글자, 세 재화)에서 칩이 헤드라인과 한 번도 겹치지 않았다. 568x320 칩 오른쪽 끝은 201px, 헤드라인 시작은 206px다. 칩은 줄이지 않고(배율 1) 자리를 헤드라인 앞까지 넓힌 뒤 글자를 줄이고 감싼다. 캡처 568x320과 844x390 `camp-chip-shop.png`에서 칩과 헤드라인 글자가 떨어져 있다 |
| F2 | camp_probe가 상점 없는 구성이라 (+) 검사를 못함 | 해소 | 새 시나리오가 `Ports.CommercePort`를 넣어 (+)가 보이는 상태에서 "shop add button is shown", (+) 크기(568x320에서 44x58), 글자 12px 이상, 칩·헤드라인 비겹침을 검사한다. 이전 후보 코드(칩 배율 하한 0.786, 칩 242px)를 되돌리면 칩 오른쪽 끝이 256px가 되어 헤드라인(206px)과 겹치므로 이 단계가 실패한다. 감싸기를 지워도 칩이 한 줄 240px 안팎으로 넓어져 실패한다. 임시 프로브 2로 (+)를 누르면 상점이 열리는 것도 확인했다 |
| F3 | 칩 글자 하한 11px | 해소 | camp_home.gd 반복이 `font_size = maxi(12, font_size - 2)`라 시작 크기가 홀수여도 12에서 멈춘다(844x390 시작 17 → 15 → 13 → 12). 임시 프로브의 글자 크기는 12, 13, 14, 15, 17, 26px로 모두 12 이상이다. 설계 문구 "12px까지 짝수로 줄인다"와 달리 실제로는 2씩 줄이다 12로 맞춘다(관찰) |
| F4 | manifest에 기대 크기 없음 | 해소 | `art/skins/soft_adventure/asset-manifest.json` 15개 자산 모두에 `postprocess.expect_size`가 있고 커밋된 PNG 크기와 같다(버튼 150x82, 148x78, 패널 148x149, 팝업 226x226, 칩 94x48, 아이콘 128x128). `skin_postprocess.py`는 투명 여백 자르기 뒤 크기가 다르면 ValueError로 멈춘다. `test_ui_kit.py`가 PNG 머리의 너비·높이와 `expect_size`를 비교한다. Pillow가 없는 환경에서는 skin_postprocess 단위 테스트만 건너뛰고 manifest 대조는 계속 돈다 |

재화 칩 측정(상점 열림, 헤드라인 "We could not reach the server. Check your connection and try again.")

| 크기 | 입력 | 글자 | 줄 수 | 칩 폭x높이 | (+) | 헤드라인 겹침 | 모험 시작 버튼 겹침 |
|---|---|---|---|---|---|---|---|
| 568x320 | ★ 10    🎟 2 | 12 | 2 | 187x60 | 44x56 | 없음 | 없음 |
| 568x320 | ★ 1,234,567    🎟 99,999 | 12 | 3 | 187x62 | 44x58 | 없음 | 없음 |
| 568x320 | 같은 문자열, 큰 글자 | 12 | 3 | 187x62 | 44x58 | 없음 | 없음 |
| 568x320 | ★ 1,234,567    🎟 99,999    💎 12,345 | 12 | 5 | 187x102 | 44x98 | 없음 | 있음 |
| 667x375 | 두 재화 | 12 | 2 | 219x60 | 44x56 | 없음 | 없음 |
| 667x375 | 세 재화 | 12 | 3 | 219x62 | 44x58 | 없음 | 없음 |
| 844x390 | 두 재화 | 12 | 2 | 228x60 | 44x56 | 없음 | 없음 |
| 844x390 | 세 재화 | 12 | 3 | 228x62 | 44x58 | 없음 | 없음 |
| 1024x600 | 두 재화 | 14 | 1 | 308x61 | 45x57 | 없음 | 없음 |
| 1024x600 | 세 재화 | 12 | 2 | 337x61 | 45x57 | 없음 | 없음 |
| 568x320 | 10    🎟 0 (starter 형식) | 12 | 1 | 173x60 | 44x56 | 없음 | 없음 |
| 568x320 | 1250    🎟 3 (starter 형식) | 12 | 2 | 187x60 | 44x56 | 없음 | 없음 |
| 568x320 | 99999    🎟 12 (starter 형식) | 12 | 2 | 187x60 | 44x56 | 없음 | 없음 |
| 844x390 | starter 형식 3종 | 17, 15, 13 | 1 | 203~211x60 | 44x56 | 없음 | 없음 |

줄 수가 2 이상인 경우 줄 내용은 캡처로 확인했다(아래 결함 N1).

## 드라이버·배율 변경 검토

(a) `tests/common/e2e_driver.gd` `_axis_move`. 컨트롤이 목록보다 작은 축에서 위 넘침 `view_start - start`, 아래 넘침 `(start + size) - (view_start + view_size)`가 1.0 이상일 때만 가려진 것으로 본다. 이전에는 `is_equal_approx` 오차 범위만 허용했다. 목록보다 큰 축(중심 기준)은 바뀌지 않았다. 이 함수는 `scroll_into_view`(따라서 `tap`)에서만 쓰이고, 1px 미만 넘친 컨트롤도 탭 좌표는 보이는 중심이라 입력이 실제로 닿는다. e2e_scroll_probe가 경계를 고정한다. 정확히 1px 아래 넘침(`_axis_move(0, 100, 53, 48) > 0`)과 1px 위 넘침(`_axis_move(10, 100, 9, 48) < 0`)은 계속 가려짐이고, 0.25px와 0.96px 넘침은 보임이며, 내용 높이 428에 48.96px 버튼을 둔 실제 ScrollContainer에서 탭이 한 번 눌린다. 3크기 모두 16단계 통과. 1px에 아주 가까운 넘침(예 0.9999px)이 float 오차로 보임이 될 수는 있지만 그때도 중심은 보이는 영역 안이라 실패 시나리오가 없다.

(b) `flow/outgame_main.gd` `_ui_scale`. `maxf(1, minf(w/568, h/320))`로 바뀌었다. 폭·높이 비가 568/320 = 1.775 이상이면 h/320이 작은 값이라 이전과 같다.

| 크기 | 비율 | 이전 | 이후 | 56px 버튼 |
|---|---|---|---|---|
| 568x320 | 1.775 | 1.000 | 1.000 | 56.0 |
| 667x375 | 1.779 | 1.172 | 1.172 | 65.6 |
| 812x375 | 2.165 | 1.172 | 1.172 | 65.6 |
| 844x390 | 2.164 | 1.219 | 1.219 | 68.3 |
| 960x540 | 1.778 | 1.688 | 1.688 | 94.5 |
| 1280x720 | 1.778 | 2.250 | 2.250 | 126.0 |
| 1024x600 | 1.707 | 1.875 | 1.803 | 105.0 → 101.0 |
| 390x844(가로 전용 게임) | 0.462 | 2.638 | 1.000 | 147.7 → 56.0 |

1024x600은 16:9보다 좁아서(1.707) 값이 3.8% 줄어든다. 설계 문구 "16:9 이상 가로 화면에서는 값이 같다"는 맞고, 검수 지시의 16:9 목록에 1024x600을 넣은 것만 사실과 다르다. 설계가 적은 "1024x600에서 0.96px"는 새 배율 1.803에서 56 x 1.803 = 100.96px이라 새 값으로 잰 수치와 맞다. starter 1024x600 여정은 통과하고 설정, 튜토리얼, 내 계정, 결과 모달 캡처에서 잘림이나 겹침이 새로 생기지 않았다. 세로 모드 게임(`landscape` false)은 1.0 그대로라 영향이 없다.

(c) camp_home.gd 칩. 칩 배율을 1로 두고, 자리 폭을 `(452 - 32) x 배율`(568x320에서 186px)로 넓히고, (+)는 44x56, 칩 좌우 여백 10px로 줄였다. 남는 폭은 서체로 직접 재서 글자를 줄이고, 그래도 넘치면 `AUTOWRAP_WORD_SMART`로 감싸되 최소 폭을 가장 긴 낱말 이상으로 잡는다. 낱말은 `text.split(" ")`이라 재화 기호(★, 🎟, 💎)와 숫자가 서로 다른 낱말이 된다(N1의 원인). 칩 높이는 줄 수만큼 늘어나고 아래쪽 한계를 보지 않는다(N2의 원인). (+) 표시 여부는 `_currency_chip`에서 `show_add`를 칩 배치 전에 정하므로 측정 시점에 맞다.

(d) camp_probe 새 시나리오의 헤드라인 사각형은 568x320에서 328x966px로 화면 아래로 길다(큰 글자 1137px). 헤드라인 라벨은 이번에 바뀌지 않았고 입력을 받지 않아 화면 영향은 없지만, 이 때문에 비겹침 단계는 사실상 가로 분리만 본다(관찰).

(e) 문서. 설계 "v2 후속 보정" 표의 4행과 5행 사이에 빈 줄이 있어 표가 4행에서 끝나고, 나머지 2행은 머리글과 구분선이 없는 별도 줄이 되어 Markdown에서 표로 보이지 않는다(N3).

## starter 검증

starter-template-game main bcb61a7에 후보 묶음(e368889, 82파일)을 설치한 결과다. 기준 열은 같은 main에 묶음을 설치하지 않고 돌린 결과다.

| 크기 | 후보 묶음 ok | scenarios | 여정 | platform | ui-kit / ui-contract | 시간 | 기준 main |
|---|---|---|---|---|---|---|---|
| 390x844 | true | 8 | 8/8 | 5/5 | 47/0, 87/0 | 19초 | 실패(직접 재현: outgame_journey 180초 시간 초과, collect reward부터 6단계 실패) |
| 844x390 | true | 8 | 8/8 | 5/5 | 47/0, 87/0 | 25초 | 실패(직접 재현: check deletion status with a button) |
| 667x375 | true | 8 | 8/8 | 5/5 | 47/0, 87/0 | 27초 | 실패(지시문 기록, 이번에 재현 안 함) |
| 812x375 | true | 8 | 8/8 | 5/5 | 47/0, 87/0 | 26초 | 실패(지시문 기록) |
| 960x540 | true | 8 | 8/8 | 5/5 | 47/0, 87/0 | 25초 | 실패(지시문 기록) |
| 568x320 | true | 8 | 8/8 | 5/5 | 47/0, 87/0 | 32초 | 통과(지시문 기록) |
| 1024x600 | true | 8 | 8/8 | 5/5 | 47/0, 87/0 | 25초 | 통과(지시문 기록) |

7크기 모두 3분 안에 끝났고 godot 로그에 SCRIPT ERROR, ERROR, WARNING이 없다. 크기마다 PNG 24장. starter의 `sourceSha`는 starter HEAD bcb61a7로 찍힌다(설치한 묶음은 커밋하지 않은 상태).

## UX 결과

foundation 3크기 캡처 111장, camp 추가 4크기 20장, starter 7크기 168장, 임시 프로브 캡처 22장 가운데 팝업 프레임 모달, 캠프 홈, starter 세로 튜토리얼을 중심으로 봤다.

- 팝업 프레임 모달(설정, 지원코드, 순위 2상태, 오퍼, 튜토리얼, 결과, 우편, 접근성, 구매 복원): 390x844, 568x320, 844x390에서 이전 회차에서 해소된 프레임 띠와 나뭇결 면이 그대로다. 이번 diff는 프레임 텍스처와 이 세 크기의 모달 배율을 바꾸지 않았다(위 표에서 세 크기 배율 동일).
- foundation 캠프 홈, 상점 닫힘(`camp-title.png` 568x320, 한국어): "★ 10    🎟 2"가 한 줄로 들어가고 칩 170px가 자리 186px 안에 있다. 헤드라인 "새로운 모험의 시작"과 떨어져 있다.
- foundation 캠프 홈, 상점 열림(`camp-chip-shop.png`): 844x390과 667x375는 "★ 1,234,567" / "🎟 99,999" 두 줄로 기호와 숫자가 짝을 이루고 (+)가 칩 오른쪽에 44x56으로 보인다. 568x320은 "★" / "1,234,567" / "🎟 99,999" 세 줄이 되어 첫 줄에 별만 남는다(N1).
- starter 가로 캠프(844x390, 667x375, 812x375, 960x540, 568x320, 1024x600): 연결된 계정에서 "10    🎟 0"과 (+)가 한 줄로 들어가고 헤드라인, Play 버튼과 겹치지 않는다. 568x320에서는 숫자 글자가 12px로 줄어 있다.
- starter 세로 390x844 튜토리얼: 제목 "Gather three stars"가 두 줄, 별 목표와 Skip guide가 모두 화면 안에 있다. 배율이 1.0이 되어 이전 기존 문제(제목 1425px, 버튼 화면 밖)는 사라졌다. 결과 모달 Continue, 설정, 상점, 내 계정 모달도 화면 안에 있다.
- starter 세로 390x844 캠프 홈은 1280x720 구성을 0.305배로 줄여 작게 보이고 "My accou / nt"로 꺾인다. 가로 전용 게임이 세로 창에 뜬 경우의 알려진 범위 밖 관찰이다. 이 축소된 칩도 "10" / "🎟" / "0"으로 감싸진다.

기존 문제(이번 diff가 건드리지 않은 화면, 이전 회차 기록과 같음): 568x320 튜토리얼 Skip guide가 스크롤 아래에 있음, 568x320 leaderboard-around에 목록 행 대신 내 기록 칩만 보임, 보상 연출 중 Reward 라벨이 버튼 위에 겹침, 상점이 없을 때 재화 칩이 (+) 없이 약 22px 높이의 얇은 띠로 그려짐.

## 결함

| ID | 심각도 | 구분 | 실패 시나리오 | 근거 |
|---|---|---|---|---|
| N1 | 중간 | UX, 신규(이번 감싸기 보정이 만듦) | 568x320 캠프 홈에서 상점이 열려 있으면(상점 port가 있는 게임) 재화 칩이 글자 12px로 줄어도 한 줄에 들지 않아 감싸진다. 감싸는 단위가 공백으로 나눈 낱말이라 재화 기호와 숫자가 다른 줄로 갈린다. (1) foundation 참조 문자열 "★ 10    🎟 2"는 "★ 10    🎟" / "2"가 되어 티켓 기호 옆에 수가 없고 둘째 줄에 "2"만 남는다. (2) starter 문자열 형식에서 코인이 네 자리가 되면("1250    🎟 3") 코인 아이콘 옆 첫 줄이 "1250    🎟", 둘째 줄이 "3"이라 1250이 티켓 수로 읽힌다. 99999 코인도 같다. (3) camp_probe 자체 입력 "★ 1,234,567    🎟 99,999"는 설계가 말한 두 줄이 아니라 "★" / "1,234,567" / "🎟 99,999" 세 줄이 되어 첫 줄에 별만 남는다. 667x375 세 재화에서도 "🎟 99,999    💎" / "12,345"로 갈린다. 기대: 기호와 숫자는 같은 줄에 남고, 감싸기는 재화 사이(여러 칸 공백)에서만 일어나며, 두 재화 문자열은 두 줄 이내 | 캡처 `foundation/r-568/camp/camp-chip-shop.png`(저장소 프로브 캡처), `extra/chip-matrix/568x320/chip-short.png`, `extra/chip-matrix/starter-format/568x320/chip-starter-1250.png`, `extra/chip-matrix/667x375/chip-long3.png`. 측정: 위 칩 표의 줄 수. 코드: camp_home.gd 감싸기 분기 `value.text.split(" ", false)`와 `AUTOWRAP_WORD_SMART`. camp_probe는 줄 구성과 줄 수를 검사하지 않는다 |
| N2 | 낮음 | UX, 신규 | 568x320 상점 열림 캠프 홈에 재화 세 개("★ 1,234,567    🎟 99,999    💎 12,345")를 주면 칩이 다섯 줄, 높이 102px로 늘어나 모험 시작 버튼과 x 189~201, y 178~211 구간이 겹친다. (+)도 98px 높이로 늘어나 버튼 왼쪽 가장자리와 2px 겹친다. 칩 높이에 아래 한계가 없고 camp_probe는 헤드라인 겹침만 본다. 세 재화는 설계 검사 입력에 없지만 `resource_provider`는 임의 문자열을 받는다 | 캡처 `extra/chip-matrix/568x320/chip-long3.png`, 측정 칩 [14.2,108.5 187x102], 버튼 [189.0,177.8 189.9x56.8]. N1을 고쳐 재화 단위로 감싸면 세 줄(약 62px)이 되어 함께 풀릴 가능성이 크다(추정) |
| N3 | 낮음 | 문서, 신규 | 설계 `docs/design/2026-11-06-ui-kit-painted-skin/design.md` "v2 후속 보정" 표를 GitHub에서 열면 4행 뒤 빈 줄 때문에 표가 끝나고, starter 여정 실패와 `_ui_scale` 두 행은 머리글 없는 파이프 문자열로 보인다 | design.md 92행과 94행 사이 빈 줄(93행) |

관찰(결함 아님): 1024x600 배율 1.875 → 1.803 변화(16:9보다 좁은 화면), 헤드라인 라벨 사각형 966px 높이로 비겹침 검사가 사실상 가로만 봄, 큰 글자 설정이 공간이 모자란 칩에서는 효과가 없음(12px 하한 설계), "짝수로 줄인다" 문구와 실제 동작 차이, manifest `final_canvas`는 자르기 전 리사이즈 목표로 남아 있고 최종 크기는 `expect_size`가 맡음.

## 판정

**fail**

근거:

- 기능: foundation 3크기 check.py가 모두 ok true, scenarios 10이고 camp 2/2, navigation 3/3, scroll-boundary 16단계, ui-kit 47항목, ui-contract 87항목, npm test(unittest 23개), bundle verify(82파일)가 통과했다. camp_probe는 추가 4크기에서도 통과했다.
- 이전 fail 사유 F1~F4는 모두 해소됐다. 칩이 헤드라인과 겹치지 않고(16측정), camp_probe가 상점 열린 구성으로 (+) 44x56, 12px 하한, 비겹침을 실제로 검사하며, 글자 하한이 12px이고, manifest 15개 자산에 `expect_size`가 있다.
- 드라이버와 배율 변경은 의도대로다. 1px 경계 검사가 유지되고, 16:9 이상 가로 화면에서 배율이 같다. starter 7크기가 모두 통과했고, 묶음 없는 기준에서 844x390과 390x844 실패를 직접 재현해 이 두 변경이 원인을 고친 것을 확인했다.
- fail 사유는 이번 감싸기 보정이 만든 N1(중간)이다. 가장 작은 지원 가로 크기 568x320에서 상점이 있는 게임은 짧은 재화 문자열도 감싸지는데, 기호와 숫자가 갈려 재화 수를 잘못 읽게 된다. 저장소 프로브의 자체 캡처와 starter 문자열 형식(코인 네 자리)에서 재현된다.
- 재검수 조건: 568x320 상점 열림에서 "★ 10    🎟 2", "★ 1,234,567    🎟 99,999", starter 형식 "1250    🎟 3"이 기호와 숫자를 같은 줄에 두고 두 재화는 두 줄 이내로 그려질 것, camp_probe가 줄 구성(또는 줄 수)을 검사할 것. N2는 같은 보정에서 칩 아래 한계나 모험 시작 버튼 비겹침 검사로 닫을 수 있고, N3은 빈 줄 삭제로 닫는다. 드라이버, 배율, manifest, 팝업 프레임은 재검수 범위에서 빼도 된다.
