# 00. Elixir 소개 및 설치

## 목차

1. [Elixir란?](#elixir란)
2. [특징](#특징)
3. [설치](#설치)
4. [개발 환경 설정](#개발-환경-설정)
5. [첫 실행](#첫-실행)

---

## Elixir란?

Elixir는 **Erlang VM (BEAM)** 위에서 동작하는 함수형, 동시성 프로그래밍 언어입니다. 2011년 José Valim이 만들었으며, Ruby의 문법적 우아함과 Erlang의 견고함을 결합했습니다.

### 왜 Elixir인가?

- **확장성**: 수백만 개의 동시 프로세스 처리
- **내결함성**: "Let it crash" 철학으로 장애 복구
- **생산성**: 깔끔한 문법과 강력한 메타프로그래밍
- **유지보수성**: 함수형 패러다임으로 예측 가능한 코드

---

## 특징

### 1. 함수형 프로그래밍

```elixir
# 불변 데이터
list = [1, 2, 3]
new_list = [0 | list]  # 원본 변경 없음

# 파이프 연산자
"  hello world  "
|> String.trim()
|> String.upcase()
|> String.split()
# => ["HELLO", "WORLD"]
```

### 2. 동시성

```elixir
# 경량 프로세스 (OS 스레드 아님)
spawn(fn -> IO.puts("Hello from process!") end)

# 수십만 프로세스도 가볍게
for _ <- 1..100_000 do
  spawn(fn -> :timer.sleep(1000) end)
end
```

### 3. 패턴 매칭

```elixir
# 구조 분해
{:ok, result} = {:ok, 42}
[head | tail] = [1, 2, 3, 4, 5]

# 함수 정의
def handle({:ok, data}), do: "Success: #{data}"
def handle({:error, reason}), do: "Error: #{reason}"
```

### 4. 내결함성 (Fault Tolerance)

```elixir
# Supervisor가 자식 프로세스 관리
children = [
  {MyWorker, arg1},
  {AnotherWorker, arg2}
]

Supervisor.start_link(children, strategy: :one_for_one)
# 프로세스 죽으면 자동 재시작
```

---

## 설치

### Windows

**Chocolatey:**
```bash
choco install elixir
```

**Scoop:**
```bash
scoop install elixir
```

**직접 설치:**
[https://elixir-lang.org/install.html#windows](https://elixir-lang.org/install.html#windows)에서 설치 파일 다운로드

### macOS

**Homebrew:**
```bash
brew install elixir
```

### Linux (Ubuntu/Debian)

```bash
# Erlang Solutions 저장소 추가
wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
sudo dpkg -i erlang-solutions_2.0_all.deb
sudo apt-get update

# 설치
sudo apt-get install elixir
```

### 버전 관리자 (asdf)

여러 버전을 관리하려면 asdf 사용:

```bash
# asdf 플러그인 추가
asdf plugin add erlang
asdf plugin add elixir

# 설치
asdf install erlang 26.0
asdf install elixir 1.15.4-otp-26

# 전역 설정
asdf global erlang 26.0
asdf global elixir 1.15.4-otp-26
```

### 설치 확인

```bash
# 버전 확인
elixir --version
# Erlang/OTP 26 [erts-14.0]
# Elixir 1.15.4 (compiled with Erlang/OTP 26)

# Erlang 버전
erl -version

# IEx (Interactive Elixir) 실행
iex
```

---

## 개발 환경 설정

### 편집기/IDE

| 편집기 | 확장/플러그인 |
|--------|---------------|
| **VS Code** | ElixirLS (권장) |
| **IntelliJ/WebStorm** | Elixir Plugin |
| **Vim/Neovim** | vim-elixir, coc-elixir |
| **Emacs** | elixir-mode, alchemist |

### VS Code 설정 (권장)

1. **ElixirLS** 확장 설치
2. 설정 추가 (settings.json):

```json
{
  "elixirLS.suggestSpecs": true,
  "elixirLS.dialyzerEnabled": true,
  "editor.formatOnSave": true,
  "[elixir]": {
    "editor.defaultFormatter": "JakeBecker.elixir-ls"
  }
}
```

### 유용한 도구

| 도구 | 설명 |
|------|------|
| `mix` | 빌드 도구 (프로젝트 생성, 의존성 관리, 테스트) |
| `iex` | 대화형 셸 |
| `hex` | 패키지 매니저 |
| `ExUnit` | 테스트 프레임워크 |

---

## 첫 실행

### IEx (Interactive Elixir)

```bash
$ iex
Erlang/OTP 26 [erts-14.0] [source] [64-bit]

Interactive Elixir (1.15.4) - press Ctrl+C to exit
iex(1)>
```

```elixir
iex> 1 + 2
3

iex> "Hello" <> " " <> "World"
"Hello World"

iex> [1, 2, 3] |> Enum.map(&(&1 * 2))
[2, 4, 6]

iex> h Enum.map  # 도움말
iex> i [1, 2, 3] # 타입 정보
```

**종료:** `Ctrl+C` 두 번 또는 `Ctrl+\`

### 스크립트 파일 실행

`hello.exs` 파일 생성:

```elixir
# hello.exs
IO.puts("Hello, Elixir!")

name = "World"
IO.puts("Hello, #{name}!")

# 리스트 처리
1..5
|> Enum.map(&(&1 * 2))
|> Enum.each(&IO.puts/1)
```

실행:
```bash
elixir hello.exs
```

### 파일 확장자

| 확장자 | 설명 |
|--------|------|
| `.ex` | 컴파일되는 Elixir 파일 (프로덕션 코드) |
| `.exs` | 스크립트 파일 (테스트, 설정, 예제) |

---

## IEx 유용한 명령어

```elixir
iex> h Enum.map          # 함수 도움말
iex> h Enum              # 모듈 도움말
iex> i [1, 2, 3]         # 값 정보 (타입, 크기 등)
iex> t Enum              # 타입 정보
iex> exports Enum        # 내보낸 함수 목록

iex> c "my_module.ex"    # 파일 컴파일
iex> r MyModule          # 모듈 재컴파일
iex> recompile           # 전체 재컴파일

iex> v                   # 마지막 결과
iex> v(1)                # 1번 라인 결과
```

### .iex.exs 설정

프로젝트 루트에 `.iex.exs` 파일을 만들어 IEx 시작 시 자동 실행:

```elixir
# .iex.exs
import_if_available(Ecto.Query)
alias MyApp.{Repo, User, Post}

IEx.configure(
  colors: [enabled: true],
  history_size: 100
)
```

---

## 다음 단계

[01. 기초 문법](./01_basics/README.md)에서 Elixir의 기본 문법을 학습합니다.
