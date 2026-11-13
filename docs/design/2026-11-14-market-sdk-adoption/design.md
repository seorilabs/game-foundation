# 출시 마켓별 서비스 채택 검사

My Little Parasite의 [승인된 잔여 설계](https://github.com/seorilabs/my-little-parasite/blob/ac95d68d7995bc602fcc310e160edff7c8fd1e0f/docs/design/2026-11-13-launch-completion/design.md)는 Android 배너·구매 미채택과 별도 iOS 범위를 실제 채택대로 검사하도록 공통 원본 수정을 승인했다. 사용자 응답은 “승인”이다. 새 SDK 계약 태그나 운영 서버 배포는 하지 않는다.

선택 `marketServices`에 채택 마켓별 auth/payments/ads의 boolean 전체를 기록한다. 전역 노출은 한 마켓 이상의 채택과 일치해야 하며 불완전한 표·문자열 false·전역 노출을 숨기는 표를 거부한다. 이 표가 없는 기존 소비자는 전역 규칙을 유지한다. `--market`을 지정하면 해당 출시 마켓의 SDK 보고서를 요구하고, 생략하면 기존처럼 모든 채택 마켓을 요구한다. 다른 마켓의 성공을 조작하거나 미검증을 면제하지 않는다.

동시에 설정 조회가 실제 통신 성공인지를 `networkOk`로 구분하는 Platform SDK 소스를 고정한다. v1.1.0의 기존 fail-open 동작과 API 계약은 유지하며, 수정된 bytes는 공개 Git 커밋과 파일별 해시로 재현한다. 원본 archive hash는 `baseArchiveSha256`으로 표시해 수정 bytes의 archive 해시로 오해하지 않게 한다. 제품별 공통 파일 직접 수정을 대신하는 원본 변경이다.

변경 전 마켓 분리·boolean 검사 실패를 확인했고, Android 광고/iOS 미채택·잘못된 표·한 마켓 출시 범위 및 기존 증적 검사 28개를 실행한다. 실제 기기와 공급자 성공이 아닌 검사기 fixture 테스트다. 제품 L3 및 실제 native SDK 증적은 제품에서 별도로 수행한다. 버전 영향은 하위 호환 선택 입력과 SDK 관찰 필드 추가이며 계약1.1.0을 유지한다.
