# ===========================================
# 01. 프로세스 (Processes)
# ===========================================

# Elixir 프로세스는 OS 프로세스/스레드와 다릅니다:
# - 매우 가벼움 (수 KB)
# - 수십만 개 생성 가능
# - 격리됨 (메모리 공유 없음)
# - 메시지 패싱으로 통신

# -------------------------------------------
# 기본 프로세스 생성
# -------------------------------------------

IO.puts("=== 프로세스 생성 ===")

# 현재 프로세스 ID
IO.puts("현재 프로세스: #{inspect(self())}")

# spawn - 새 프로세스 생성
pid = spawn(fn ->
  IO.puts("새 프로세스: #{inspect(self())}")
  IO.puts("부모 프로세스에서 실행됨!")
end)

IO.puts("생성된 프로세스: #{inspect(pid)}")

# 프로세스가 끝날 때까지 잠시 대기
Process.sleep(100)

# spawn_link - 연결된 프로세스 (한쪽이 죽으면 다른 쪽도 종료)
# spawn_monitor - 모니터링 (죽어도 알림만 받음)

# -------------------------------------------
# 프로세스 정보
# -------------------------------------------

IO.puts("\n=== 프로세스 정보 ===")

IO.puts("살아있나? #{Process.alive?(self())}")
IO.inspect(Process.info(self(), :memory), label: "메모리")
IO.inspect(Process.info(self(), :message_queue_len), label: "메시지 큐")

# 많은 프로세스 생성
pids = for _ <- 1..1000 do
  spawn(fn -> Process.sleep(1000) end)
end
IO.puts("1000개 프로세스 생성됨")
IO.puts("살아있는 프로세스 수: #{length(Process.list())}")

# 정리
Enum.each(pids, &Process.exit(&1, :kill))
Process.sleep(100)

# -------------------------------------------
# 메시지 전달
# -------------------------------------------

IO.puts("\n=== 메시지 전달 ===")

# send - 메시지 보내기
# receive - 메시지 받기

# 자신에게 메시지 보내기
send(self(), {:hello, "World"})
send(self(), {:number, 42})

# 메시지 받기
receive do
  {:hello, name} ->
    IO.puts("받은 메시지: Hello, #{name}!")
end

receive do
  {:number, n} ->
    IO.puts("받은 숫자: #{n}")
end

# -------------------------------------------
# 프로세스 간 통신
# -------------------------------------------

IO.puts("\n=== 프로세스 간 통신 ===")

# 에코 프로세스
parent = self()

echo_pid = spawn(fn ->
  receive do
    {:echo, message, from} ->
      IO.puts("에코 프로세스가 받음: #{message}")
      send(from, {:response, String.upcase(message)})
  end
end)

# 메시지 보내고 응답 받기
send(echo_pid, {:echo, "hello elixir", parent})

receive do
  {:response, reply} ->
    IO.puts("응답 받음: #{reply}")
after
  1000 ->
    IO.puts("타임아웃!")
end

# -------------------------------------------
# 상태를 가진 프로세스 (루프)
# -------------------------------------------

IO.puts("\n=== 상태를 가진 프로세스 ===")

defmodule Counter do
  def start(initial_count \\ 0) do
    spawn(fn -> loop(initial_count) end)
  end

  defp loop(count) do
    receive do
      {:increment, from} ->
        new_count = count + 1
        send(from, {:count, new_count})
        loop(new_count)

      {:decrement, from} ->
        new_count = count - 1
        send(from, {:count, new_count})
        loop(new_count)

      {:get, from} ->
        send(from, {:count, count})
        loop(count)

      :stop ->
        IO.puts("카운터 종료, 최종값: #{count}")
        :ok
    end
  end

  # 클라이언트 API
  def increment(pid) do
    send(pid, {:increment, self()})
    receive do
      {:count, count} -> count
    end
  end

  def decrement(pid) do
    send(pid, {:decrement, self()})
    receive do
      {:count, count} -> count
    end
  end

  def get(pid) do
    send(pid, {:get, self()})
    receive do
      {:count, count} -> count
    end
  end

  def stop(pid) do
    send(pid, :stop)
  end
end

# 사용
counter = Counter.start(10)
IO.puts("초기값: #{Counter.get(counter)}")
IO.puts("증가 후: #{Counter.increment(counter)}")
IO.puts("증가 후: #{Counter.increment(counter)}")
IO.puts("감소 후: #{Counter.decrement(counter)}")
Counter.stop(counter)

# -------------------------------------------
# 프로세스 모니터링
# -------------------------------------------

IO.puts("\n=== 프로세스 모니터링 ===")

# spawn_monitor - 프로세스 감시
{pid, ref} = spawn_monitor(fn ->
  IO.puts("작업 시작...")
  Process.sleep(100)
  IO.puts("작업 완료!")
  # exit(:normal)
end)

receive do
  {:DOWN, ^ref, :process, ^pid, reason} ->
    IO.puts("프로세스 종료됨, 이유: #{inspect(reason)}")
after
  1000 ->
    IO.puts("타임아웃")
end

# 비정상 종료 감지
{pid2, ref2} = spawn_monitor(fn ->
  raise "의도적 에러!"
end)

receive do
  {:DOWN, ^ref2, :process, ^pid2, reason} ->
    IO.puts("프로세스 크래시, 이유: #{inspect(reason)}")
after
  1000 ->
    IO.puts("타임아웃")
end

# -------------------------------------------
# Task - 간단한 비동기 작업
# -------------------------------------------

IO.puts("\n=== Task ===")

# Task.async/await - 비동기 작업 후 결과 대기
task = Task.async(fn ->
  Process.sleep(100)
  "작업 결과!"
end)

result = Task.await(task)
IO.puts("Task 결과: #{result}")

# 여러 Task 병렬 실행
tasks = for i <- 1..5 do
  Task.async(fn ->
    Process.sleep(:rand.uniform(100))
    i * i
  end)
end

results = Task.await_many(tasks)
IO.inspect(results, label: "병렬 결과")

# Task.start - fire-and-forget (결과 필요 없을 때)
Task.start(fn ->
  IO.puts("백그라운드 작업 실행")
end)

Process.sleep(50)

# -------------------------------------------
# Agent - 간단한 상태 관리
# -------------------------------------------

IO.puts("\n=== Agent ===")

# Agent는 상태를 저장하는 간단한 프로세스
{:ok, agent} = Agent.start_link(fn -> [] end)

# 상태 업데이트
Agent.update(agent, fn list -> ["사과" | list] end)
Agent.update(agent, fn list -> ["바나나" | list] end)
Agent.update(agent, fn list -> ["오렌지" | list] end)

# 상태 조회
items = Agent.get(agent, fn list -> list end)
IO.inspect(items, label: "Agent 상태")

# get_and_update - 조회와 업데이트 동시에
popped = Agent.get_and_update(agent, fn [head | tail] -> {head, tail} end)
IO.puts("꺼낸 항목: #{popped}")
IO.inspect(Agent.get(agent, & &1), label: "남은 항목")

Agent.stop(agent)

# ============================================
# 실습: 채팅방 프로세스
# ============================================

# TODO: 간단한 채팅방 프로세스 만들기
# - 사용자 입장/퇴장 관리
# - 메시지 브로드캐스트
# - 현재 사용자 목록 조회
