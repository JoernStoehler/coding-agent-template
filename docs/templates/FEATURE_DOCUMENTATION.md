# Feature: [Feature Name]

## Overview
[1-2 sentence description of what this feature does]

## Quick Start
```bash
# Minimal example to get started
[code example]
```

## Purpose
- **Problem it solves**: [What problem does this address?]
- **Target users**: [Who will use this feature?]
- **Key benefits**: [Why is this valuable?]

## Architecture

### Components
1. **[Component Name]** (`src/path/to/component.py`)
   - Purpose: [What it does]
   - Dependencies: [What it needs]
   - Interfaces: [How others interact with it]

2. **[Component Name]** (`src/path/to/component.py`)
   - Purpose: [What it does]
   - Dependencies: [What it needs]
   - Interfaces: [How others interact with it]

### Data Flow
```
[User Input] -> [Component A] -> [Component B] -> [Output]
                      |               |
                      v               v
                 [Database]      [External API]
```

## Implementation Details

### Key Files
- `src/services/feature_service.py` - Main business logic
- `src/api/feature_endpoints.py` - API endpoints
- `src/models/feature_model.py` - Data models
- `tests/test_feature_service.py` - Test coverage

### Configuration
```python
# Required environment variables
FEATURE_ENABLED=true
FEATURE_TIMEOUT=30
FEATURE_MAX_RETRIES=3
```

### Database Schema
```sql
-- If applicable, show relevant tables
CREATE TABLE feature_data (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    data JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
```

## Usage Examples

### Basic Usage
```python
from src.services.feature_service import FeatureService

service = FeatureService()
result = service.process(data)
```

### Advanced Usage
```python
# With configuration
service = FeatureService(
    timeout=60,
    retry_policy=ExponentialBackoff()
)

# Async usage
async def process_async():
    result = await service.process_async(data)
    return result
```

### Error Handling
```python
try:
    result = service.process(data)
except FeatureValidationError as e:
    # Handle validation errors
    logger.error(f"Validation failed: {e}")
except FeatureTimeoutError as e:
    # Handle timeouts
    logger.error(f"Operation timed out: {e}")
```

## API Reference

### Endpoints
```yaml
POST /api/v1/feature
  Request:
    - data: object (required)
    - options: object (optional)
  Response:
    - result: object
    - metadata: object

GET /api/v1/feature/{id}
  Response:
    - data: object
    - status: string
```

### Service Methods
```python
class FeatureService:
    def process(self, data: Dict[str, Any]) -> Result:
        """Process feature data"""
        
    def validate(self, data: Dict[str, Any]) -> bool:
        """Validate input data"""
        
    async def process_async(self, data: Dict[str, Any]) -> Result:
        """Async processing"""
```

## Testing

### Unit Tests
```bash
pytest tests/unit/test_feature_service.py -v
```

### Integration Tests
```bash
pytest tests/integration/test_feature_integration.py -v
```

### Performance Tests
```python
# Benchmark example
def test_feature_performance(benchmark):
    service = FeatureService()
    result = benchmark(service.process, test_data)
    assert result.duration < 0.1  # 100ms threshold
```

## Monitoring

### Metrics
- `feature.requests.total` - Total requests
- `feature.requests.duration` - Request duration
- `feature.errors.total` - Error count by type

### Logs
```json
{
  "timestamp": "2025-01-04T12:00:00Z",
  "level": "INFO",
  "service": "feature_service",
  "message": "Processing completed",
  "duration_ms": 45,
  "user_id": "123"
}
```

### Alerts
- High error rate: >5% errors in 5 minutes
- Slow responses: p95 latency >1s
- Resource exhaustion: Memory >80%

## Troubleshooting

### Common Issues

1. **Feature not working**
   - Check: Is `FEATURE_ENABLED=true`?
   - Check: Are all dependencies running?
   - Solution: Review logs for specific errors

2. **Performance degradation**
   - Check: Database query performance
   - Check: External API latency
   - Solution: Enable caching, optimize queries

3. **Data validation errors**
   - Check: Input data format
   - Check: Schema version compatibility
   - Solution: Update data transformers

### Debug Mode
```bash
# Enable debug logging
LOG_LEVEL=DEBUG python -m src.main

# Enable profiling
PROFILING_ENABLED=true python -m src.main
```

## Migration Guide

### From Version 1.x to 2.x
1. Update configuration:
   ```diff
   - FEATURE_OLD_SETTING=value
   + FEATURE_NEW_SETTING=value
   ```

2. Update code:
   ```python
   # Old way
   service.old_method()
   
   # New way
   service.new_method()
   ```

3. Run migration:
   ```bash
   python scripts/migrate_feature_v2.py
   ```

## Security Considerations

- **Authentication**: All endpoints require valid API token
- **Authorization**: Role-based access control (RBAC)
- **Data Privacy**: PII is encrypted at rest
- **Rate Limiting**: 100 requests per minute per user

## Performance Optimization

### Caching Strategy
```python
@cache(ttl=300)  # 5 minute cache
def get_feature_data(user_id: str) -> Dict:
    return expensive_calculation()
```

### Database Optimization
- Indexes on frequently queried columns
- Partitioning for time-series data
- Connection pooling configured

## Related Documentation

- @docs/architecture/SYSTEM_OVERVIEW.md - Overall architecture
- @docs/api/REST_API_GUIDE.md - Complete API reference
- @docs/guides/DEPLOYMENT.md - Deployment instructions
- @.claude/commands/feature_commands.md - CLI commands

## Changelog

### Version 2.0.0 (2025-01-04)
- Added async support
- Improved error handling
- Performance optimizations

### Version 1.0.0 (2024-12-01)
- Initial release