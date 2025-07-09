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

FROM python:3.11-slim

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
# We install everything in one layer to reduce image size and improve caching
RUN apt-get update && apt-get install -y \
    # Basic system tools
    curl \
    wget \
    git \
    gnupg \
    ca-certificates \
    # Build essentials for some Python packages
    build-essential \
    # Additional utilities
    jq \
    vim \
    # Terminal multiplexers for background processes
    screen \
    tmux \
    # Missing useful tools
    procps \
    htop \
    tree \
    bc \
    ripgrep \
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
    rich

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


# Create non-root user
RUN groupadd -r user && useradd -r -g user -m -s /bin/bash user

# Set up directories and permissions
# Create necessary directories for the development environment
RUN mkdir -p /workspaces \
    && mkdir -p /home/user/.claude \
    && mkdir -p /home/user/.gemini \
    && mkdir -p /home/user/.config/gh \
    && mkdir -p /home/user/.local/share/direnv/allow \
    && chown -R user:user /workspaces /home/user

# Switch to non-root user for security
USER user
WORKDIR /workspaces

# Git configuration is handled by VS Code - no need to set placeholder values

# Set up shell environment with useful aliases and functions
# NOTE: Shell customizations (aliases, functions, environment vars) have been moved
# to postCreateCommand.sh to avoid Dev Containers heredoc parsing issues.
# This ensures reliable builds while maintaining the same functionality.

# Set up bash history persistence directory
RUN mkdir -p /home/user/.bash_history_dir \
    && touch /home/user/.bash_history_dir/.bash_history

# Configure npm for user-level global packages and install Claude CLI
RUN npm config set prefix '/home/user/.local' \
    && npm install -g @anthropic-ai/claude-code

# Default command
CMD ["/bin/bash"]