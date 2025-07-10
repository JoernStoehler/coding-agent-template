# Base development environment for coding agents
# Provides: Python 3.11, Node.js 20, common dev tools
# Fork this and modify for your specific needs
#
# DESIGN DECISIONS:
# - Multi-tool approach: This is a development environment for AI agents that need
#   Python, Node.js, and various CLI tools. Single-purpose containers aren't suitable.
# - Size over speed: We prioritize development speed over image size optimization.
#   Rebuild times matter more than final image size in our fast development cycle.
# - Trust over verification: We skip hash verification for downloads from GitHub/trusted
#   sources to reduce complexity. We trust the sources and prioritize simplicity.
# - AMD64 only: We only support AMD64 architecture - this is intentional and sufficient.
# - Loose reproducibility: Exact build reproducibility isn't critical during fast
#   development phase. We'll revisit this when we slow down or go to production.

FROM mcr.microsoft.com/devcontainers/python:3.11

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install additional tools not in base image
# Base image already includes: python, pip, git, curl, wget, sudo, build-essential, etc.
RUN apt-get update && apt-get install -y \
    # Terminal multiplexers for background processes
    screen \
    tmux \
    # Additional useful tools
    htop \
    tree \
    bc \
    ripgrep \
    # Process manager for background services
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install uv (modern Python package manager)
# Using curl|bash installation since apt-get version is outdated
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && echo 'export PATH="/root/.local/bin:$PATH"' >> /root/.bashrc

# Install Node.js 20 LTS (official method)
# Using curl|bash from NodeSource - this is the recommended installation method
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Verify installations
RUN python --version && node --version && npm --version

# Install Python packages for MCP servers using uv
# uv is faster and more reliable than pip for package management
RUN /root/.local/bin/uv pip install --system \
    fastmcp \
    requests \
    python-dotenv \
    pydantic \
    click \
    rich \
    j2cli

# Install GitHub CLI
# Using official GitHub repository and GPG key verification
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install Cloudflared (AMD64 only)
# Using latest release - we trust GitHub releases and skip hash verification for simplicity
RUN curl -L --connect-timeout 30 --max-time 300 --retry 3 --retry-delay 10 \
    --output cloudflared.deb \
    https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb \
    && dpkg -i cloudflared.deb \
    && rm cloudflared.deb

# Install OTEL Collector Contrib (version pinned)
# Version is hardcoded due to inconsistent filenames in releases - intentional decision
RUN curl -L --connect-timeout 30 --max-time 300 --retry 3 --retry-delay 10 \
    --output /tmp/otelcol-contrib.deb \
    "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.96.0/otelcol-contrib_0.96.0_linux_amd64.deb" \
    && apt-get update \
    && apt-get install -y /tmp/otelcol-contrib.deb \
    && rm -f /tmp/otelcol-contrib.deb \
    && rm -rf /var/lib/apt/lists/*

# Install Starship prompt
# Fast, customizable prompt written in Rust - provides better prompt features than bash scripts
RUN curl -sS https://starship.rs/install.sh | sh -s -- --yes

# Install direnv
# Allows automatic loading of environment variables when entering directories
# We use it to set STARSHIP_CONFIG per worktree for custom prompts
RUN apt-get update && apt-get install -y direnv && rm -rf /var/lib/apt/lists/*

# Copy supervisor configuration files
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY telemetry.conf /etc/supervisor/conf.d/telemetry.conf
COPY otel-config.yaml.j2 /etc/otel/config.yaml.j2


# System directories need root to create, then transfer ownership to vscode
# Note: supervisor logs remain root-owned (use sudo to read them)
RUN mkdir -p /workspaces \
    && mkdir -p /etc/supervisor/conf.d \
    && mkdir -p /var/log/supervisor \
    && mkdir -p /etc/otel \
    && chown -R vscode:vscode /workspaces

USER vscode
WORKDIR /workspaces

# User directories created as vscode user to avoid ownership issues
# CLI tool directories (.claude, .gemini, .config/gh) preserve OAuth tokens across rebuilds
# direnv/allow directory prevents direnv permission issues (legacy fix - may not be needed)
# bash_history file must exist before setting HISTFILE
RUN mkdir -p /home/vscode/.claude \
    && mkdir -p /home/vscode/.gemini \
    && mkdir -p /home/vscode/.config/gh \
    && mkdir -p /home/vscode/.local/share/direnv/allow \
    && mkdir -p /home/vscode/.bash_history_dir \
    && touch /home/vscode/.bash_history_dir/.bash_history

# Configure npm for user-level global packages and install AI CLIs
RUN npm config set prefix '/home/vscode/.local' \
    && npm install -g @anthropic-ai/claude-code @google/gemini-cli

# Default command
CMD ["/bin/bash"]