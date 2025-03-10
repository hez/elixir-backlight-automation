# BacklightAutomation

An automatic screen dimmer for the Raspberry Pi 7" touch screen.

## Installation

```elixir
def deps do
  [
    {:backlight_automation, github: "hez/elixir-backlight-automation", tag: "v0.2.0"}
  ]
end
```

## Usage

Add the server to your application start up.

```elixir
children = [
  # ....
  {BacklightAutomation, [active_level: 100, inactive_level: 30, dim_interval: 60]}
]
```

You can also manual trigger level changes, but the server will override your changes on next check. Instead change the `active_level` or `inactive_level`.

```elixir
iex> BacklightAutomation.inactive_level(25)
:ok
iex> BacklightAutomation.active_level(90)
:ok
```

The interval for going inactive can also be changed, it takes a number of seconds before dimming the screen:

```elixir
iex> BacklightAutomation.dim_interval(90)
```
