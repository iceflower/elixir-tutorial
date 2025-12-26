# ===========================================
# 06. 모듈 (Modules)
# ===========================================

# -------------------------------------------
# 기본 모듈 정의
# -------------------------------------------

defmodule Calculator do
  @moduledoc """
  간단한 계산기 모듈입니다.
  기본적인 산술 연산을 제공합니다.
  """

  @doc """
  두 숫자를 더합니다.

  ## Examples

      iex> Calculator.add(2, 3)
      5
  """
  def add(a, b), do: a + b
  def subtract(a, b), do: a - b
  def multiply(a, b), do: a * b
  def divide(a, b) when b != 0, do: a / b
end

IO.puts("=== 기본 모듈 ===")
IO.puts("Calculator.add(10, 5) = #{Calculator.add(10, 5)}")
IO.puts("Calculator.subtract(10, 5) = #{Calculator.subtract(10, 5)}")

# -------------------------------------------
# 모듈 속성 (Module Attributes)
# -------------------------------------------

defmodule App do
  # 컴파일 시 상수로 사용
  @app_name "MyApp"
  @version "1.0.0"
  @author "Kim"

  # 누적 속성 (Accumulating Attributes)
  Module.register_attribute(__MODULE__, :features, accumulate: true)
  @features :auth
  @features :api
  @features :websocket

  def info do
    "#{@app_name} v#{@version} by #{@author}"
  end

  def version, do: @version

  # 컴파일 시점에 @features는 [:websocket, :api, :auth]
end

IO.puts("\n=== 모듈 속성 ===")
IO.puts(App.info())
IO.puts("Version: #{App.version()}")

# -------------------------------------------
# 중첩 모듈 (Nested Modules)
# -------------------------------------------

defmodule Outer do
  defmodule Inner do
    def hello, do: "Hello from Inner"
  end

  def greet, do: Inner.hello()
end

# 또는 점(.)으로 직접 정의
defmodule MyApp.Models.User do
  defstruct [:id, :name, :email]

  def new(name, email) do
    %__MODULE__{id: :rand.uniform(1000), name: name, email: email}
  end
end

IO.puts("\n=== 중첩 모듈 ===")
IO.puts(Outer.greet())
IO.puts(Outer.Inner.hello())
IO.inspect(MyApp.Models.User.new("Kim", "kim@test.com"), label: "User")

# -------------------------------------------
# 별칭, 임포트, 사용 (alias, import, use)
# -------------------------------------------

defmodule Demo do
  # alias - 모듈 이름 줄이기
  alias MyApp.Models.User
  # alias MyApp.Models.User, as: U  # 다른 이름으로

  # import - 함수를 현재 스코프로 가져오기
  import String, only: [upcase: 1, downcase: 1]
  # import String, except: [split: 1]  # 특정 함수 제외

  def demo do
    # User로 바로 접근 (MyApp.Models.User 대신)
    user = User.new("Lee", "lee@test.com")

    # upcase 직접 호출 (String.upcase 대신)
    name = upcase(user.name)

    "#{name}: #{user.email}"
  end
end

IO.puts("\n=== alias, import ===")
IO.puts(Demo.demo())

# -------------------------------------------
# Behaviours (인터페이스)
# -------------------------------------------

defmodule Parser do
  @callback parse(binary()) :: {:ok, any()} | {:error, String.t()}
  @callback extensions() :: [String.t()]
end

defmodule JSONParser do
  @behaviour Parser

  @impl Parser
  def parse(content) do
    # 실제로는 Jason 같은 라이브러리 사용
    {:ok, "parsed: #{content}"}
  end

  @impl Parser
  def extensions, do: [".json"]
end

IO.puts("\n=== Behaviours ===")
IO.inspect(JSONParser.parse("{\"name\": \"test\"}"), label: "JSON parse")
IO.inspect(JSONParser.extensions(), label: "Extensions")

# -------------------------------------------
# 구조체 (Structs)
# -------------------------------------------

defmodule Person do
  # 기본값이 있는 구조체
  defstruct name: "Unknown", age: 0, email: nil

  def new(attrs \\ []) do
    struct(__MODULE__, attrs)
  end

  def adult?(%Person{age: age}), do: age >= 18

  def greet(%Person{name: name}) do
    "Hello, #{name}!"
  end
end

IO.puts("\n=== 구조체 ===")

# 구조체 생성
person1 = %Person{name: "Kim", age: 25}
person2 = %Person{name: "Lee", age: 17, email: "lee@test.com"}
person3 = Person.new(name: "Park", age: 30)

IO.inspect(person1, label: "person1")
IO.puts("#{person1.name} is adult? #{Person.adult?(person1)}")
IO.puts("#{person2.name} is adult? #{Person.adult?(person2)}")
IO.puts(Person.greet(person3))

# 구조체 업데이트 (새 구조체 반환)
updated = %{person1 | age: 26}
IO.inspect(updated, label: "updated person1")

# 패턴 매칭
%Person{name: name, age: age} = person1
IO.puts("Matched: #{name}, #{age}")

# -------------------------------------------
# 프로토콜 (Protocols)
# -------------------------------------------

# 프로토콜 정의 - 다형성 지원
defprotocol Describable do
  @doc "Returns a description of the data"
  def describe(data)
end

# 다양한 타입에 대해 구현
defimpl Describable, for: Person do
  def describe(%Person{name: name, age: age}) do
    "#{name}은(는) #{age}살입니다"
  end
end

defimpl Describable, for: Map do
  def describe(map) do
    "#{map_size(map)}개의 키를 가진 맵"
  end
end

defimpl Describable, for: List do
  def describe(list) do
    "#{length(list)}개의 요소를 가진 리스트"
  end
end

IO.puts("\n=== 프로토콜 ===")
IO.puts(Describable.describe(person1))
IO.puts(Describable.describe(%{a: 1, b: 2, c: 3}))
IO.puts(Describable.describe([1, 2, 3, 4, 5]))

# ============================================
# 실습: 쇼핑 카트 모듈 만들기
# ============================================

# TODO: Cart 모듈과 Item 구조체 만들기
# - Item: name, price, quantity 필드
# - Cart: items 리스트를 가지고 add_item, total, item_count 함수 구현
