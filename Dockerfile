FROM hexpm/elixir:1.18.3-erlang-27.3-debian-bullseye-20240408 as build

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git nodejs npm \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set environment variables
ENV MIX_ENV=prod \
    LANG=C.UTF-8

# Create app directory and copy the Elixir project into it
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy configuration files
COPY config ./config
COPY mix.exs mix.lock ./

# Install mix dependencies
RUN mix deps.get --only prod && \
    mix deps.compile

# Copy assets
COPY assets ./assets
COPY priv ./priv

# Compile and build assets
RUN cd assets && npm install && \
    npm run deploy && \
    cd .. && \
    mix assets.deploy

# Copy all application files
COPY lib ./lib
COPY rel ./rel

# Compile the application
RUN mix compile

# Build the release
RUN mix release

# Start a new build stage for the final image
FROM debian:bullseye-slim

# Install runtime dependencies
RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
    && apt-get clean && rm -f /var/lib/apt/lists/*_* \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

# Set environment variables
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    MIX_ENV=prod \
    PHX_SERVER=true

WORKDIR /app

# Create a non-root user and set permissions
RUN useradd --create-home app && \
    chown -R app: /app

# Copy the release from the build stage
COPY --from=build --chown=app:app /app/_build/prod/rel/messenger ./

# Set the user
USER app

# Set the entrypoint
ENTRYPOINT ["/app/bin/messenger"]

# Set default command
CMD ["start"]

# Expose the port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:4000/ || exit 1
