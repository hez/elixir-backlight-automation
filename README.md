# RpiScreenDimmer

A automatic screen dimmer for the Raspberry Pi 7" touch screen.

## Installation

```elixir
def deps do
  [
    {:rpi_screen_dimmer, github: "hez/rpi-screen-dimmer", tag: "v0.1.2"}
  ]
end
```

## Usage

Add the server to your application start up.

```elixir
children = [
  # ....
  {RpiScreenDimmer, [active_level: 100, inactive_level: 30, dim_interval: 60]}
]
```

You can also manual trigger level changes, but the server will override your changes on next check. Instead change the `active_level` or `inactive_level`.

```elixir
iex> RpiScreenDimmer.inactive_level(25)
:ok
iex> RpiScreenDimmer.active_level(90)
:ok
```

The interval for going inactive can also be changed, it takes a number of seconds before dimming the screen:

```elixir
iex> RpiScreenDimmer.dim_interval(90)
```
