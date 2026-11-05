# ui_kit: 공통 기반의 상용 UI 재료 (계약 1.1.0)

- 상태: agent-config 설계 [2026-11-05 상용 게임 UI 기준 스킬](https://github.com/magicsih/agent-config/blob/main/docs/design/2026-11-05-game-ui-commercial/design.md) v0.1 승인(2026-11-05)에 따른 C 단계 구현
- 테스트 계획: [test-plan.json](test-plan.json) L3, 개발 환경, redesign, 출시 없음

## 왜

공통 기반 자체가 코드로 조립한 `StyleBoxFlat`, 서체 1종, 즉시 뜨는 화면, 무음 버튼의 원형이었다. 이 묶음을 설치한 게임이 같은 모양을 복제해 "게임 엔진으로 만든 앱"처럼 보였다. 기반에 상용 게임의 필수 재료를 넣으면 신규 게임이 설치만으로 재료를 받는다.

## 무엇

`godot/addons/seorilabs_game/ui_kit/`에 코드 3개, 장면 5개, 파티클 2개를 고정한다.

| 파일 | 역할 |
|---|---|
| `theme_builder.gd`, `build_theme.gd` | `skin.json` v2(색, 텍스처 9분할, 서체 역할, 크기, 모션 수치)로 `Theme` 조립. headless 스크립트가 `skins/soft_adventure/theme.tres`를 생성하고 커밋 |
| `juice.gd` | `press_punch`, `pop_in`, `pop_out`, `fly_to`, `count_up`, `float_delta`, `shake`. `reduced_motion`이면 즉시 완료 |
| `ui_sfx.gd` + `sfx/*.wav` | `attach(root)`로 하위 모든 Button의 `button_down`에 탭음을 연결(나중에 추가되는 버튼 포함). `play(kind)` tap/confirm/cancel/error/reward_sting. 효과음은 `tools/gen_ui_sfx.py`로 합성한 CC0 |
| `hud_layers.tscn` | CanvasLayer World 0, Hud 10, Popup 20, Toast 30, Ftue 40, System 50. `toast(text)` |
| `currency_chip.tscn` | 아이콘 + 숫자 + (+) 버튼, `set_value(v, animate)` 카운트업, `fly_target()` |
| `popup_base.tscn` | 딤 + 프레임 + 제목 + 내용 슬롯 + 행동. `open()`/`close()`, `opened`/`closed` |
| `reward_ceremony.tscn` | `present(items, headline, target, counter)` 기대 0.4s → 충격 0.2s(플래시·파티클·스팅) → 정착 0.5s(fly_to·count_up). `skip()`, `finished` |
| `particles/burst.tscn`, `sparkle.tscn` | CPUParticles2D 프리셋 |

스킨 `skins/soft_adventure/`에 벡터 9분할 8장(primary 3상태, secondary 2상태, panel, popup_frame, chip)과 coin 아이콘을 추가했다. 제품이 바꾸는 것은 `skin.json`과 svg뿐이다.

## 기반 연결

- `_apply_settings`: `custom_theme`가 없으면 `theme.tres`를 복제해 언어·큰 글자에 맞춰 역할 서체·크기만 다시 적용한다. HUD 층 루트에도 같은 테마를 준다(CanvasLayer는 Control 테마 상속을 끊는다).
- `_ready`: `UiSfx.attach(self)`, `HudLayers`와 `RewardCeremony`(Popup 층)를 붙인다.
- `_button`: 모든 버튼 `press_punch`, primary는 `PrimaryButton` 변형과 confirm 효과음.
- `_clear`: 모달 화면은 프레임 `pop_in`과 내용 페이드로 들어온다. 내용 좌표는 바꾸지 않아 초점·스크롤 계산이 흔들리지 않는다.
- `_home`/`_compact_home`: 재화 라벨을 `currency_chip`으로 교체. (+)는 상점이 있을 때만 보인다.
- `_draw_result`: 보상 큐 payload의 `amount`로 3단계 연출. 입력을 막지 않고 화면 전환 시 `skip()`.
- 가로 캠프 버튼은 코드 StyleBoxFlat 대신 테마 변형을 쓴다. `home_stage.gd`의 `_box()`는 월드 그림을 그리는 `_draw` 내부 도형이라 UI 스킨 대상이 아니어서 유지했다.

## 계약 1.1.0

- `tools/bundle.py`: 허용 버전 `1.0.0`, `1.1.0`, 생성 `1.1.0`. 1.0.0 위 설치 허용, 역방향 거부.
- `tools/validate_outgame.py`: `uiStandard.version` 두 버전 허용. 잠금 버전과 프로필 버전은 계속 일치해야 한다.
- 소비 게임은 자기 `tools/bundle.py` 사본을 먼저 갱신한 뒤 묶음을 설치한다. 기존 게임 전환은 범위 밖이다.

## 검증

- `tools/test_ui_kit.py`: skin.json v2 참조 무결성, theme.tres 서체 2종 이상·StyleBoxTexture·uid 없음, 킷 파일 목록 고정, 제품 참조 없음, 효과음 5종·라이선스, 모션 기본값과 skin.json 수치 일치.
- `tools/test_bundle.py`: 1.1.0 설치·역방향 거부·미지 버전 거부.
- `godot/tests/common/ui_kit_probe.gd`(check.py가 실행): 테마 재료, 팝업 open/close 시그널·프레임 수, 보상 단계 순서·finished 1회·skip·재시작 가시성, 버튼 효과음 연결 수·종류, 재화 칩 표기, 레이어 순서·토스트, reduced_motion 즉시 완료.
- 여정에 `popup-open`, `reward-impact`, `reward-settle` 캡처와 연출 단계 대기 단계를 추가했다. `shot()`은 기본으로 모션이 끝난 뒤 찍는다.
- 독립 검수 3회: 홈, 모달(설정·상점), 보상 화면을 `python3 tools/check.py --capture --size 390x844`와 `--size 320x568`, 가로 568x320 캡처로 각각 확인한다. 실행 근거와 NAS 위치는 PR에 기록한다.

## 결정

- 효과음은 Kenney CC0 대신 저장소 안에서 합성했다. 외부 사이트가 자동 접근을 거부했고, 합성본은 재현 가능하며 라이선스 의존이 없다. 제품은 같은 이름으로 교체할 수 있다.
- `theme.tres`는 생성 파일이지만 커밋한다. 정적 게이트(`ui_gate.py`)가 테마 리소스의 서체·텍스처 참조를 검사하기 때문이다.
- `shot()`의 기본 대기는 캡처 근거가 모션 중간 프레임으로 흔들리지 않게 한다. 모션 증거가 필요한 캡처만 `settle=false`로 찍는다.
