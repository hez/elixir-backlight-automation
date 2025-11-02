# BacklightAutomation

An automatic screen dimmer for the Raspberry Pi 7" touch screen.

## Installation

```elixir
def deps do
  [
    {:backlight_automation, github: "hez/elixir-backlight-automation", tag: "v0.2.1"}
  ]
end
```

## Usage

Add the server to your application start up.

```elixir
children = [
  # ....
  {BacklightAutomation.Server, [active_level: 100, inactive_level: 30, dim_interval: 60]}
]
```

You can also manual trigger level changes, which will set the level of the current state, ie idle will set the inactive level. Individual state levels can be explicitly set via `active_level` or `inactive_level`.

```elixir
iex> BacklightAutomation.set_level(75)
:ok
iex> BacklightAutomation.inactive_level(25)
:ok
iex> BacklightAutomation.active_level(90)
:ok
```

The interval for going inactive can also be changed, it takes a number of seconds before dimming the screen:

```elixir
iex> BacklightAutomation.dim_interval(90)
```

The screen can be trigger awake with the `touch` function

```elixir
iex> BacklightAutomation.touch()
```


## Configuration

The BacklightAutomation.Application takes a keyword list where you can override defaults.

Valid options
  - active_level
  - inactive_level
  - dim_interval
  - screen_names
