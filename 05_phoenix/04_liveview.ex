# ===========================================
# 04. Phoenix LiveView
# ===========================================
# LiveView는 서버 렌더링으로 실시간 UI를 구현합니다.
# JavaScript 없이 SPA 같은 경험을 제공합니다.

# =========================================
# 기본 LiveView - 카운터
# =========================================

defmodule MyAppWeb.CounterLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  @impl true
  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  @impl true
  def handle_event("decrement", _params, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    {:noreply, assign(socket, count: 0)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="counter">
      <h1>카운터: <%= @count %></h1>

      <div class="buttons">
        <button phx-click="decrement">-</button>
        <button phx-click="reset">Reset</button>
        <button phx-click="increment">+</button>
      </div>
    </div>
    """
  end
end

# =========================================
# 폼을 사용하는 LiveView
# =========================================

defmodule MyAppWeb.SearchLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, query: "", results: [])}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    results = perform_search(query)
    {:noreply, assign(socket, query: query, results: results)}
  end

  # 실시간 검색 (입력할 때마다)
  @impl true
  def handle_event("search-change", %{"query" => query}, socket) do
    results = if String.length(query) >= 2 do
      perform_search(query)
    else
      []
    end

    {:noreply, assign(socket, query: query, results: results)}
  end

  defp perform_search(query) do
    # 실제로는 데이터베이스 검색
    [
      %{id: 1, title: "#{query} 관련 글 1"},
      %{id: 2, title: "#{query} 관련 글 2"},
      %{id: 3, title: "#{query} 관련 글 3"}
    ]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="search">
      <form phx-submit="search" phx-change="search-change">
        <input
          type="text"
          name="query"
          value={@query}
          placeholder="검색어를 입력하세요..."
          phx-debounce="300"
        />
        <button type="submit">검색</button>
      </form>

      <ul :if={@results != []} class="results">
        <li :for={result <- @results}>
          <a href={~p"/posts/#{result.id}"}><%= result.title %></a>
        </li>
      </ul>

      <p :if={@results == [] && @query != ""}>
        검색 결과가 없습니다.
      </p>
    </div>
    """
  end
end

# =========================================
# CRUD LiveView
# =========================================

defmodule MyAppWeb.TodoLive do
  use MyAppWeb, :live_view

  alias MyApp.Todos

  @impl true
  def mount(_params, _session, socket) do
    todos = Todos.list_todos()
    {:ok, assign(socket, todos: todos, new_todo: "")}
  end

  @impl true
  def handle_event("add", %{"todo" => todo_text}, socket) do
    case Todos.create_todo(%{text: todo_text, completed: false}) do
      {:ok, todo} ->
        {:noreply,
         socket
         |> update(:todos, fn todos -> todos ++ [todo] end)
         |> assign(:new_todo, "")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "추가 실패")}
    end
  end

  @impl true
  def handle_event("toggle", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:ok, updated} = Todos.update_todo(todo, %{completed: !todo.completed})

    todos = Enum.map(socket.assigns.todos, fn t ->
      if t.id == updated.id, do: updated, else: t
    end)

    {:noreply, assign(socket, todos: todos)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:ok, _} = Todos.delete_todo(todo)

    todos = Enum.reject(socket.assigns.todos, &(&1.id == String.to_integer(id)))
    {:noreply, assign(socket, todos: todos)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="todo-app">
      <h1>할 일 목록</h1>

      <form phx-submit="add">
        <input
          type="text"
          name="todo"
          value={@new_todo}
          placeholder="새로운 할 일..."
        />
        <button type="submit">추가</button>
      </form>

      <ul class="todo-list">
        <li :for={todo <- @todos} class={if todo.completed, do: "completed", else: ""}>
          <input
            type="checkbox"
            checked={todo.completed}
            phx-click="toggle"
            phx-value-id={todo.id}
          />
          <span><%= todo.text %></span>
          <button phx-click="delete" phx-value-id={todo.id}>삭제</button>
        </li>
      </ul>

      <p class="stats">
        총 <%= length(@todos) %>개,
        완료 <%= Enum.count(@todos, & &1.completed) %>개
      </p>
    </div>
    """
  end
end

# =========================================
# 실시간 업데이트 (PubSub)
# =========================================

defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # PubSub 구독
      Phoenix.PubSub.subscribe(MyApp.PubSub, "stats")

      # 1초마다 시간 업데이트
      :timer.send_interval(1000, self(), :tick)
    end

    {:ok, assign(socket,
      current_time: DateTime.utc_now(),
      user_count: 0,
      message_count: 0
    )}
  end

  @impl true
  def handle_info(:tick, socket) do
    {:noreply, assign(socket, current_time: DateTime.utc_now())}
  end

  @impl true
  def handle_info({:stats_update, stats}, socket) do
    {:noreply, assign(socket, stats)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="dashboard">
      <h1>실시간 대시보드</h1>

      <div class="time">
        현재 시간: <%= Calendar.strftime(@current_time, "%H:%M:%S") %>
      </div>

      <div class="stats">
        <div class="stat">
          <span class="value"><%= @user_count %></span>
          <span class="label">접속자</span>
        </div>
        <div class="stat">
          <span class="value"><%= @message_count %></span>
          <span class="label">메시지</span>
        </div>
      </div>
    </div>
    """
  end
end

# =========================================
# LiveComponent (재사용 컴포넌트)
# =========================================

defmodule MyAppWeb.ModalComponent do
  use MyAppWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="modal-overlay" phx-click="close" phx-target={@myself}>
      <div class="modal" phx-click-away="close" phx-target={@myself}>
        <button class="close-btn" phx-click="close" phx-target={@myself}>×</button>
        <h2><%= @title %></h2>
        <div class="modal-content">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("close", _params, socket) do
    send(self(), {:close_modal, socket.assigns.id})
    {:noreply, socket}
  end
end

# 사용 예:
# <.live_component
#   module={MyAppWeb.ModalComponent}
#   id="confirm-modal"
#   title="확인"
# >
#   <p>정말 삭제하시겠습니까?</p>
#   <button phx-click="confirm-delete">삭제</button>
# </.live_component>
