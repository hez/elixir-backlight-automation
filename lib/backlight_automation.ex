defmodule BacklightAutomation do
  # TODO Allow for ../intel_backlight/..
  alias BacklightAutomation.Server

  def timestamp, do: System.monotonic_time(:second)

  def current_level, do: Server.current_level()
  def active_level(new_level), do: Server.active_level(new_level)
  def inactive_level(new_level), do: Server.inactive_level(new_level)
  def dim_interval(interval_in_sec), do: Server.dim_interval(interval_in_sec)
  def max_brightness, do: backlight().max_brightness
  def active?, do: Server.active?(state())

  def set_level(new_level) do
    if active?(), do: active_level(new_level), else: inactive_level(new_level)
  end

  def touch, do: Server.touch()

  defp state, do: Server.state()
  defp backlight, do: state().backlight
end
