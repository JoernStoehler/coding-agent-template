#!/bin/bash
# Run OTLP telemetry collector for coding agents
# Exit on any error so VS Code terminal shows failure
#
# PURPOSE: Collect telemetry from Claude/Gemini CLIs and forward to observability backend
# This enables cost tracking and performance analysis for AI-powered coding agents
#
# DATA FLOW:
# 1. Claude/Gemini CLI -> localhost:4317 (gRPC) -> this collector
# 2. Collector batches data -> observability backend (Honeycomb/etc)
#
# TROUBLESHOOTING:
# - "HONEYCOMB_API_KEY not set" - Set it in your .env file
# - "Invalid API key" - Check key format and region
# - "Connection refused on 4317" - This script isn't running
# - "No telemetry data" - Check CLI settings.json files were created
# - Health check: curl http://localhost:13133/health
#
# REQUIRED ENV VARS:
# - HONEYCOMB_API_KEY: Your Honeycomb ingest key
# - HONEYCOMB_DATASET: Dataset name (default: coding-agent)
# - HONEYCOMB_API_ENDPOINT: API endpoint (default: api.honeycomb.io for US)

set -euo pipefail  # Exit on error, undefined variable, or pipe failure

echo "🚀 Starting OTLP Telemetry Collector for Coding Agents..."

# Validate Honeycomb API key
if [ -z "${HONEYCOMB_API_KEY:-}" ]; then
    echo "❌ ERROR: HONEYCOMB_API_KEY not set"
    echo "   Please set it in your .env file"
    exit 1
fi

# Set defaults
HONEYCOMB_DATASET="${HONEYCOMB_DATASET:-coding-agent}"
HONEYCOMB_API_ENDPOINT="${HONEYCOMB_API_ENDPOINT:-api.eu1.honeycomb.io}"

# Validate API key with endpoint
echo "🔐 Validating Honeycomb API key..."
if ! curl -f -s --max-time 10 \
    -H "X-Honeycomb-Team: $HONEYCOMB_API_KEY" \
    "https://${HONEYCOMB_API_ENDPOINT}/1/auth" > /dev/null; then
    echo "❌ ERROR: Invalid Honeycomb API key or network issue"
    echo "   Please check your .env file and API endpoint"
    exit 1
fi

# Create OTLP collector config with secure temp file
if ! CONFIG_FILE=$(mktemp -t otel-config-XXXXXX.yaml); then
    echo "❌ ERROR: Failed to create temporary config file"
    exit 1
fi
trap 'rm -f "$CONFIG_FILE"' EXIT

cat > "$CONFIG_FILE" << EOF
# OpenTelemetry Collector Configuration for Coding Agents
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317  # Claude/Gemini send here
      http:
        endpoint: 0.0.0.0:4318  # Alternative HTTP endpoint

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
    send_batch_max_size: 2048
  
  # Add resource attributes for better filtering
  resource:
    attributes:
      - key: service.namespace
        value: coding-agent
        action: upsert
      - key: deployment.environment
        value: ${ENVIRONMENT:-development}
        action: upsert

exporters:
  debug:
    verbosity: basic  # Reduced verbosity for production use
    sampling_initial: 10
    sampling_thereafter: 100
  
  otlp:
    endpoint: "${HONEYCOMB_API_ENDPOINT}:443"
    headers:
      "x-honeycomb-team": "\${HONEYCOMB_API_KEY}"
      "x-honeycomb-dataset": "\${HONEYCOMB_DATASET}"

extensions:
  health_check:
    endpoint: 0.0.0.0:13133
    path: /health

service:
  extensions: [health_check]
  telemetry:
    logs:
      level: info
    metrics:
      level: none  # Disable prometheus metrics
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch, resource]
      exporters: [debug, otlp]
    metrics:
      receivers: [otlp]
      processors: [batch, resource]
      exporters: [otlp]  # No debug for metrics to reduce noise
    logs:
      receivers: [otlp]
      processors: [batch, resource]
      exporters: [debug, otlp]
EOF

