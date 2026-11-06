# ui_kit 그린 스킨 독립 검수 1회차

- 검수자: 독립 검수 에이전트 1 (구현자와 다른 에이전트)
- 대상: seorilabs/game-foundation `feat/ui-kit-painted-skin`, 후보 SHA `10a8765d29cdbeb4561fbd8a3ca47ecc7fa506d7`
- 크기: 390x844 (세로 기준). 부속 probe는 고정 크기로 캠프 568x320, 내비게이션 320x568도 함께 찍힌다
- 실행 시각: 2026-11-06 08:29–08:33 UTC
- 실행 환경: dev headless 검증 + 렌더링 캡처(Godot 4.7.2), 격리 worktree(detached HEAD), 격리 저장(journey 자체 격리 프로필)
- 설계: `docs/design/2026-11-06-ui-kit-painted-skin/design.md` AC-1~AC-7, `runtime-review.md`, 테스트 계획 L3·dev·redesign
- 기준 자료: 시안 A `concept_a_wood_leather.png`(NAS), 전환 전 캡처 `925cc8c…/ui-kit-skin-surfaces/fix3-390x844/`(NAS)

## 검수 계획

| 영역 | 화면 | 통과 기준 |
|---|---|---|
| 기능 | `check.py --capture` 전체(아키텍처, 묶음 해시, contract probe, ui standard probe, ui_kit probe 47항목, journey 10 시나리오, accounts probe 2, scroll·camp·navigation probe), 단위 테스트, `bundle.py verify`, `ui_gate.py` 8항목 | 모두 통과, 시나리오 status 전부 passed |
| 홈 | hero, map, world, 재화 칩, 주 버튼 | 시안 A와 재질·색·구도 비교. 9분할 이음매·줄무늬·모서리 왜곡 없음, 버튼 글자가 플랭크 안 |
| 타이틀 | loading, ready, 오류(Retry) | 전환 전 캡처와 비교. 핵심 정보 노출, 터치 영역 48dp 이상 |
| 모달 | 설정(ko), 언어·접근성(큰 글자 ko), 우편함(스크롤·만료), 지원코드, 계정(캠프), 상점 오퍼·구매 대기·복원, 순위 5상태(empty, closed, failed, offline, unranked)+around, 튜토리얼 | 제목·본문·버튼이 프레임 띠 안, 팝업 프레임 세로 타일 이음매, 패널 늘림 왜곡, 칩 판 위 글자 가독성(어두운 칩 위 흰 글자, 크림 판 위 청록 글자) |
| 보상 | reward, impact, settle | 코인 아이콘이 그린 화풍, 3단계 유지 |
| 큰 글자 | large-text-ko | 글자가 스킨 밖으로 나가지 않음 |
| 아이콘 | 7종 콘택트 시트 | 화풍 일치 |
| 상시 모션 | ui-kit.json ambient 4항목 | idle_pulse·shine 동작, reduced_motion 정지 |

## 실행 명령과 결과

모든 명령은 격리 worktree 루트에서 실행했다.

| 순서 | 명령 | 결과 |
|---|---|---|
| 1 | `godot --headless --path godot --import --quit-after 2` | 종료 0 (08:29:46–08:30:10 UTC) |
| 2 | `python3 tools/check.py --capture --size 390x844 --out build/qa-round-1` | **실패**(종료 1, 15초). ui_kit_probe 단계에서 `ERROR: Resource file not found: res://addons/seorilabs_game/skins/soft_adventure/icon_coin.svg` (`tests/common/ui_kit_probe.gd:152`). check.py는 ERROR 줄을 실패로 보고 journey 이후 단계를 실행하지 않아 automated.json·캡처가 생성되지 않음. 통과 단계: architecture, bundle verify, contract probe, ui standard probe 87/0, ui_kit probe 47 checks 0 failed(출력은 통과지만 ERROR 로그 동반) |
| 3 | journey·accounts·account_services·scroll·camp·navigation probe를 check.py와 같은 인자로 단독 실행(각 180초 제한, 08:31:54–08:32:30 UTC) | 6개 모두 종료 0, ERROR 0. journey 23초, 나머지 0~6초. 180초 초과 없음 |
| 4 | `python3 -m unittest discover -s tools -p 'test_*.py'` | 19 tests OK (`test_ui_kit.py`의 텍스처 참조 검사는 PNG만 확인하므로 probe의 svg 참조를 잡지 못한다) |
| 5 | `python3 tools/bundle.py verify` | ok, version 1.1.0, files 85, source commit `30999e7…`(잠금 커밋) |
| 6 | `ui_gate.py --root . --project godot` | 8항목 PASS (display_font, painted_skin, popup_motion, button_sfx, reward_ceremony, particles, hud_layers, currency_chip) |

