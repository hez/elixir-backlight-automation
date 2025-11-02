defmodule BacklightAutomation.InputDevice do
  require Logger

  @default_screen_names [
    # Raspberry pi touchscreens
    "raspberrypi-ts",
    "generic ft5x06 (79)",
    "10-0038 generic ft5x06 (79)",
    # Dell laptop touchscreen
    "G2Touch Multi-Touch by G2TSP"
  ]

  def start_all([_] = devices), do: Enum.map(devices, &InputEvent.start_link/1)

  def screen_names, do: @default_screen_names

  @spec all(list(String.t())) :: list(InputEvent.Info.t())
  def all(screen_names \\ @default_screen_names) do
    InputEvent.enumerate()
    |> Enum.filter(fn {_name, info} -> Enum.member?(screen_names, info.name) end)
    |> Enum.map(&elem(&1, 0))
  end
end
