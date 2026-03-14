<p align="center">
  <img width="120" alt="픽카챠 앱 로고" src="https://github.com/user-attachments/assets/7eca77ef-e2af-4162-9878-47af0a0b1a0b" />
</p>

<h1 align="center">픽카챠</h1>

<p align="center">
  <strong>Apple Watch 제스처 기반 선택형 인터랙티브 콘텐츠 플랫폼</strong><br/>
  Apple Developer Academy @ POSTECH · 6인 팀 프로젝트
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17.0+-black?logo=apple" />
  <img src="https://img.shields.io/badge/watchOS-10.0+-black?logo=apple" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?logo=swift" />
  <img src="https://img.shields.io/badge/SwiftUI-blue" />
  <img src="https://img.shields.io/badge/SwiftData-purple" />
</p>

</br>

## 스크린샷

<p align="center">
  <img width="18%"src="https://github.com/user-attachments/assets/f20cfa5d-359b-4b76-bc0b-29a54a5154d7" />
  <img width="18%"src="https://github.com/user-attachments/assets/1c599a9c-b706-459f-b400-78ea40b0beeb" />
  <img width="18%"src="https://github.com/user-attachments/assets/086e98bd-54de-4271-88e3-726f58c2be94" />
  <img width="18%"src="https://github.com/user-attachments/assets/96ce8cb3-c997-48c3-b560-7a8875e03233" />
  <img width="18%"src="https://github.com/user-attachments/assets/db77c06c-32e3-4be0-b013-4ef58b7e7b11" />
</p>

</br>

## 소개

사용자 선택에 따라 분기하는 **선택형 스토리**와 이상형 월드컵 방식의 **토너먼트** 콘텐츠를 Apple Watch 손목 제스처로 즐길 수 있는 앱입니다. Core Motion 기반 제스처로 A/B 선택을 처리하고, WatchConnectivity로 iPhone-Watch 간 상태를 실시간으로 동기화합니다.

**주요 기능**

- 📖 **선택형 스토리** — 사용자의 선택 경로에 따라 결말이 달라지는 분기형 스토리
- 🏆 **토너먼트** — 이상형 월드컵 방식의 A/B 대결 콘텐츠
- ⌚ **Apple Watch 연동** — 손목 제스처(Core Motion)로 A/B 선택, 다시 듣기 등 Watch 조작
- 🔊 **TTS** — 스토리 및 토너먼트 내용 음성 지원

</br>

## 담당 역할

6인 팀(기획 공동, 디자인 3명, 개발 3명)에서 **개발 리드 & iOS 개발**을 담당했습니다.

- 개발 태스크 분배 및 일정 관리
- 디자인 파트와의 커뮤니케이션 및 디자인 QA
- 데이터 아키텍처 설계 및 SwiftData 모델 구현
- 홈/인트로 화면 개발, 재사용 컴포넌트 제작

</br>

## 주요 기여

### 1. 기획 변경에 유연한 스토리 분기 구조 설계

초기 기획은 완전 이진 트리였습니다. `@Relationship`으로 노드 간 직접 연결을 시도했는데, 개발 중 두 가지 문제가 생겼습니다.

첫째, 노드가 서로를 양방향 참조하면서 Circular reference 에러가 발생했습니다. 둘째, 기획이 바뀌면서 여러 경로가 하나의 엔딩으로 합류하는 구조가 됐는데, 직접 연결로는 이를 깔끔하게 표현하기 어려웠습니다.

**ID 참조 방식**으로 전환했습니다.

```swift
// 변경 전 — 직접 연결
@Relationship var nextNode: StoryNode?

// 변경 후 — ID 참조
var nextNodeID: String?
// 실행 시 Repository.find(by: nextNodeID)
```

노드가 다음 노드의 ID만 저장하고, 실행 시점에 Repository에서 조회하는 구조로 바꾸니 Circular reference 문제가 해결됐고, 여러 경로가 같은 엔딩을 가리키는 구조도 자연스럽게 처리됐습니다.

---

### 2. WatchConnectivity 통신 구조 설계

iPhone이 콘텐츠 상태를 Watch로 보내고, Watch는 사용자 이벤트(선택, 다시 듣기)를 iPhone으로 보내는 **역할 분리 구조**로 설계했습니다. 소켓 통신의 송수신 분리 개념을 참고했습니다. 구현은 팀원이 담당했습니다.

---

### 3. 재사용 컴포넌트 선제 개발

팀원들이 기능 개발에 집중할 수 있도록 공통 컴포넌트를 먼저 만들어뒀습니다.

- 카드 캐러셀 — 드래그 제스처 + 중앙 확대 애니메이션
- 커스텀 NavigationBar, TagBadge, PageIndicator, OrangeButton

</br>

## 아키텍처

```
Kartrider/
├── Models/
│   ├── Story/             # 스토리 노드, 엔딩 모델 (SwiftData)
│   ├── Tournament/        # 토너먼트 후보, 결과 모델 (SwiftData)
│   └── PlayHistory/       # 플레이 기록 모델
├── Repositories/          # SwiftData CRUD 추상화
├── ViewModels/
│   ├── HomeViewModel
│   ├── StoryViewModel
│   └── TournamentViewModel
├── Views/
│   ├── Home/
│   ├── Story/
│   ├── Tournament/
│   └── Components/        # 재사용 컴포넌트
└── WatchApp/
```

**데이터 흐름**

```
SwiftData ──▶ Repository ──▶ ViewModel ──▶ View
                                 │
                                 └──▶ WatchConnectivity ──▶ Apple Watch
                                                               (Core Motion 제스처)
```

</br>

## 기술 스택

| 분류 | 스택 |
|---|---|
| UI | SwiftUI |
| 데이터 | SwiftData |
| Watch | WatchKit, WatchConnectivity, Core Motion |
| 아키텍처 | MVVM |
| 기타 | TTS (AVSpeechSynthesizer), SwiftLint |
