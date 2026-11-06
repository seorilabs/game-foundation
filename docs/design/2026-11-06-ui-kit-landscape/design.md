# 설계: ui_kit 가로 화면 보정과 제품 스킨 폴더 hook

- 설계 ID·버전·원본 커밋: 2026-11-06-ui-kit-landscape v2, 기준 main `8c9a309b7cb090ad7c03595e7737dd27c81c2bbd`(v1 #13 병합 `bc21978`, v2는 main `f7cc20f` 위)
- 상태: 승인(2026-11-06 사용자, starter-template-game 검수 추가 회차 승인에 "skin_dir hook도 같은 foundation PR에 포함"으로 범위를 정함)
- 관련: starter-template-game 설계 `2026-11-06-ui-kit-1-1-0`의 독립 검수 1·2회차(후보 `9217328`, fail), slot-defense #15, [ui_kit 설계](../2026-11-05-ui-kit/design.md)

## 목적·범위·근거

starter-template-game(가로 전용, `landscape = true`)에 1.1.0 묶음을 설치하고 568x320과 1024x600에서 독립 검수를 돌리자 공통 묶음의 가로 화면 결함 세 가지가 나왔다. ui_kit 검수(#11)는 가로를 844x390 한 크기에서만 봐서 잡지 못했다.

| 결함 | 원인 | 보정 |
|---|---|---|
| 보상 연출의 "coins" 라벨이 화면 아래로 잘림(568x320, 1024x600) | `_draw_result`가 가로에 초점 y 0.86을 주고 `reward_ceremony.present`가 Stage `offset_top`을 0.72H로 내려 Stage 높이 0.28H가 아이콘 64+숫자+라벨 열보다 작다 | `present`가 열의 최소 높이를 재서 `offset_top`을 화면 안으로 당긴다 |
| 높이 320에서 모달 내용이 프레임 하단 테두리와 겹침 | `_clear`의 가로 content 여백이 16px인데 프레임 그림(popup_frame 9분할)의 안쪽 여백은 backing 12 + content 22 = 34px | 가로 여백을 `max(16·배율, 12 + 프레임 content 여백)`으로 둔다 |
| 가로 캠프 홈의 재화가 평문 "★ n" 라벨 | `camp_home.gd`가 `_text`로 그린다 | `_currency_chip`으로 칩을 두고 숫자 글자만 배율에 맞춘다 |

같은 PR에 제품 스킨 폴더 hook `skin_dir`를 더한다. `outgame_main.gd`가 테마와 코인 아이콘을 `ThemeBuilder.DEFAULT_SKIN`으로 고정해 제품이 다른 스킨(slot-defense VD-B)을 쓰려면 묶음 파일을 고쳐야 했고, 그러면 해시 검증이 깨진다. 계약 버전은 1.1.0 그대로다(하위 호환, 기본값이 soft_adventure).

제외: 세로 화면 배치, 캠프 그림(`camp.svg`)과 캠프 아이콘 경로(캠프 구성은 soft_adventure 전용 합성 화면), 소비 게임 전환.

## v2 추가(2026-11-06, starter 검수 4회차 fail에 따른 보정)

starter-template-game에 #13 묶음을 설치해 돌린 독립 검수 4회차(568x320)가 두 가지 겹침으로 fail했다(5회차 1024x600, 6회차 568x320은 pass). 사용자가 "foundation에서 둘 다 고치고 검수 3회 재실행"을 승인했다.

| 결함 | 원인 | 보정 |
|---|---|---|
| 568x320 결과 화면에서 끌어올린 보상 코인이 Continue 버튼 하단 14~17px와 겹침 | 가로 결과 화면은 버튼이 전폭이라 빈 띠가 없다 | `_draw_result`가 가로에서 내용을 왼쪽 버튼 열(비율 3)과 오른쪽 연출 열(비율 2)로 나누고 연출 초점을 오른쪽 열 중심(내용 폭 0.8, 높이 0.55)에 둔다. 1024x600에서 "coins" 외곽선이 프레임 테두리에 5px 올라타던 것도 같이 사라지며, 연출 클램프 여유는 16→48px |
| 플랫폼 캠프 홈에서 긴 재화 문자열("★ 10  🎟 2")로 넓어진 칩이 두 줄 헤드라인과 겹침 | 칩이 내용 크기라 설계 자리 370px(배율 적용)를 넘는다 | `camp_home._layout`이 다음 프레임에 칩 최소 폭을 재서 자리 폭에 맞게 `scale`을 줄인다 |

검사: 참조 여정이 가로일 때 연출 열이 `reward_continue`와 겹치지 않고 프레임 안쪽 사각형 안인지, `camp_probe`가 긴 재화 문자열을 주고 칩 폭이 자리 폭 이하인지 본다. 테스트 계획은 v1과 같다(L3 dev, redesign false).

## 사용자 흐름·화면 상태

흐름은 바뀌지 않는다. 가로 결과 화면에서 보상 열이 Continue 버튼 아래 띠 안에 온전히 보이고, 가로 모달(설정·우편·지원·계정)의 내용이 프레임 테두리 안에 머물며, 캠프 홈 왼쪽의 재화가 칩으로 뜬다. 큰 글자(150%)에서는 칩 숫자가 2px 커진다.

## 구조·책임·의존성

- `ui_kit/reward_ceremony.gd` `present`: Stage 위치 보정만 추가. 단계·타이밍·시그널은 그대로.
- `flow/outgame_main.gd`: `_clear` 가로 여백, `skin_dir` 변수와 세 곳의 경로 치환.
- `ui/camp_home.gd`: 재화 칩 배치. `_placements`에 `chip` 항목을 두고 `_layout`이 위치와 숫자 글자만 맞춘다.
- 검사: `tests/common/ui_kit_probe.gd`(초점 0.86에서 열이 화면 안), `tests/reference/camp_probe.gd`(칩 존재, 설정 모달 내용이 프레임 안쪽 사각형 안). `check.py`가 camp_probe를 568x320으로 돌린다.

## 데이터·인터페이스·실패 처리

- `skin_dir`에 `theme.tres`가 없으면 `ThemeBuilder.build`로 즉석 조립한다. `skin.json`이 없으면 `load_skin`이 빈 사전을 돌려주고 기본 테마로 뜬다.
- 저장 형식·묶음 파일 목록·계약 버전은 바뀌지 않는다. 묶음 해시는 바뀌므로 소비 게임은 새 묶음을 설치한다.

## 품질 요구사항

568x320, 844x390, 1024x600에서 결과 화면 보상 열과 모달 내용이 화면과 프레임 안에 있고, 390x844 세로 캡처가 #11 결과와 같다.

## 대안·주요 결정

| 대안 | 결정 |
|---|---|
| `_draw_result`의 초점 값만 0.86 → 0.75로 낮춤 | 기각. 높이마다 다시 어긋난다. 연출 쪽에서 열 높이를 재는 것이 모든 크기에 맞다 |
| 가로 여백을 상수 34로 고정 | 기각. 제품 스킨의 프레임 여백이 다를 수 있어 스타일박스에서 읽는다 |
| 캠프 홈 재화를 `_text` 그대로 두고 칩은 세로만 | 기각. 필수 재료 게이트의 "재화 칩"이 가로 템플릿에서 실제로 보이지 않는다 |

## 인수조건·테스트·검수

| 조건 ID | 관찰할 동작·통과 기준 | 테스트 방법·환경 | 격리 데이터 | 기대 결과 | 증거 |
|---|---|---|---|---|---|
| AC-1 | 초점 0.86으로 `present`해도 연출 열이 화면 안에 있다 | `ui_kit_probe` | — | PASS | ui-kit.json |
| AC-2 | 568x320 캠프 설정 모달의 내용이 프레임 안쪽 사각형 안에 있다 | `camp_probe` 568x320 | 임시 저장 | PASS, `camp-settings.png` | e2e 보고 |
| AC-3 | 캠프 홈에 `coins` 칩(Row/Icon, Row/Value)이 있다 | `camp_probe` | 임시 저장 | PASS, `camp-title.png` | e2e 보고 |
| AC-4 | `skin_dir` 기본값으로 기존 캡처(390x844 여정)가 바뀌지 않고, `npm test`와 `test_ui_kit.py`가 통과한다 | `npm test`, `check.py --capture` 390x844·568x320·844x390 | 임시 저장 | 통과 | CI, 캡처 |
| AC-5 | starter-template-game에 새 묶음을 설치해 568x320·1024x600 독립 검수 3회가 통과한다 | starter 저장소 설계 AC-7 | — | pass 3회 | starter PR |

- TDD: `ui_kit_probe`와 `camp_probe`의 새 단계는 보정 전 FAIL(열 하단 y>320, 내용 사각형이 프레임 밖, 칩 없음), 보정 후 PASS.
- 테스트 계획: [test-plan.json](test-plan.json). L3(공통 묶음 `addons/**` 회귀 경로, CI 전체 실행), 개발 환경, redesign false(새 화면·개편이 아닌 배치 보정이며 시각 판정은 소비 저장소의 독립 검수 3회가 맡는다), 출시 없음.

## 적용·운영·되돌리기

PR 병합 → 잠금 `source.commit`을 main 커밋으로 맞추는 후속 PR(#12 방식) → starter가 `pack --commit <main>`으로 설치. 되돌리기는 PR revert.

## 승인·추적

승인 근거는 starter-template-game 검수 추가 회차 승인(2026-11-06)이다. 이 문서와 `test-plan.json`을 같은 커밋에 둔다.
