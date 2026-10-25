# Game Foundation

Godot 4.7.2의 공통 UI와 동작 계약 원본, 이를 실행하는 소프트 어드벤처 레퍼런스다. 코드 MIT, 직접 만든 예제 그림 CC0, 글꼴 OFL이다.

```sh
npm start
npm test
python3 tools/check.py --capture --size 320x568 --out build/review-320
```

Python 3.11 이상과 Godot이 설치돼 있으면 npm 의존성 설치, 네트워크와 개인 스킬 없이 실행한다. `npm test`는 실제 입력, 저장과 복원, 지원코드, 분석, 결제 상태와 순위 계약을 확인한다. 검증은 추적 소스를 바꾸지 않는다. 로컬 기본 실행에는 실제 서비스가 없으며 상점과 순위는 숨긴다. 오류와 지연 응답을 직접 살펴볼 때만 `npm start -- --scenarios`를 사용한다. 대역은 출시 export에서 제외한다.

공통 파일은 addons의 원본에서 수정한다. 제품 이름, 그림과 플레이는 reference에서 주입하며 공통 코드는 reference를 참조하지 않는다. 세 홈은 `npm start -- -- --product skyway`, `npm start -- -- --product map`, `npm start -- -- --product windharbor`로 확인한다. `stage_factory`, `launch_game`, `score_provider`와 서비스 주입을 유지한다.

```sh
python3 tools/bundle.py pack --commit <검수한40자리SHA> --out /absolute/common.tar.gz
python3 /path/to/new-game/tools/bundle.py --root /path/to/new-game install --bundle /absolute/common.tar.gz
```

묶음은 계약 1.0.0, 원본 커밋, 파일 목록과 SHA-256, SDK v1.0.0 출처를 기록한다. 검수 결과는 [설계](docs/design/2026-10-25-game-foundation/design.md)와 QA 요약을 참조한다. 파일이 바뀌거나 추가된 기존 묶음은 갱신을 거부한다. 별도 버전 태그는 만들지 않는다. 생성용 저장소는 비공개 starter-template-game이다.

현재 범위는 개발 환경 검수와 PR 병합까지다. 기기, 실제 결제, 운영 서버, 마켓 출시 검증을 포함하지 않는다.
