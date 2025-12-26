# Elixir 학습 튜토리얼

Elixir 기초 문법부터 Phoenix 웹 프레임워크까지 단계별로 학습하는 프로젝트입니다.

**Elixir 1.18 / OTP 27 / Phoenix 1.8 기준 (2025년 1월 업데이트)**

## 프로젝트 구조

```text
elixir-tutorial/
├── 00_introduction.md       # 📚 소개 및 설치
├── cheatsheet.md            # 📚 치트시트
├── 01_basics/               # 💻 기초 문법 예제 + README.md
├── 02_collections/          # 💻 컬렉션 예제 + README.md
├── 03_otp/                  # 💻 OTP 예제 + README.md
├── 04_plug_server/          # 💻 Plug 웹서버 + README.md
├── 05_phoenix/              # 💻 Phoenix 가이드 + README.md
└── 06_testing_debugging/    # 💻 테스트 & 디버깅 + README.md
```

## 사전 준비

### Elixir 설치

**Windows (Chocolatey):**

```bash
choco install elixir
```

**Windows (Scoop):**

```bash
scoop install elixir
```

**macOS:**

```bash
brew install elixir
```

**설치 확인:**

```bash
elixir --version
iex   # Interactive Elixir 실행
```

## 학습 순서

### 📚 문서로 개념 학습

| 순서 | 문서 | 내용 |
|------|------|------|
| 0 | [00_introduction.md](00_introduction.md) | Elixir 소개, 설치, 개발환경 |
| 1 | [01_basics/README.md](01_basics/README.md) | 기초 문법 (타입, 패턴매칭, 함수) |
| 2 | [02_collections/README.md](02_collections/README.md) | 컬렉션, Enum, Stream |
| 3 | [03_otp/README.md](03_otp/README.md) | 프로세스, GenServer, Supervisor |
| 4 | [04_plug_server/README.md](04_plug_server/README.md) | Plug 웹서버 기초 |
| 5 | [05_phoenix/README.md](05_phoenix/README.md) | Phoenix 프레임워크 |
| 6 | [06_testing_debugging/README.md](06_testing_debugging/README.md) | 테스트, 디버깅, 프로파일링 |
| - | [cheatsheet.md](cheatsheet.md) | 빠른 참조용 치트시트 |

### 💻 코드로 실습

| 단계 | 폴더 | 내용 |
|------|------|------|
| 1 | `01_basics/` | 기초 문법 예제 |
| 2 | `02_collections/` | 컬렉션과 Enum/Stream 예제 |
| 3 | `03_otp/` | 프로세스, GenServer, Supervisor 예제 |
| 4 | `04_plug_server/` | Plug 기반 웹서버 (실행 가능) |
| 5 | `05_phoenix/` | Phoenix 코드 예제 |
| 6 | `06_testing_debugging/` | 테스트 및 디버깅 예제 |

## 예제 실행 방법

### 단일 파일 실행

```bash
elixir 01_basics/01_hello_world.exs
```

### Interactive Shell에서 실행

```bash
iex 01_basics/01_hello_world.exs
```

### Plug 웹서버 실행

```bash
cd 04_plug_server
mix deps.get
mix run --no-halt
# http://localhost:4000 접속
```

## 학습 팁

1. **문서 먼저, 코드 다음**: 각 폴더의 README.md로 개념을 이해한 후 예제 코드 실습
2. **직접 타이핑**: 코드를 복사하지 말고 직접 입력
3. **실험하기**: 예제를 수정해서 결과 확인
4. **iex 활용**: `iex`에서 코드를 한 줄씩 테스트
5. **에러 읽기**: Elixir 에러 메시지는 매우 친절함

## IEx 유용한 명령어

```elixir
iex> h Enum.map           # 도움말
iex> i [1, 2, 3]          # 값 정보
iex> recompile            # 재컴파일
```

## 참고 자료

- [Elixir 공식 사이트](https://elixir-lang.org/)
- [Elixir School (한국어)](https://elixirschool.com/ko/)
- [Phoenix 공식 문서](https://hexdocs.pm/phoenix/)
- [Exercism Elixir Track](https://exercism.org/tracks/elixir)
- [Elixir Forum](https://elixirforum.com/)
