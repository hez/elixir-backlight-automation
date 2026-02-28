defmodule BacklightAutomation.Server do
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

  use GenServer
  require Logger

  alias BacklightAutomation.BacklightDevice
  alias BacklightAutomation.InputDevice

  @name __MODULE__

  @refresh_interval 5_000

  defguard is_valid_level(level) when is_integer(level) and level >= 0

  @spec start_link(list()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts) do
    Logger.warning("starting BacklightAutomation server")
    res = GenServer.start_link(@name, opts, name: @name)
    Logger.error("got #{inspect(res)}")
    res
  end

  @spec active_level(integer()) :: :ok
  def active_level(new_level), do: GenServer.cast(@name, {:set_active_level, new_level})

  @spec inactive_level(integer()) :: :ok
  def inactive_level(new_level), do: GenServer.cast(@name, {:set_inactive_level, new_level})

  @spec dim_interval(integer()) :: :ok
  def dim_interval(interval_in_sec),
    do: GenServer.cast(@name, {:set_dim_interval, interval_in_sec})

  @spec touch() :: :ok
  def touch, do: GenServer.cast(@name, :touch)

  @spec current_level() :: integer()
  def current_level, do: state().current_level

  @spec set_level(integer()) :: :ok
  def set_level(new_level) when is_valid_level(new_level),
    do: GenServer.cast(@name, {:set_level, new_level})

  def max_brightness, do: state().backlight.max_brightness

  @spec active?() :: boolean()
  def active?, do: state() |> active?()

  @spec state() :: BacklightAutomation.t()
  def state, do: GenServer.call(@name, :state)

  @impl GenServer
  def init(opts) do
    state = opts |> BacklightAutomation.new() |> start_input_devices()
    :timer.send_interval(@refresh_interval, self(), :refresh)
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:refresh, state) do
    state = state |> ensure_valid_backlight() |> start_input_devices()

    new_state =
      cond do
        active?(state) -> set_level(state, state.active_level)
        not active?(state) -> set_level(state, state.inactive_level)
        true -> state
      end

    {:noreply, new_state}
  end

  # Handle InputEvents by marking activity.
  @impl true
  def handle_info(_val, state), do: handle_cast(:touch, state)

  # GenServer events
  @impl GenServer
  def handle_call(:state, _from, state), do: {:reply, state, state}

  @impl GenServer
  def handle_cast(:touch, state),
    do: handle_info(:refresh, %{state | last_activity: BacklightAutomation.timestamp()})

  @impl GenServer
  def handle_cast({:set_level, new_level}, state), do: {:noreply, set_level(state, new_level)}

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
  @spec active?(map()) :: boolean()
  def active?(%{last_activity: last_activity, dim_interval: dim_interval} = _state),
    do: last_activity + dim_interval > BacklightAutomation.timestamp()

  defp start_input_devices(%{input_devices_started?: true} = state), do: state

  defp start_input_devices(state) do
    Logger.debug("attempting to find input devices")

    with [_] = devices <- InputDevice.all(),
         [_] <- InputDevice.start_all(devices) do
      %{state | input_devices: devices, input_devices_started?: true}
    else
      err ->
        Logger.warning("err starting input devices #{inspect(err)}")
        state
    end
  end

  defp set_level(
         %{backlight: %BacklightDevice{} = backlight, current_level: current_level} = state,
         new_level
       )
       when is_valid_level(new_level) and current_level != new_level do
    Logger.warning("about to set level to #{new_level} from #{current_level}")
    BacklightDevice.set_level(backlight, new_level)
    broadcast_level_change(state, new_level)
    %{state | current_level: new_level}
  end

  defp set_level(state, _new_level), do: state

  defp ensure_valid_backlight(%{backlight: backlight} = state) do
    if BacklightDevice.valid?(backlight),
      do: state,
      else: %{state | backlight: BacklightDevice.new()}
  end

  defp broadcast_level_change(
         %{pubsub_name: pubsub_name, current_level: current_level} = state,
         new_level
       )
       when not is_nil(pubsub_name) do
    Phoenix.PubSub.broadcast(
      pubsub_name,
      BacklightAutomation.pubsub_topic(),
      {:level_change,
       %{current_level: current_level, new_level: new_level, active?: active?(state)}}
    )
  end

  defp broadcast_level_change(state, _new_level) do
    Logger.debug("cannot broadcast level change #{inspect(state)}")
    :ok
  end
end
