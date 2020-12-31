defmodule RpiScreenDimmer do
  use GenServer

  @name __MODULE__

  @touchscreen_name "raspberrypi-ts"

  @active_level_default 255
  @inactive_level_default 30
  @dim_interval_default 30

  @control_file "/sys/class/backlight/rpi_backlight/brightness"

  @refresh_interval 5_000

  @spec start_link(list()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts), do: GenServer.start_link(@name, opts, name: @name)

  @spec active_level(integer()) :: :ok
  def active_level(new_level), do: GenServer.cast(@name, {:set_active_level, new_level})

  @spec inactive_level(integer()) :: :ok
  def inactive_level(new_level), do: GenServer.cast(@name, {:set_inactive_level, new_level})

  @spec dim_interval(integer()) :: :ok
  def dim_interval(interval_in_sec),
    do: GenServer.cast(@name, {:set_dim_interval, interval_in_sec})

  @spec set_level!(boolean(), map()) :: any()
  def set_level!(true, %{active_level: level}), do: set_level!(level)
  def set_level!(false, %{inactive_level: level}), do: set_level!(level)

  @spec set_level!(integer()) :: any()
  def set_level!(new_level) when is_integer(new_level) and new_level >= 0 and new_level <= 255,
    do: File.write!(@control_file, Integer.to_string(new_level), [:write])

  # Handlers

  @impl GenServer
  def init(opts) do
    InputEvent.start_link(find_touch_screen_input())
    :timer.send_interval(@refresh_interval, self(), :refresh)

    state = %{
      active_level: Keyword.get(opts, :active_level, @active_level_default),
      dim_interval: Keyword.get(opts, :dim_interval, @dim_interval_default),
      inactive_level: Keyword.get(opts, :inactive_level, @inactive_level_default),
      last_activity: timestamp()
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:refresh, state) do
    state
    |> active?()
    |> set_level!(state)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(_val, state), do: handle_info(:refresh, %{state | last_activity: timestamp()})

  @impl GenServer
  def handle_cast({:set_active_level, new_level}, state),
    do: {:noreply, %{state | active_level: new_level}}

  @impl GenServer
  def handle_cast({:set_inactive_level, new_level}, state),
    do: {:noreply, %{state | inactive_level: new_level}}

  @impl GenServer
  def handle_cast({:set_dim_interval, interval}, state),
    do: {:noreply, %{state | dim_interval: interval}}

  # Helper funcs

  defp active?(%{last_activity: last_activity, dim_interval: dim_interval}),
    do: last_activity + dim_interval > timestamp()

  defp find_touch_screen_input do
    InputEvent.enumerate()
    |> Enum.find(fn {_name, info} -> info.name == @touchscreen_name end)
    |> elem(0)
  end

  defp timestamp, do: System.monotonic_time(:second)
end