ui-kit.json: 48항목 passed, 0 failed(ambient 4항목 포함: idle pulse moves, shine band exists, reduced idle pulse stays still, reduced shine band absent). 설계의 "47항목"보다 1개 많다.

## 기능 결과

| 시나리오 | status | featureIds |
|---|---|---|
| startup-gates | passed | startup, operations |
| first-play-reward-and-replay | passed | startup, tutorial, account_save, observability |
| settings-support-language-restart | passed | settings_support, account_save, observability, ui_support_entry, ui_analytics_opt_out, ui_locale_offline, ui_navigation |
| inbox-read-claim-scroll | passed | inbox, account_save, observability |
| commerce-pending-reconcile-restore | passed | commerce, ui_navigation |
| leaderboard-states-and-pagination | passed | ui_leaderboard |
| shared-version-product-hooks | passed | startup, ui_navigation |
| save-corruption-and-guide-recovery | passed | account_save, tutorial |
| server-claim-batches-and-failure | passed | inbox, operations, observability |
| late-server-response-preserves-navigation | passed | inbox, ui_navigation |

camp probe journey, navigation probe journey, scroll-boundary journey: 모두 생성되고 ERROR 없음. 단, 위 결과는 check.py가 실패한 뒤 단계별로 단독 실행해 얻은 것이고, check.py 한 번으로는 automated.json이 나오지 않는다(결함 D-1).

## UX 결과

| 화면 | 시안/전환 전과 비교 | 결과 |
|---|---|---|
| 홈 hero | 시안 A와 같은 구성: 가죽 알약 칩+금 코인, 자작나무 플랭크 Inbox/Rank, 금빛 주 버튼, 하단 플랭크 3개. 칩 위 숫자는 흰색으로 읽힘. 목적지 띠는 어두운 가죽 칩 위 밝은 글자+외곽선. 메뉴(≡)는 둥근 놋쇠 단추 대신 작은 플랭크(runtime-review에 수용 기록 있음) | 통과. 이음매·줄무늬 없음 |
| 홈 map/world | 패널 안 지도·마을은 전환 전과 같음. map의 "13 Locked"가 "12 Lost lighthouse" 플랭크와 겹치고 "Lock/ed"로 줄바꿈되는 것은 전환 전 캡처에도 동일 | 통과(겹침은 기존 문제) |
| 타이틀 loading/ready/오류 | 주 버튼이 금빛 플랭크로 바뀜. 보이는 플랭크 높이는 약 34px로 전환 전(약 42px)보다 낮지만 텍스처 상하 투명 여백 6px씩을 더하면 컨트롤 높이는 48 유지. 우상단 Settings 플랭크는 보이는 크기 82x30px로 글자가 좌우 리벳에 붙는다 | 통과(Settings 글자 여백은 관찰, 결함 아님) |
| 설정(ko)·접근성 큰 글자 ko | 프레임: 가죽 띠+놋쇠 모서리, 내부 나무판 세로 타일. 타일 이음매는 나무판 결 사이로 들어가 눈에 띄지 않음. 토글 행은 플랭크 안에 들어가고 큰 글자에서도 넘침 없음. 제목·닫기 버튼이 프레임 띠 안에 있음 | 통과 |
| 우편함 scroll/expired | 카드 글자·버튼이 프레임 안. Received(비활성)와 Expired(비활성) 플랭크는 회색 플랭크로 구분됨 | 통과 |
| 지원코드 | 코드 상자가 높이 42px 패널로 그려지면서 패널 텍스처(최소 72px, margins 34/36)가 눌려 구리색 테두리만 남고, 청록 글자 "SK - 7H2K9X4Q"가 왼쪽 테두리에 걸치고 위아래가 테두리와 겹침. 전환 전에는 크림 판 위 청록 글자로 선명 | **실패**(D-2) |
| 상점 오퍼·구매 대기·복원 | 이미지·본문·가격 버튼이 프레임 안. 가격 버튼 금빛 플랭크 | 통과 |
| 순위 empty/closed/failed/offline/unranked/around | 빈 상태·안내문은 통과. 점수 행(closed, offline, around, My best record)은 48px 행에 패널 텍스처가 눌려 구리색 테두리만 보이고, 청록 글자가 테두리 위에 겹쳐 글자 윗부분이 잘린다. 내 줄(ChipPanel)은 어두운 가죽 위에 어두운 청록 글자라 읽히지 않는다. 전환 전은 크림 행+청록 글자, 내 줄은 청록 바탕+회색 글자(전환 전에도 내 줄 대비는 낮았음) | **실패**(D-3) |
| 튜토리얼 | 제목 "Gather three stars"가 두 줄로 줄바꿈(전환 전 한 줄). 프레임 안에 있고 잘리지 않음. 별 카드 패널은 충분히 커서 정상 | 통과(관찰) |
| 보상 reward/impact/settle | 코인 아이콘이 놋쇠 별 코인(그린)으로 바뀌고 Reward→impact→settle 3단계 유지, 파티클 표시 | 통과 |
| 캠프 568x320 title | 하단 탭 6개에서 아이콘이 플랭크 위쪽을 차지하고 글자(계정, 상점, 우편함, 광고 보상, 운영, 설정)가 플랭크 아래 테두리에 걸쳐 절반쯤 바깥으로 나간다. 우편함은 아이콘과 글자가 겹친다. 전환 전은 아이콘+글자가 플랭크 안에 있었음 | **실패**(D-4) |
| 캠프 settings/account | 가로 프레임 안에 토글·버튼·본문 정상 | 통과 |
| 내비게이션 320x568 | 모달 제목 "Settings"가 "Setting/s", "Purchases"가 "Purcha/ses"로 단어 중간에서 줄바꿈. 전환 전 캡처는 한 줄. 두꺼운 프레임 띠로 제목 폭이 줄어든 결과 | **실패**(D-5, 이번 회차 크기 390x844 밖이지만 AC-3의 320x568 범위) |
| scroll-boundary | 테마 없는 회색 화면. 전환 전 캡처와 동일 | 해당 없음(기존) |
| 아이콘 7종 | coin, account, shop, inbox, ads, operations, settings 모두 나무·놋쇠·가죽 화풍으로 일치 | 통과 |
| 텍스처 원본 8장 | primary/secondary 160x90, panel 256x256, popup_frame 320x320, chip 96x54. 설계의 512x256 등보다 작지만 캡처 상 흐림 없음. 모서리 장식은 margins 안 | 통과(관찰) |

