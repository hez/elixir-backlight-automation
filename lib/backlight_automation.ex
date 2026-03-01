defmodule BacklightAutomation do
  # TODO Allow for ../intel_backlight/..
  use Supervisor

  @type t :: %__MODULE__{
          backlight: BacklightAutomation.BacklightDevice.t(),
          current_level: integer() | nil,
          active_level: integer() | nil,
          dim_interval: integer() | nil,
          inactive_level: integer() | nil,
          last_activity: integer() | nil,
          input_devices: list() | nil,
          input_devices_started?: boolean()
        }

  defstruct backlight: nil,
            current_level: nil,
            active_level: nil,
            dim_interval: nil,
            inactive_level: nil,
            last_activity: nil,
            input_devices: nil,
            input_devices_started?: false

  @active_level_default 255
  @inactive_level_default 30
  @dim_interval_default 30

  def start_link(opts \\ []) do
    {name, rest} = Keyword.pop(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, rest, name: name)
  end

  @impl Supervisor
  def init(opts \\ []) do
    children = [
      {Registry, name: registry_name(), keys: :duplicate},
      {BacklightAutomation.Server, opts}
    ]

    opts = [strategy: :rest_for_one, name: __MODULE__]
    Supervisor.init(children, opts)
  end

  @spec new(Keyword.t()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      backlight: BacklightAutomation.BacklightDevice.new(),
      current_level: nil,
      active_level: Keyword.get(opts, :active_level, @active_level_default),
      dim_interval: Keyword.get(opts, :dim_interval, @dim_interval_default),
      inactive_level: Keyword.get(opts, :inactive_level, @inactive_level_default),
      last_activity: timestamp(),
      input_devices: nil,
      input_devices_started?: false
    }
  end

  def timestamp, do: System.monotonic_time(:second)
  def registry_name, do: Registry.BacklightAutomationPubSub
  def registry_topic, do: "backlight_level_change"
  def register(opts \\ []), do: Registry.register( registry_name(), registry_topic(), opts )

  defdelegate active?, to: BacklightAutomation.Server
  defdelegate active_level(new_level), to: BacklightAutomation.Server
  defdelegate current_level, to: BacklightAutomation.Server
  defdelegate dim_interval(interval_in_sec), to: BacklightAutomation.Server
  defdelegate inactive_level(new_level), to: BacklightAutomation.Server
  defdelegate max_brightness, to: BacklightAutomation.Server
  defdelegate set_level(new_level), to: BacklightAutomation.Server
  defdelegate state, to: BacklightAutomation.Server
  defdelegate touch, to: BacklightAutomation.Server
end
