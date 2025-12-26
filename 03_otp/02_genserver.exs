# ===========================================
# 02. GenServer (Generic Server)
# ===========================================

# GenServer는 상태를 가진 서버 프로세스의 일반적인 패턴을 추상화합니다.
# 직접 receive 루프를 작성하는 대신 콜백 함수만 구현하면 됩니다.

# -------------------------------------------
# 기본 GenServer
# -------------------------------------------

defmodule Counter do
  use GenServer

  # ===================
  # 클라이언트 API
  # ===================

  @doc "카운터 시작"
  def start_link(initial_value \\ 0) do
    GenServer.start_link(__MODULE__, initial_value, name: __MODULE__)
  end

  @doc "현재 값 조회"
  def get do
    GenServer.call(__MODULE__, :get)
  end

  @doc "증가"
  def increment do
    GenServer.call(__MODULE__, :increment)
  end

  @doc "감소"
  def decrement do
    GenServer.call(__MODULE__, :decrement)
  end

  @doc "특정 값만큼 증가 (비동기)"
  def add(amount) do
    GenServer.cast(__MODULE__, {:add, amount})
  end

  @doc "리셋"
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  # ===================
  # 서버 콜백
  # ===================

  @impl true
  def init(initial_value) do
    IO.puts("[Counter] 시작됨, 초기값: #{initial_value}")
    {:ok, initial_value}
  end

  # call - 동기 요청 (응답 대기)
  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:increment, _from, state) do
    new_state = state + 1
    {:reply, new_state, new_state}
  end

  def handle_call(:decrement, _from, state) do
    new_state = state - 1
    {:reply, new_state, new_state}
  end

  def handle_call(:reset, _from, _state) do
    {:reply, :ok, 0}
  end

  # cast - 비동기 요청 (응답 없음)
  @impl true
  def handle_cast({:add, amount}, state) do
    {:noreply, state + amount}
  end

  # info - 일반 메시지 (send로 보낸 것)
  @impl true
  def handle_info(msg, state) do
    IO.puts("[Counter] 알 수 없는 메시지: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    IO.puts("[Counter] 종료됨, 이유: #{inspect(reason)}, 최종값: #{state}")
    :ok
  end
end

# -------------------------------------------
# GenServer 사용
# -------------------------------------------

IO.puts("=== GenServer 사용 ===\n")

{:ok, _pid} = Counter.start_link(10)

IO.puts("초기값: #{Counter.get()}")
IO.puts("증가: #{Counter.increment()}")
IO.puts("증가: #{Counter.increment()}")
IO.puts("감소: #{Counter.decrement()}")

Counter.add(100)
Process.sleep(10)  # cast는 비동기이므로 잠시 대기
IO.puts("100 추가 후: #{Counter.get()}")

Counter.reset()
IO.puts("리셋 후: #{Counter.get()}")

GenServer.stop(Counter)
Process.sleep(50)

# -------------------------------------------
# 실전 예제: 키-값 저장소
# -------------------------------------------

IO.puts("\n=== 키-값 저장소 ===\n")

defmodule KVStore do
  use GenServer

  # 클라이언트 API
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  def put(server \\ __MODULE__, key, value) do
    GenServer.call(server, {:put, key, value})
  end

  def get(server \\ __MODULE__, key) do
    GenServer.call(server, {:get, key})
  end

  def delete(server \\ __MODULE__, key) do
    GenServer.call(server, {:delete, key})
  end

  def all(server \\ __MODULE__) do
    GenServer.call(server, :all)
  end

  def clear(server \\ __MODULE__) do
    GenServer.cast(server, :clear)
  end

  # 서버 콜백
  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:put, key, value}, _from, state) do
    new_state = Map.put(state, key, value)
    {:reply, :ok, new_state}
  end

  def handle_call({:get, key}, _from, state) do
    value = Map.get(state, key)
    {:reply, value, state}
  end

  def handle_call({:delete, key}, _from, state) do
    {value, new_state} = Map.pop(state, key)
    {:reply, value, new_state}
  end

  def handle_call(:all, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:clear, _state) do
    {:noreply, %{}}
  end
end

{:ok, _} = KVStore.start_link()