## 결함

- D-1 (기능, 차단): 새 체크아웃에서 `python3 tools/check.py --capture`가 ui_kit_probe 단계에서 실패한다. `godot/tests/common/ui_kit_probe.gd:152`가 삭제된 `icon_coin.svg`를 load해 `ERROR: Resource file not found`가 찍히고 check.py가 ERROR 줄을 실패로 처리한다. probe 자체는 47 checks 0 failed를 찍지만 journey·캡처·automated.json이 만들어지지 않는다. 구현자 환경의 `.godot` import 캐시에 옛 svg가 남아 있어 통과한 것으로 보인다(원본 저장소에 `icon_coin.svg.import` 잔존 확인). `npm test`도 같은 경로라 CI에서 실패한다. `test_ui_kit.py`는 skin.json 참조만 보므로 잡지 못한다.
- D-2 (UX): 지원코드 화면의 코드 상자가 눌린 패널 텍스처(테두리만) 위에 청록 글자를 그려 코드 첫 글자가 테두리에 겹치고 가독성이 떨어진다.
- D-3 (UX): 순위 화면의 점수 행(`_rank_row`, PanelContainer 기본 panel, `custom_minimum_size.y = 48`)이 panel 텍스처 최소 72px보다 낮아 구리색 테두리만 남고, 청록 글자가 테두리 위에서 잘린다. 내 줄(ChipPanel)은 어두운 가죽 위 어두운 청록 글자로 읽히지 않는다. closed, offline, around, My best record 모두 동일.
- D-4 (UX): 캠프 568x320 하단 탭 6개의 글자가 플랭크 아래 테두리 밖으로 나가고 우편함은 아이콘과 글자가 겹친다(`camp_home.gd` `_button`의 expand_icon + png 아이콘).
- D-5 (UX, 320x568): 모달 제목이 단어 중간에서 줄바꿈된다("Setting/s", "Purcha/ses"). 390x844에서는 "Gather three stars"가 두 줄로만 바뀌고 잘리지 않는다.
- 기존 문제(전환 전부터): 홈 map의 "13 Locked" 라벨이 "12 Lost lighthouse"와 겹치고 "Lock/ed"로 줄바꿈. 순위 내 줄의 낮은 대비(전환 전 청록 바탕+회색 글자). scroll-boundary 캡처는 테마 없는 회색 화면.

## 판정

fail. check.py가 새 체크아웃에서 svg 참조로 중단되어 자동 증거(automated.json)가 나오지 않고(D-1), 패널 텍스처가 48px 이하 행에서 눌려 순위·지원코드 글자가 테두리와 겹치며(D-2, D-3), 캠프 하단 탭 글자가 플랭크 밖으로 나간다(D-4). journey 10 시나리오, ui-kit 48항목, 단위 테스트, bundle verify, ui_gate 8항목은 단독 실행으로 모두 통과했고 홈은 시안 A와 재질·색·구도가 일치한다.
