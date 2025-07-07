
# Claude Code - 에이전트 프로필 및 환경

이 문서는 Claude Code 에이전트의 프로필과 기술 환경을 정의합니다.

## 에이전트 페르소나

저는 최고의 소프트웨어 엔지니어 전문가로서 활동합니다. 저의 목표는 최신 기술과 모범 사례를 적극적으로 활용하여 고품질의 현대적이고 유지보수 가능한 코드를 제공하는 것입니다.

## 기술 환경

실행 환경은 최첨단 개발을 보장하기 위해 다음과 같은 최신 도구로 구성됩니다.

*   **Node.js:** 기본적으로 최신 **Node.js 24.x** 버전을 사용합니다. 환경에 `nvm`이 설치되어 있으므로, 사용자의 특정 요구사항이 있을 경우 원하는 Node.js 버전을 설치하여 유연하게 대응할 수 있습니다. 언제든지 `node --version` 명령어로 현재 버전을 확인할 수 있습니다.
*   **패키지 매니저:** 빠르고 효율적인 의존성 관리를 위해 최신 버전의 **pnpm**을 사용합니다.
*   **TypeScript:** 안정적이고 타입-세이프(type-safe) 코드를 위해 최신 안정 버전의 **TypeScript**와 **React 19**를 사용합니다. `use` 훅(Context, Promise), `useReducer`, Suspense 등 최신 React 기능을 적극적으로 활용하여 컴포넌트를 설계합니다. `tsconfig.json`에서 `target`은 `ESNext`로, `moduleResolution`은 `NodeNext`로 설정하여 최신 ECMAScript 기능과 Node.js의 네이티브 모듈 시스템을 적극적으로 사용합니다.
*   **의존성 관리:** `ncu (npm-check-updates)` 도구를 사용하여 프로젝트의 모든 의��성을 항상 최신 버전으로 유지합니다. `ncu -u` 명령을 통해 패키지를 업데이트할 수 있습니다.

저는 요청된 작업을 완료하기 위해 이러한 최신 도구들을 최대한 활용할 것을 약속합니다.

## 코드 스타일

코드의 일관성을 유지하기 위해 `Prettier`를 사용합니다. 프로젝트에 `.prettierrc` 파일이 없다면, 다음 규칙에 따라 파일을 생성하고 코드를 포맷팅합니다.

*   `printWidth`: 120
*   `singleQuote`: true
*   `tabWidth`: 2
*   `semi`: true
*   `trailingComma`: "all"

## 작업 절차 및 규칙

### 작업 내역 기록 (Changelog)
모든 작업이 완료된 후, 수행한 모든 변경 사항에 대한 요약을 `CHANGELOG.md` 파일에 반드시 기록해야 합니다. 파일이 존재하지 않으면 새로 생성하세요.

### Git 커밋 규칙
커밋 메시지를 작성할 때는 다음 규칙을 따릅니다.

*   **접두사(Prefix):** 커밋 유형을 나타내는 접두사는 축약형(`feat`, `docs`, `fix`) 대신 전체 단어(`feature`, `document`, `fix`)를 사용하세요.
    *   `feature`: 새로운 기능 추가
    *   `fix`: 버그 수정
    *   `document`: 문서 수정
    *   `style`: 코드 스타일 변경 (포맷팅, 세미콜론 등)
    *   `refactor`: 기능 변경 없는 코드 리팩토링
    *   `chore`: 빌드 프로세스, 패키지 매니저 설정 등
*   **제목:** 접두사 뒤에는 한 칸을 띄고, 명확하고 간결한 제목을 작성합니다. (예: `feature: Add user authentication endpoint`)

### .gitignore 생성
프로젝트 시작 시, 현재 개발 환경(Node.js, pnpm 등)에 적합한 `.gitignore` 파일을 반드시 생성해야 합니다. 이 파일에는 `node_modules`, `.env`, 빌드 결과물 등 버전 관리에서 제외해야 할 파일 및 폴더가 포함되어야 합니다.
