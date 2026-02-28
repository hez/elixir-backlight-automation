defmodule BacklightAutomation do
  # TODO Allow for ../intel_backlight/..
  alias BacklightAutomation.Server

  @type t :: %__MODULE__{
          backlight: BacklightAutomation.BacklightDevice.t(),
          pubsub_name: atom() | nil,
          current_level: integer() | nil,
          active_level: integer() | nil,
          dim_interval: integer() | nil,
          inactive_level: integer() | nil,
          last_activity: integer() | nil,
          input_devices: list() | nil,
          input_devices_started?: boolean()
        }

  defstruct backlight: nil,
            pubsub_name: nil,
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

  @spec new(Keyword.t()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      backlight: BacklightAutomation.BacklightDevice.new(),
      pubsub_name: Keyword.get(opts, :pubsub),
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
  def pubsub_topic, do: "backlight_automation"

  defdelegate active?, to: Server
  defdelegate active_level(new_level), to: Server
  defdelegate current_level, to: Server
  defdelegate dim_interval(interval_in_sec), to: Server
  defdelegate inactive_level(new_level), to: Server
  defdelegate max_brightness, to: Server
  defdelegate set_level(new_level), to: Server
  defdelegate state, to: Server
  defdelegate touch, to: Server
end