# Check if otelcol-contrib is installed
OTELCOL_BIN="otelcol-contrib"
if ! command -v "$OTELCOL_BIN" >/dev/null 2>&1; then
    echo "📦 OTLP collector not found, downloading..."
    
    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT
    
    # Get latest version
    echo "   Fetching latest version information..."
    OTLP_VERSION=$(curl -sSf --max-time 30 https://api.github.com/repos/open-telemetry/opentelemetry-collector-releases/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$OTLP_VERSION" ]; then
        echo "❌ ERROR: Failed to get OTLP collector version"
        exit 1
    fi
    
    echo "   Downloading version $OTLP_VERSION..."
    VERSION_NO_V="${OTLP_VERSION#v}"
    
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        *) echo "❌ ERROR: Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    DOWNLOAD_URL="https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/${OTLP_VERSION}/otelcol-contrib_${VERSION_NO_V}_${OS}_${ARCH}.tar.gz"
    
    # Download binary
    if ! curl -sSfL --max-time 120 --retry 3 -o "$TEMP_DIR/otelcol.tar.gz" "$DOWNLOAD_URL"; then
        echo "❌ ERROR: Failed to download OTLP collector"
        exit 1
    fi
    
    # Extract to ~/.local/bin
    mkdir -p "$HOME/.local/bin"
    tar -xzf "$TEMP_DIR/otelcol.tar.gz" -C "$HOME/.local/bin" otelcol-contrib
    chmod +x "$HOME/.local/bin/otelcol-contrib"
    
    OTELCOL_BIN="$HOME/.local/bin/otelcol-contrib"
    echo "   ✅ Downloaded to $OTELCOL_BIN"
fi

# Configure AI CLI telemetry settings
echo "📝 Configuring AI CLI telemetry settings..."

# Function to update JSON settings file
update_settings_file() {
    local settings_file="$1"
    local expected_content="$2"
    local cli_name="$3"
    
    local update_needed=false
    if [ ! -f "$settings_file" ]; then
        update_needed=true
    else
        # Check if content matches expected configuration
        if ! python3 -c "
import json, sys
try:
    with open('$settings_file') as f:
        current = json.load(f)
    expected = json.loads('''$expected_content''')
    # Deep comparison of nested dictionaries
    def dict_contains(d1, d2):
        for k, v in d2.items():
            if k not in d1:
                return False
            if isinstance(v, dict):
                if not isinstance(d1[k], dict) or not dict_contains(d1[k], v):
                    return False
            elif d1[k] != v:
                return False
        return True
    if not dict_contains(current, expected):
        sys.exit(1)
    sys.exit(0)
except:
    sys.exit(1)
" 2>/dev/null; then
            update_needed=true
        fi
    fi
    
    if [ "$update_needed" = true ]; then
        mkdir -p "$(dirname "$settings_file")"
        echo "$expected_content" > "$settings_file"
        echo "   ✅ Updated $cli_name telemetry settings"
    else
        echo "   ✅ $cli_name telemetry settings already configured"
    fi
}

# Claude CLI configuration
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CLAUDE_EXPECTED_CONTENT='{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp",
    "OTEL_LOGS_EXPORTER": "otlp",
    "OTEL_EXPORTER_OTLP_PROTOCOL": "grpc",
    "OTEL_EXPORTER_OTLP_ENDPOINT": "http://localhost:4317",
    "OTEL_SERVICE_NAME": "claude-cli",
    "OTEL_RESOURCE_ATTRIBUTES": "service.name=claude-cli,service.namespace=coding-agent"
  }
}'

update_settings_file "$CLAUDE_SETTINGS" "$CLAUDE_EXPECTED_CONTENT" "Claude"

# Gemini CLI configuration
GEMINI_SETTINGS="$HOME/.gemini/settings.json"
GEMINI_EXPECTED_CONTENT='{
  "telemetry": {
    "enabled": true,
    "target": "local",
    "otlpEndpoint": "http://localhost:4317",
    "logPrompts": true,
    "serviceName": "gemini-cli",
    "resourceAttributes": {
      "service.namespace": "coding-agent"
    }
  }
}'

update_settings_file "$GEMINI_SETTINGS" "$GEMINI_EXPECTED_CONTENT" "Gemini"

echo "✅ Configuration validated"
echo "📊 Starting collector on localhost:4317..."
echo "   Health: http://localhost:13133/health"
echo "   Dataset: $HONEYCOMB_DATASET"
echo ""
echo "Press Ctrl+C to stop"
echo "─────────────────────────────────────────"

# Run collector in foreground
exec "$OTELCOL_BIN" --config="$CONFIG_FILE"