KVStore.put(:name, "Kim")
KVStore.put(:age, 25)
KVStore.put(:city, "Seoul")

IO.puts("이름: #{KVStore.get(:name)}")
IO.puts("나이: #{KVStore.get(:age)}")
IO.inspect(KVStore.all(), label: "전체")

KVStore.delete(:city)
IO.inspect(KVStore.all(), label: "삭제 후")

GenServer.stop(KVStore)

# -------------------------------------------
# 실전 예제: 캐시 (TTL 지원)
# -------------------------------------------

IO.puts("\n=== TTL 캐시 ===\n")

defmodule Cache do
  use GenServer

  @cleanup_interval 1000  # 1초마다 정리

  # 클라이언트 API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def put(key, value, ttl_ms \\ 5000) do
    GenServer.call(__MODULE__, {:put, key, value, ttl_ms})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  # 서버 콜백
  @impl true
  def init(_opts) do
    # 주기적 정리 스케줄
    schedule_cleanup()
    {:ok, %{data: %{}, stats: %{hits: 0, misses: 0}}}
  end

  @impl true
  def handle_call({:put, key, value, ttl_ms}, _from, state) do
    expires_at = System.monotonic_time(:millisecond) + ttl_ms
    entry = %{value: value, expires_at: expires_at}
    new_data = Map.put(state.data, key, entry)
    {:reply, :ok, %{state | data: new_data}}
  end

  def handle_call({:get, key}, _from, state) do
    now = System.monotonic_time(:millisecond)

    case Map.get(state.data, key) do
      %{value: value, expires_at: exp} when exp > now ->
        new_stats = Map.update!(state.stats, :hits, &(&1 + 1))
        {:reply, {:ok, value}, %{state | stats: new_stats}}

      _ ->
        new_stats = Map.update!(state.stats, :misses, &(&1 + 1))
        {:reply, :miss, %{state | stats: new_stats}}
    end
  end

  def handle_call(:stats, _from, state) do
    {:reply, state.stats, state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    now = System.monotonic_time(:millisecond)

    new_data = state.data
      |> Enum.filter(fn {_k, %{expires_at: exp}} -> exp > now end)
      |> Map.new()

    removed = map_size(state.data) - map_size(new_data)
    if removed > 0 do
      IO.puts("[Cache] #{removed}개 만료 항목 정리됨")
    end

    schedule_cleanup()
    {:noreply, %{state | data: new_data}}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end
end

{:ok, _} = Cache.start_link()

Cache.put(:temp, "임시 데이터", 500)  # 0.5초 TTL
Cache.put(:long, "오래 유지", 10000)  # 10초 TTL

IO.inspect(Cache.get(:temp), label: "temp (즉시)")
IO.inspect(Cache.get(:long), label: "long (즉시)")

Process.sleep(600)  # 0.6초 대기

IO.inspect(Cache.get(:temp), label: "temp (0.6초 후)")
IO.inspect(Cache.get(:long), label: "long (0.6초 후)")
IO.inspect(Cache.stats(), label: "통계")

GenServer.stop(Cache)

# -------------------------------------------
# GenServer 반환값 정리
# -------------------------------------------

IO.puts("\n=== GenServer 반환값 정리 ===")

IO.puts("""
handle_call 반환값:
  {:reply, reply, new_state}
  {:reply, reply, new_state, timeout}
  {:reply, reply, new_state, :hibernate}
  {:noreply, new_state}
  {:stop, reason, reply, new_state}

handle_cast 반환값:
  {:noreply, new_state}
  {:noreply, new_state, timeout}
  {:stop, reason, new_state}

handle_info 반환값:
  {:noreply, new_state}
  {:noreply, new_state, timeout}
  {:stop, reason, new_state}
""")

# ============================================
# 실습: 은행 계좌 GenServer
# ============================================

# TODO: BankAccount GenServer 만들기
# - start_link(initial_balance)
# - deposit(amount) - 입금
# - withdraw(amount) - 출금 (잔액 부족 시 {:error, :insufficient_funds})
# - balance() - 잔액 조회
# - transfer(to_account, amount) - 다른 계좌로 이체
