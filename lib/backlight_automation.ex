defmodule BacklightAutomation do
  @moduledoc """
  ## Example InputEvents

  - Dell laptop w/ touchscreen
    {"/dev/input/event5",
       %InputEvent.Info{
         input_event_version: "1.0.1",
         name: "G2Touch Multi-Touch by G2TSP",
         bus: 3,
         vendor: 10900,
         product: 21001,
         version: 273,
         report_info: [
           ev_msc: [:msc_timestamp],
           ev_abs: [
             abs_x: %{
               max: 1920,
               min: 0,
               value: 1384,
               flat: 0,
               fuzz: 0,
               resolution: 6
             },
             abs_y: %{
               max: 1080,
               min: 0,
               value: 1058,
               flat: 0,
               fuzz: 0,
               resolution: 6
             },
             abs_mt_slot: %{
               max: 9,
               min: 0,
               value: 0,
               flat: 0,
               fuzz: 0,
               resolution: 0
             },
             abs_mt_position_x: %{
               max: 1920,
               min: 0,
               value: 0,
               flat: 0,
               fuzz: 0,
               resolution: 6
             },
             abs_mt_position_y: %{
               max: 1080,
               min: 0,
               value: 0,
               flat: 0,
               fuzz: 0,
               resolution: 6
             },
             abs_mt_tracking_id: %{
               max: 65535,
               min: 0,
               value: 0,
               flat: 0,
               fuzz: 0,
               resolution: 0
             }
           ],
           ev_key: [:btn_touch]
         ]
       }},
  """
  # TODO Make touch screen names configurable
  # TODO Allow for ../intel_backlight/..
  # TODO read max_brightness
  use GenServer
  require Logger

  alias BacklightAutomation.BacklightDevice

  @name __MODULE__

  @touchscreen_names [
    # Raspberry pi touchscreens
    "raspberrypi-ts",
    "generic ft5x06 (79)",
    "10-0038 generic ft5x06 (79)",
    # Dell laptop touchscreen
    "G2Touch Multi-Touch by G2TSP"
  ]

  @active_level_default 255
  @inactive_level_default 30
  @dim_interval_default 30

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

  @spec set_level(boolean(), map()) :: any()
  def set_level(true, %{active_level: level}), do: set_level(level)
  def set_level(false, %{inactive_level: level}), do: set_level(level)

  @spec set_level(integer()) :: :ok
  def set_level(new_level) when is_integer(new_level) and new_level >= 0 and new_level <= 255,
    do: GenServer.cast(@name, {:set_level, new_level})

  # Handlers

  @impl GenServer
  def init(opts) do
    backlight = BacklightDevice.new()
    InputEvent.start_link(find_touch_screen_input())
    :timer.send_interval(@refresh_interval, self(), :refresh)

    state = %{
      backlight: backlight,
      active_level: Keyword.get(opts, :active_level, @active_level_default),
      dim_interval: Keyword.get(opts, :dim_interval, @dim_interval_default),
      inactive_level: Keyword.get(opts, :inactive_level, @inactive_level_default),
      last_activity: timestamp()
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:refresh, state) do
    state |> active?() |> set_level(state)
    {:noreply, state}
  end

  # Handle InputEvents by marking activity.
  @impl true
  def handle_info(_val, state), do: handle_info(:refresh, %{state | last_activity: timestamp()})

  @impl GenServer
  def handle_cast({:set_level, new_level}, state) do
    BacklightDevice.set_level(state.backlight, new_level)
    {:noreply, state}
  end

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

  def active?(%{last_activity: last_activity, dim_interval: dim_interval}),
    do: last_activity + dim_interval > timestamp()

  def find_touch_screen_input do
    InputEvent.enumerate()
    |> Enum.find(fn {_name, info} -> Enum.member?(@touchscreen_names, info.name) end)
    |> elem(0)
  end

  defp timestamp, do: System.monotonic_time(:second)
end
