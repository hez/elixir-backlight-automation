defmodule BacklightAutomation.BacklightDevice do
  require Logger
  @control_file "brightness"
  @max_brightness_file "max_brightness"

  @default_directory Path.join(~W{/ sys class backlight})
  @default_max 255

  defstruct base_directory: @default_directory, directory: nil, max_brightness: @default_max

  @type t() :: %__MODULE__{}
  @type ok_t() :: {:ok, t()}

  @spec new() :: t()
  def new, do: %__MODULE__{} |> find_device_directory() |> find_max_brightness()

  @spec set_level(t(), integer()) :: :ok | :error
  def set_level(%__MODULE__{} = backlight, new_level) do
    file = control_file(backlight)

    case File.write(file, Integer.to_string(new_level), [:write]) do
      :ok ->
        Logger.debug("Wrote new #{new_level} level to control file, #{file}")
        :ok

      err ->
        Logger.warning("Failed to write new control level, #{inspect(err)} to #{file}")
        :error
    end
  end

  @spec control_file(t()) :: String.t()
  def control_file(%__MODULE__{} = backlight), do: Path.join([backlight.directory, @control_file])

  @spec max_brightness_file(t()) :: String.t()
  def max_brightness_file(%__MODULE__{} = backlight) do
    if valid?(backlight) do
      Path.join([backlight.directory, @max_brightness_file])
    else
      ""
    end
  end

  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{directory: dir}) when is_binary(dir), do: true
  def valid?(_), do: false

  def find_device_directory(%__MODULE__{} = backlight) do
    case File.ls(backlight.base_directory) do
      {:ok, [_] = dirs} ->
        Logger.debug(
          "found the following dirs for possible control files, picking the first #{inspect(dirs)}"
        )

        dir = Path.join([backlight.base_directory, List.first(dirs)])
        %{backlight | directory: dir}

      err ->
        Logger.warning("failed to find control file, #{inspect(err)}")
        backlight
    end
  end

  def find_max_brightness(%__MODULE__{} = backlight) do
    file = max_brightness_file(backlight)

    if File.exists?(file) do
      case File.read(file) do
        {:ok, max_brightness} ->
          {max_int, _} = Integer.parse(max_brightness)
          %{backlight | max_brightness: max_int}

        err ->
          Logger.warning("failed to read max brightness, #{inspect(err)}")
          backlight
      end
    else
      Logger.warning("invalid max brightness file")
      backlight
    end
  end
end
