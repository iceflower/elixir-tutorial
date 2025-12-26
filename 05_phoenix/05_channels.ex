# ===========================================
# 05. Phoenix Channels
# ===========================================
# Channels는 WebSocket 기반 실시간 양방향 통신을 제공합니다.
# 채팅, 게임, 실시간 알림 등에 사용됩니다.

# =========================================
# Socket 정의
# =========================================

defmodule MyAppWeb.UserSocket do
  use Phoenix.Socket

  # 채널 라우팅
  channel "room:*", MyAppWeb.RoomChannel
  channel "user:*", MyAppWeb.UserChannel
  channel "notifications:*", MyAppWeb.NotificationChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case verify_token(token) do
      {:ok, user_id} ->
        {:ok, assign(socket, :user_id, user_id)}
      {:error, _reason} ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info) do
    :error
  end

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user_id}"

  defp verify_token(token) do
    # 실제로는 Phoenix.Token 등으로 검증
    {:ok, String.to_integer(token)}
  end
end

# =========================================
# 채팅 채널
# =========================================

defmodule MyAppWeb.RoomChannel do
  use MyAppWeb, :channel

  alias MyApp.Chat

  @impl true
  def join("room:lobby", _payload, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  def join("room:" <> room_id, _payload, socket) do
    if authorized?(socket.assigns.user_id, room_id) do
      send(self(), :after_join)
      {:ok, assign(socket, :room_id, room_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    # 이전 메시지 로드
    messages = Chat.list_recent_messages(socket.assigns[:room_id] || "lobby", 50)

    push(socket, "history", %{messages: messages})

    # 입장 알림
    broadcast!(socket, "user_joined", %{
      user_id: socket.assigns.user_id,
      joined_at: DateTime.utc_now()
    })

    {:noreply, socket}
  end

  # 메시지 수신 및 브로드캐스트
  @impl true
  def handle_in("new_message", %{"body" => body}, socket) do
    user_id = socket.assigns.user_id
    room_id = socket.assigns[:room_id] || "lobby"

    case Chat.create_message(%{body: body, user_id: user_id, room_id: room_id}) do
      {:ok, message} ->
        broadcast!(socket, "new_message", %{
          id: message.id,
          body: message.body,
          user_id: user_id,
          inserted_at: message.inserted_at
        })
        {:reply, :ok, socket}

      {:error, _changeset} ->
        {:reply, {:error, %{reason: "failed to save"}}, socket}
    end
  end

  # 타이핑 표시
  def handle_in("typing", %{"typing" => typing}, socket) do
    broadcast_from!(socket, "user_typing", %{
      user_id: socket.assigns.user_id,
      typing: typing
    })
    {:noreply, socket}
  end

  # 메시지 삭제
  def handle_in("delete_message", %{"id" => message_id}, socket) do
    user_id = socket.assigns.user_id

    case Chat.delete_message(message_id, user_id) do
      {:ok, _} ->
        broadcast!(socket, "message_deleted", %{id: message_id})
        {:reply, :ok, socket}
      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  @impl true
  def terminate(_reason, socket) do
    broadcast!(socket, "user_left", %{
      user_id: socket.assigns.user_id
    })
    :ok
  end

  defp authorized?(user_id, room_id) do
    # 권한 확인 로직
    true
  end
end

# =========================================
# 알림 채널
# =========================================

defmodule MyAppWeb.NotificationChannel do
  use MyAppWeb, :channel

  @impl true
  def join("notifications:" <> user_id, _params, socket) do
    if socket.assigns.user_id == String.to_integer(user_id) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("mark_read", %{"id" => notification_id}, socket) do
    MyApp.Notifications.mark_as_read(notification_id)
    {:reply, :ok, socket}
  end

  def handle_in("mark_all_read", _params, socket) do
    MyApp.Notifications.mark_all_as_read(socket.assigns.user_id)
    {:reply, :ok, socket}
  end
end

# =========================================
# 서버에서 클라이언트로 메시지 보내기
# =========================================

defmodule MyApp.Notifications do
  @moduledoc """
  알림 시스템 - 어디서든 클라이언트에 알림 전송
  """

  def send_notification(user_id, notification) do
    MyAppWeb.Endpoint.broadcast!(
      "notifications:#{user_id}",
      "new_notification",
      notification
    )
  end

  def broadcast_announcement(message) do
    MyAppWeb.Endpoint.broadcast!(
      "room:lobby",
      "announcement",
      %{message: message, time: DateTime.utc_now()}
    )
  end
end

# =========================================
# Presence (온라인 사용자 추적)
# =========================================

defmodule MyAppWeb.Presence do
  use Phoenix.Presence,
    otp_app: :my_app,
    pubsub_server: MyApp.PubSub
end

# 채널에서 Presence 사용
defmodule MyAppWeb.RoomChannelWithPresence do
  use MyAppWeb, :channel

  alias MyAppWeb.Presence

  @impl true
  def join("room:" <> room_id, _params, socket) do
    send(self(), :after_join)
    {:ok, assign(socket, :room_id, room_id)}
  end

  @impl true
  def handle_info(:after_join, socket) do
    # 현재 접속자 목록 전송
    push(socket, "presence_state", Presence.list(socket))

    # 자신을 Presence에 등록
    {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
      online_at: System.system_time(:second),
      typing: false
    })

    {:noreply, socket}
  end

  # Presence 업데이트
  @impl true
  def handle_in("update_status", %{"status" => status}, socket) do
    {:ok, _} = Presence.update(socket, socket.assigns.user_id, fn meta ->
      Map.put(meta, :status, status)
    end)
    {:noreply, socket}
  end
end

# =========================================
# JavaScript 클라이언트 예시
# =========================================

# ```javascript
# import { Socket, Presence } from "phoenix"
#
# // 소켓 연결
# let socket = new Socket("/socket", {params: {token: userToken}})
# socket.connect()
#
# // 채널 참가
# let channel = socket.channel("room:lobby", {})
#
# // 이벤트 리스너
# channel.on("new_message", msg => {
#   console.log("New message:", msg)
#   appendMessage(msg)
# })
#
# channel.on("user_joined", data => {
#   console.log("User joined:", data.user_id)
# })
#
# // Presence
# let presence = new Presence(channel)
# presence.onSync(() => {
#   let users = presence.list()
#   console.log("Online users:", users)
# })
#
# // 채널 참가 실행
# channel.join()
#   .receive("ok", resp => console.log("Joined:", resp))
#   .receive("error", resp => console.log("Error:", resp))
#
# // 메시지 보내기
# function sendMessage(body) {
#   channel.push("new_message", {body: body})
#     .receive("ok", () => console.log("Sent"))
#     .receive("error", err => console.log("Error:", err))
# }
# ```
