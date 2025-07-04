# Service: [Service Name]

## Purpose
[One sentence describing what this service does]

## Quick Reference
```python
# Import
from src.services.service_name import ServiceName

# Basic usage
service = ServiceName()
result = service.main_method(data)
```

## Dependencies

### Internal Dependencies
- `src/models/data_model.py` - Data structures used
- `src/utils/helpers.py` - Utility functions
- `src/config.py` - Configuration management

### External Dependencies
```txt
requests>=2.31.0  # HTTP client
redis>=5.0.0      # Caching layer
pydantic>=2.0.0   # Data validation
```

## Interface

### Public Methods

#### `__init__(config: Optional[Dict] = None)`
Initialize the service with optional configuration.

**Parameters:**
- `config`: Optional configuration overrides

**Example:**
```python
service = ServiceName({
    'timeout': 30,
    'retry_count': 3
})
```

#### `main_method(data: DataModel) -> ResultModel`
Primary method that processes input data.

**Parameters:**
- `data`: Input data conforming to DataModel schema

**Returns:**
- `ResultModel`: Processed result

**Raises:**
- `ValidationError`: Invalid input data
- `ProcessingError`: Processing failure
- `TimeoutError`: Operation timeout

**Example:**
```python
try:
    result = service.main_method(data)
    print(f"Success: {result.status}")
except ValidationError as e:
    print(f"Invalid data: {e}")
```

### Data Models

#### Input Model
```python
class DataModel(BaseModel):
    id: str
    content: Dict[str, Any]
    metadata: Optional[Dict] = None
    
    class Config:
        json_schema_extra = {
            "example": {
                "id": "123",
                "content": {"key": "value"},
                "metadata": {"source": "api"}
            }
        }
```

#### Output Model
```python
class ResultModel(BaseModel):
    id: str
    status: Literal["success", "partial", "failed"]
    data: Optional[Dict[str, Any]]
    errors: List[str] = []
    processing_time_ms: float
```

## Implementation Details

### Core Algorithm
```python
def main_method(self, data: DataModel) -> ResultModel:
    """
    Process data through three stages:
    1. Validation and preprocessing
    2. Core transformation
    3. Post-processing and formatting
    """
    # Stage 1: Validate
    validated_data = self._validate_input(data)
    
    # Stage 2: Transform
    transformed = self._apply_transformation(validated_data)
    
    # Stage 3: Format output
    return self._format_result(transformed)
```

### Error Handling Strategy
1. **Validation Errors**: Return immediately with descriptive error
2. **Transient Errors**: Retry with exponential backoff
3. **Fatal Errors**: Log, alert, and propagate

### Performance Characteristics
- **Time Complexity**: O(n) for n items
- **Space Complexity**: O(1) - processes streaming
- **Typical Latency**: 50ms p50, 200ms p99
- **Throughput**: 1000 requests/second

## Configuration

### Environment Variables
```bash
SERVICE_NAME_TIMEOUT=30          # Request timeout in seconds
SERVICE_NAME_RETRY_COUNT=3       # Number of retries
SERVICE_NAME_CACHE_TTL=300       # Cache TTL in seconds
SERVICE_NAME_BATCH_SIZE=100      # Batch processing size
```

### Configuration Object
```python
{
    "timeout": 30,
    "retry_count": 3,
    "retry_delay": 1.0,
    "cache_enabled": true,
    "cache_ttl": 300,
    "batch_size": 100,
    "concurrent_workers": 4
}
```

## Testing

### Unit Tests
Located in `tests/unit/test_service_name.py`

```python
def test_main_method_success():
    service = ServiceName()
    data = DataModel(id="1", content={"test": "data"})
    result = service.main_method(data)
    assert result.status == "success"
```

### Integration Tests
Located in `tests/integration/test_service_name_integration.py`

### Performance Tests
```python
def test_performance_benchmark(benchmark):
    service = ServiceName()
    data = generate_test_data()
    result = benchmark(service.main_method, data)
    assert result.processing_time_ms < 100
```

## Monitoring and Debugging

### Key Metrics
- `service_name.requests.total` - Total requests
- `service_name.requests.duration` - Request duration histogram
- `service_name.errors.total` - Errors by type
- `service_name.cache.hit_rate` - Cache effectiveness

### Log Examples
```json
{
  "timestamp": "2025-01-04T10:30:00Z",
  "level": "INFO",
  "service": "service_name",
  "method": "main_method",
  "request_id": "abc123",
  "duration_ms": 45,
  "status": "success"
}
```

### Debug Mode
```python
# Enable debug logging
service = ServiceName(debug=True)

# Or via environment
DEBUG=true python app.py
```

## Common Issues and Solutions

### Issue: Timeout Errors
**Symptoms**: `TimeoutError` after 30 seconds
**Cause**: Large data processing or slow external calls
**Solution**: 
- Increase timeout: `SERVICE_NAME_TIMEOUT=60`
- Implement pagination for large datasets
- Add caching for expensive operations

### Issue: High Memory Usage
**Symptoms**: Memory grows unbounded
**Cause**: Loading entire dataset into memory
**Solution**:
- Use streaming/generator patterns
- Process in smaller batches
- Implement memory limits

### Issue: Rate Limiting
**Symptoms**: `429 Too Many Requests` errors
**Cause**: Exceeding external API limits
**Solution**:
- Implement rate limiting
- Use exponential backoff
- Cache API responses

## Security Considerations

### Input Validation
- All inputs validated against schema
- SQL injection prevention via parameterized queries
- XSS prevention through output encoding

### Authentication/Authorization
- Service-to-service auth via API keys
- User context passed via headers
- Role-based access control (RBAC)

### Data Privacy
- PII fields encrypted at rest
- Audit logging for data access
- Data retention policies enforced

## Performance Tuning

### Optimization Techniques
1. **Caching**: Redis cache for frequent queries
2. **Batching**: Process multiple items together
3. **Async I/O**: Non-blocking external calls
4. **Connection Pooling**: Reuse database connections

### Benchmarks
```
Operation          | p50   | p95   | p99
-------------------|-------|-------|-------
Single item        | 10ms  | 50ms  | 100ms
Batch (100 items)  | 100ms | 500ms | 1s
With caching       | 1ms   | 5ms   | 10ms
```

## Related Services

- `auth_service.py` - Authentication and authorization
- `notification_service.py` - Sends notifications
- `storage_service.py` - Persistent storage

## Version History

### v2.0.0 (2025-01-04)
- Added async support
- Improved error handling
- Performance optimizations

### v1.0.0 (2024-10-01)
- Initial release

## Migration Notes

### Upgrading from v1.x to v2.x
1. Update imports:
   ```python
   # Old
   from services import ServiceName
   
   # New
   from src.services.service_name import ServiceName
   ```

2. Update method calls:
   ```python
   # Old (synchronous only)
   result = service.process(data)
   
   # New (async support)
   result = await service.main_method(data)
   ```

## API Compatibility

This service implements the standard service interface:
```python
class ServiceInterface(Protocol):
    def main_method(self, data: DataModel) -> ResultModel: ...
    async def main_method_async(self, data: DataModel) -> ResultModel: ...
    def health_check(self) -> HealthStatus: ...
```

## Additional Resources

- @docs/architecture/SERVICES_OVERVIEW.md - All services
- @docs/api/SERVICE_API.md - REST API wrapper
- @.claude/commands/service_commands.md - Useful commands
- Internal Wiki: [Service Name Documentation](#)