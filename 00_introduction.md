# 00. Elixir 소개 및 설치

> **2025년 12월 기준** - Elixir 1.18, Erlang/OTP 27, Phoenix 1.8

## 목차

1. [Elixir란?](#elixir란)
2. [특징](#특징)
3. [Elixir 1.18 새로운 기능](#elixir-118-새로운-기능)
4. [설치](#설치)
5. [개발 환경 설정](#개발-환경-설정)
6. [첫 실행](#첫-실행)

---

## Elixir란?

Elixir는 **Erlang VM (BEAM)** 위에서 동작하는 함수형, 동시성 프로그래밍 언어입니다.
2011년 José Valim이 만들었으며, Ruby의 문법적 우아함과 Erlang의 견고함을 결합했습니다.

### 왜 Elixir인가?

- **확장성**: 수백만 개의 동시 프로세스 처리
- **내결함성**: "Let it crash" 철학으로 장애 복구
- **생산성**: 깔끔한 문법과 강력한 메타프로그래밍
- **유지보수성**: 함수형 패러다임으로 예측 가능한 코드
- **점진적 타입 시스템**: 1.18부터 본격적인 타입 체크 지원

### 주요 사용 사례

| 분야 | 예시 |
|------|------|
| **웹 개발** | Phoenix Framework, LiveView |
| **실시간 시스템** | 채팅, 게임 서버, IoT |
| **분산 시스템** | 마이크로서비스, 클러스터링 |
| **데이터 파이프라인** | Broadway, GenStage |
| **임베디드** | Nerves (IoT 디바이스) |

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

## Elixir 1.18 새로운 기능

### 1. 점진적 타입 시스템 (Gradual Type System)

Elixir 1.18에서 가장 큰 변화는 **타입 체킹**입니다.
명시적 타입 선언 없이도 컴파일 타임에 타입 오류를 감지합니다.

```elixir
defmodule Example do
  # 패턴과 반환 타입을 자동 추론
  def add(a, b) when is_integer(a) and is_integer(b) do
    a + b
  end
end

# 컴파일 시 타입 불일치 경고
Example.add("hello", 1)  # warning: incompatible types
```

**타입 체킹 범위:**

- 함수 호출 타입 체킹
- 패턴 타입 추론
- `case`, `cond`, `=` 에서 매칭 불가능한 절 감지
- 튜플, 리스트 복합 타입 지원

### 2. 내장 JSON 지원

외부 라이브러리 없이 JSON 처리 가능:

```elixir
# 인코딩
JSON.encode!(%{name: "Elixir", version: 1.18})
# => "{\"name\":\"Elixir\",\"version\":1.18}"

# 디코딩
JSON.decode!("{\"name\":\"Elixir\"}")
# => %{"name" => "Elixir"}

# iodata로 인코딩 (성능 최적화)
JSON.encode_to_iodata!(%{key: "value"})

# 커스텀 인코딩 (JSON.Encoder 프로토콜)
defimpl JSON.Encoder, for: MyStruct do
  def encode(value, opts) do
    JSON.encode_to_iodata!(Map.from_struct(value), opts)
  end
end
```

### 3. Language Server 개선

- **컴파일러 락**: 프로젝트가 한 번만 컴파일되어 IDE와 터미널 간 충돌 방지
- **IEx 자동 리로드**: 다른 프로세스에서 컴파일된 모듈 자동 갱신

```elixir
# IEx에서 자동 리로드 활성화
IEx.configure(auto_reload: true)
```

### 4. 파라미터화된 테스트

동일한 테스트를 다양한 파라미터로 실행:

```elixir
defmodule MathTest do
  use ExUnit.Case, async: true

  # 파라미터화된 테스트 모듈
  for {input, expected} <- [{1, 2}, {2, 4}, {3, 6}] do
    test "double #{input} equals #{expected}" do
      assert unquote(input) * 2 == unquote(expected)
    end
  end
end
```

### 5. mix format --migrate

레거시 문법을 최신 스타일로 자동 변환:

```bash
mix format --migrate
```

**변환 예시:**

- `'hello'` → `~c"hello"` (charlist를 시길로)
- 비트스트링 수정자 괄호 정규화

---

## 설치

### 권장 버전 (2025년 12월 기준)

| 소프트웨어 | 버전 |
|------------|------|
| Erlang/OTP | 27.x |
| Elixir | 1.18.x |

> **참고**: Elixir 1.18은 Erlang/OTP 25를 지원하는 마지막 버전입니다. OTP 26 이상 권장.

### Windows

**Chocolatey:**

```bash
choco install elixir
```

**Scoop:**

```bash
scoop install elixir
```

**WinGet:**

```bash
winget install ElixirLang.Elixir
```

**직접 설치:**
[https://elixir-lang.org/install.html#windows](https://elixir-lang.org/install.html#windows)

### macOS

**Homebrew:**

```bash
brew install elixir
```

### Linux (Ubuntu/Debian)

```bash
# 저장소 추가 (최신 방법)
sudo apt-get install -y gnupg
wget https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc
sudo apt-key add erlang_solutions.asc
echo "deb https://packages.erlang-solutions.com/ubuntu $(lsb_release -cs) contrib" \
  | sudo tee /etc/apt/sources.list.d/erlang.list

# 설치
sudo apt-get update
sudo apt-get install -y esl-erlang elixir
```

### 버전 관리자 (mise 또는 asdf)

**mise (권장 - 더 빠름):**

```bash
# mise 설치
curl https://mise.run | sh

# Erlang과 Elixir 설치
mise use -g erlang@27.2
mise use -g elixir@1.18.1-otp-27
```

**asdf:**

```bash
# 플러그인 추가
asdf plugin add erlang
asdf plugin add elixir

# 설치
asdf install erlang 27.2
asdf install elixir 1.18.1-otp-27

# 전역 설정
asdf global erlang 27.2
asdf global elixir 1.18.1-otp-27
```

### 설치 확인

```bash
# 버전 확인
elixir --version
# Erlang/OTP 27 [erts-15.0]
# Elixir 1.18.1 (compiled with Erlang/OTP 27)

# IEx 실행
iex
```

---

## 개발 환경 설정

### 편집기/IDE

| 편집기 | 확장/플러그인 | 비고 |
|--------|---------------|------|
| **VS Code** | ElixirLS | 가장 인기 있는 선택 |
| **Zed** | 내장 지원 | 빠른 새 에디터 |
| **Neovim** | elixir-tools.nvim | LSP 기반 |
| **IntelliJ** | Elixir Plugin | 유료 |
| **Emacs** | elixir-ts-mode | Tree-sitter 기반 |

### VS Code 설정 (권장)

1. **ElixirLS** 확장 설치
2. 설정 추가 (settings.json):

```json
{
  "elixirLS.suggestSpecs": true,
  "elixirLS.dialyzerEnabled": true,
  "elixirLS.fetchDeps": true,
  "editor.formatOnSave": true,
  "[elixir]": {
    "editor.defaultFormatter": "JakeBecker.elixir-ls",
    "editor.tabSize": 2
  },
  "files.associations": {
    "*.heex": "phoenix-heex"
  }
}
```

### Neovim 설정 (elixir-tools.nvim)

```lua
-- lazy.nvim 사용 시
{
  "elixir-tools/elixir-tools.nvim",
  version = "*",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("elixir").setup({
      nextls = { enable = true },
      elixirls = { enable = false },
    })
  end,
  dependencies = { "nvim-lua/plenary.nvim" },
}
```

### 유용한 도구

| 도구 | 설명 | 명령어 |
|------|------|--------|
| `mix` | 빌드 도구 | `mix new`, `mix compile` |
| `iex` | 대화형 셸 | `iex -S mix` |
| `hex` | 패키지 매니저 | `mix hex.info` |
| `ExUnit` | 테스트 프레임워크 | `mix test` |
| `Dialyzer` | 정적 분석 | `mix dialyzer` |
| `Credo` | 코드 품질 검사 | `mix credo` |

---

## 첫 실행

### IEx (Interactive Elixir)

```bash
$ iex
Erlang/OTP 27 [erts-15.0] [source] [64-bit]

Interactive Elixir (1.18.1) - press Ctrl+C to exit
iex(1)>
```

```elixir
iex> 1 + 2
3

iex> "Hello" <> " " <> "World"
"Hello World"

iex> [1, 2, 3] |> Enum.map(&(&1 * 2))
[2, 4, 6]

# 1.18 새 기능: 내장 JSON
iex> JSON.encode!(%{hello: "world"})
"{\"hello\":\"world\"}"

iex> h Enum.map  # 도움말
iex> i [1, 2, 3] # 타입 정보
```

**종료:** `Ctrl+C` 두 번

### 스크립트 파일 실행

`hello.exs` 파일 생성:

```elixir
# hello.exs
IO.puts("Hello, Elixir 1.18!")

name = "World"
IO.puts("Hello, #{name}!")

# 내장 JSON 사용
data = %{language: "Elixir", version: "1.18"}
IO.puts(JSON.encode!(data))

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
| `.heex` | HTML + EEx 템플릿 (Phoenix) |
| `.leex` | LiveView EEx 템플릿 (레거시) |

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

# 1.18 새 기능
iex> IEx.configure(auto_reload: true)  # 자동 리로드
```

### .iex.exs 설정

프로젝트 루트에 `.iex.exs` 파일을 만들어 IEx 시작 시 자동 실행:

```elixir
# .iex.exs
import_if_available(Ecto.Query)
alias MyApp.{Repo, User, Post}

IEx.configure(
  colors: [enabled: true],
  history_size: 100,
  auto_reload: true  # 1.18 새 기능
)

# 유용한 헬퍼 함수
defmodule H do
  def reload! do
    IEx.Helpers.recompile()
  end
end
```

---

## Mix 프로젝트 생성

```bash
# 기본 프로젝트
mix new my_app

# Supervisor 포함
mix new my_app --sup

# Phoenix 웹 앱
mix phx.new my_web_app

# Phoenix LiveView 전용
mix phx.new my_app --live
```

프로젝트 구조:

```text
my_app/
├── lib/
│   ├── my_app.ex
│   └── my_app/
├── test/
│   ├── my_app_test.exs
│   └── test_helper.exs
├── mix.exs           # 프로젝트 설정
└── README.md
```

---

## 다음 단계

[01. 기초 문법](./01_basics/README.md)에서 Elixir의 기본 문법을 학습합니다.

---

## 참고 자료

- [Elixir 공식 사이트](https://elixir-lang.org/)
- [Elixir 1.18 릴리스 노트](https://elixir-lang.org/blog/2024/12/19/elixir-v1-18-0-released/)
- [Elixir School (한국어)](https://elixirschool.com/ko/)
- [HexDocs](https://hexdocs.pm/)
- [Elixir Forum](https://elixirforum.com/)
