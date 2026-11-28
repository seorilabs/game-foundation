# 테스트실 검사의 열림 대기 수정

- 설계 ID·기준 커밋: `2026-11-28-dev-probe-open-wait`, 기준 main `7cf1fc02a3d4c84b0b695ee9f024067f3a457696`
- 상태: 승인. 2026-11-28 사용자가 말랑(seorilabs/malang) 작업 중 "원본 수정 후 1.3.x 설치"를 골랐다. 원 승인은 malang `docs/design/2026-11-28-malang-story/approval.md`의 작업 범위이고, 이 수정은 그 대화에서 따로 받은 선택이다.
- 테스트 계획: [test-plan.json](test-plan.json). L1, 개발 환경, release null, 기기 사용 없음

## 문제

`tests/common/dev_probe.gd`는 테스트실을 연 뒤 4프레임만 기다리고 "결과 문구가 바뀌어도 버튼 목록이 움직이지 않는다"의 기준 위치를 잰다. 테스트실 창은 `Juice.pop_in`(0.18초, 끝에서 살짝 되튐)으로 열리고 크기에 따라 창 위치도 바뀐다. 프레임이 빠른 실행에서는 4프레임이 열림 도중이라 기준이 1px쯤 어긋나 검사가 실패한다.

말랑의 비공개 저장소 CI(자체 러너 `seorilabs-x64`)에서 매번 실패했다. 진단 실행에서 기준을 잴 때 창이 (11.3, 7.5) 크기 367.4×829.1이었고, 열림이 끝난 뒤 (12, 9) 366×826이 됐다. GitHub 호스트 러너에서 도는 이 저장소와 starter-template-game은 프레임이 느려 통과해 왔다. 제품 동작과는 무관한 시험 타이밍 결함이다.

## 수정

창의 크기가 1이고 투명도가 1이 될 때까지(실제 시간 최대 5초) 기다린 뒤 기준을 잰다. 5초 안에 끝나지 않으면 "open animation finishes before the layout checks" 검사가 그 원인을 따로 알린다. 다른 검사와 공통 코드, 제품 화면은 바꾸지 않는다.

## 인수조건

| 조건 ID | 통과 기준 | 방법 | 증거 |
|---|---|---|---|
| AC-1 | 수정 전 `--fixed-fps 30`, `45`, `60`에서 "button list does not move when the result changes"가 실패한다(RED) | `godot --headless --fixed-fps N --path godot --script res://tests/common/dev_probe.gd` | 실행 기록 |
| AC-2 | 수정 뒤 같은 명령과 일반 실행에서 27개(열림 완료 검사 포함) 모두 통과한다(GREEN) | 같은 명령 | 실행 기록 |
| AC-3 | `npm test`와 묶음 해시 검증이 통과한다 | `npm test`, `python3 tools/bundle.py verify` | 실행 기록 |

## 적용

잠금은 이 PR의 코드 커밋을 가리킨다. 병합 뒤 잠금 원본 커밋을 main 병합 커밋으로 맞추는 후속 PR을 낸다. 말랑은 그 커밋의 묶음(계약 1.3.0)을 설치한다.
