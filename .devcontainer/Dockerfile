# Base development environment for coding agents
# Provides: Python 3.11, Node.js 20, common dev tools
# Fork this and modify for your specific needs

FROM python:3.11-slim

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies and Node.js
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

# Install Node.js 20 LTS (official method)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Verify installations
RUN python --version && node --version && npm --version

# Install Python packages for MCP servers
RUN pip install --no-cache-dir \
    fastmcp \
    requests \
    python-dotenv \
    pydantic \
    click \
    rich

# Install claude-code CLI
RUN npm install -g @anthropic-ai/claude-code

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install Cloudflared (official method)
RUN curl -L --connect-timeout 30 --max-time 300 --retry 3 --retry-delay 10 \
    --output cloudflared.deb \
    https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb \
    && dpkg -i cloudflared.deb \
    && rm cloudflared.deb

# Install OTEL Collector Contrib (simplified approach)
RUN curl -L --connect-timeout 30 --max-time 300 --retry 3 --retry-delay 10 \
    --output /tmp/otelcol-contrib.deb \
    "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.96.0/otelcol-contrib_0.96.0_linux_amd64.deb" \
    && apt-get update \
    && apt-get install -y /tmp/otelcol-contrib.deb \
    && rm -f /tmp/otelcol-contrib.deb \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r user && useradd -r -g user -m -s /bin/bash user

# Set up directories and permissions
RUN mkdir -p /workspaces \
    && mkdir -p /home/user/.claude \
    && mkdir -p /home/user/.gemini \
    && mkdir -p /home/user/.config/gh \
    && chown -R user:user /workspaces /home/user

# Switch to user
USER user
WORKDIR /workspaces

# Set up git configuration properly
RUN git config --global init.defaultBranch main \
    && git config --global user.name "Coding Agent" \
    && git config --global user.email "agent@example.com" \
    && git config --global core.editor "vim"

# Set up shell environment
RUN echo 'export PATH="/home/user/.local/bin:$PATH"' >> /home/user/.bashrc \
    && echo 'alias ll="ls -la"' >> /home/user/.bashrc \
    && echo 'alias la="ls -la"' >> /home/user/.bashrc \
    && echo 'alias gs="git status"' >> /home/user/.bashrc \
    && echo 'alias gl="git log --oneline -10"' >> /home/user/.bashrc \
    && echo '# Function to load .env files' >> /home/user/.bashrc \
    && echo 'load_env() { ' >> /home/user/.bashrc \
    && echo '    local env_file="${1:-.env}"' >> /home/user/.bashrc \
    && echo '    if [ -f "$env_file" ]; then' >> /home/user/.bashrc \
    && echo '        echo "Loading environment from: $env_file"' >> /home/user/.bashrc \
    && echo '        set -a; source "$env_file"; set +a' >> /home/user/.bashrc \
    && echo '    else' >> /home/user/.bashrc \
    && echo '        echo "Environment file not found: $env_file"' >> /home/user/.bashrc \
    && echo '    fi' >> /home/user/.bashrc \
    && echo '}' >> /home/user/.bashrc

# Set up bash history persistence (volume mount will override this directory)
RUN mkdir -p /home/user/.bash_history_dir \
    && touch /home/user/.bash_history_dir/.bash_history \
    && echo 'export HISTFILE=/home/user/.bash_history_dir/.bash_history' >> /home/user/.bashrc \
    && echo 'export HISTSIZE=10000' >> /home/user/.bashrc \
    && echo 'export HISTFILESIZE=10000' >> /home/user/.bashrc

# Set up Claude config directory (workaround for Anthropic bug)
RUN echo 'export CLAUDE_CONFIG_DIR="/home/user/.claude"' >> /home/user/.bashrc

# Default command
CMD ["/bin/bash"]