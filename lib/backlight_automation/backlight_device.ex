defmodule BacklightAutomation.BacklightDevice do
  require Logger
  @control_file "brightness"

  @default_directory Path.join(~W{sys class backlight})
  @default_max 255

  defstruct base_directory: @default_directory, directory: nil, max_brightness: @default_max

  @type t() :: %__MODULE__{}
  @type ok_t() :: {:ok, t()}

  @spec new() :: ok_t() | :error
  def new, do: find_device_directory(%__MODULE__{})

  @spec set_level(t(), integer()) :: :ok | :error
  def set_level(backlight, new_level) do
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
  def control_file(backlight), do: Path.join([backlight.directory, @control_file])

  defp find_device_directory(backlight) do
    case File.ls(backlight.base_directory) do
      {:ok, dirs} ->
        Logger.debug(
          "found the following dirs for possible control files, picking the first #{inspect(dirs)}"
        )

        dir = Path.join([backlight.base_directory, List.first(dirs)])
        {:ok, %{backlight | directory: dir}}

      err ->
        Logger.error("failed to find control file, #{inspect(err)}")
        :error
    end
  end
end
