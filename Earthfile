VERSION 0.6

all:
  BUILD +check

deps:
  FROM elixir:1.13-alpine
  RUN apk add git
  COPY mix.exs .
  COPY mix.lock .
  RUN mix local.rebar --force \
      && mix local.hex --force \
      && mix deps.get

check:
  FROM +deps

  COPY --dir lib/ test/ ./

  COPY docker-compose.yml ./
  WITH DOCKER --compose docker-compose.yml
    RUN mix test
  END

