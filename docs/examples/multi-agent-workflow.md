# Example: Multi-Agent Workflow

This example shows how multiple agents work together on a larger feature.

## Scenario

Build a complete user dashboard with:
- Frontend (React)
- Backend API (FastAPI)
- Database schema (PostgreSQL)
- Integration tests

## Step 1: Orchestrator Setup

First, create an orchestrator agent to coordinate the work:

```bash
./scripts/setup-agent.sh orchestrator "Coordinate dashboard feature development"
```

Customize its prompt:
```bash
cd /workspaces/orchestrator
cat >> prompt.md << 'EOF'

## Your Role

Coordinate the development of a user dashboard by:
1. Creating specialized agents
2. Assigning clear tasks
3. Monitoring progress via mail
4. Handling integration

## Agents to Create

1. **db-agent**: Design database schema
2. **api-agent**: Build REST API
3. **ui-agent**: Create React components
4. **test-agent**: Write integration tests

## Communication Protocol

- Agents report status via mail
- You respond with guidance
- Coordinate handoffs between agents
- Resolve conflicts
EOF
```

## Step 2: Database Agent

The orchestrator creates:

```bash
./scripts/setup-agent.sh db-agent "Design dashboard database schema"
```

With prompt:
```markdown
## Task: Dashboard Database Schema

Create PostgreSQL schema for user dashboard featuring:
- User activity tracking
- Dashboard preferences
- Widget configurations

## Requirements
- Use migrations (Alembic)
- Include indexes for performance
- Add sample data
- Document schema

## Output
- migration files in `migrations/`
- Schema diagram
- README with setup instructions

## When Complete
Send mail to orchestrator with:
- Migration file locations
- How to run migrations
- Any decisions made
```

## Step 3: API Agent

After database schema is ready:

```bash
./scripts/setup-agent.sh api-agent "Build dashboard REST API"
```

With context from db-agent:
```markdown
## Task: Dashboard API

Build FastAPI endpoints for dashboard.

## Available Schema
The db-agent created these tables:
- users
- dashboard_configs  
- activity_logs
- widgets

See migrations/ for details.

## Required Endpoints
- GET /api/dashboard/{user_id}
- PUT /api/dashboard/{user_id}/config
- GET /api/dashboard/{user_id}/activity
- POST /api/dashboard/{user_id}/widgets

## Requirements
- Use Pydantic models
- Include OpenAPI docs
- Add authentication
- Write unit tests

## Communication
- Check mail for schema updates
- Send progress to orchestrator
- Coordinate with ui-agent on API design
```

## Step 4: Frontend Agent

In parallel with API development:

```bash
./scripts/setup-agent.sh ui-agent "Create dashboard React components"
```

With API specification:
```markdown
## Task: Dashboard UI

Build React dashboard components.

## API Endpoints (from api-agent)
```
GET /api/dashboard/{user_id}
Response: {
  "widgets": [...],
  "preferences": {...},
  "last_login": "..."
}
```

## Components Needed
- DashboardContainer
- WidgetGrid
- ActivityFeed
- PreferencesModal

## Requirements
- Use React hooks
- Responsive design
- Loading states
- Error handling

## Coordinate With
- api-agent: API contracts
- test-agent: Test data
```

## Step 5: Integration Agent

Once components are ready:

```bash
./scripts/setup-agent.sh test-agent "Write dashboard integration tests"
```

## Agent Communication Flow

```
orchestrator
    ├── Creates db-agent
    │   └── db-agent works
    │       └── Sends: "Schema complete"
    │
    ├── Creates api-agent + ui-agent
    │   ├── api-agent: "Need schema details"
    │   │   ├── Reads db-agent's work
    │   │   └── Sends: "API endpoints ready"
    │   │
    │   └── ui-agent: "Need API spec"
    │       ├── Coordinates with api-agent
    │       └── Sends: "UI components ready"
    │
    └── Creates test-agent
        └── test-agent: Tests everything
            └── Sends: "All tests passing"
```

## Mail Examples

### Status Update
```python
mcp__mail__mcp__mail_send(
    from_agent="db-agent",
    to_agents=["orchestrator"],
    subject="Schema Complete",
    body="""
    Completed dashboard schema:
    - 4 tables created
    - Migrations in migrations/001_dashboard.py
    - Run with: alembic upgrade head
    - Sample data included
    
    Key decisions:
    - Used JSONB for widget config (flexible)
    - Added user_id indexes (performance)
    - Soft deletes for audit trail
    """
)
```

### Coordination Request
```python
mcp__mail__mcp__mail_send(
    from_agent="api-agent",
    to_agents=["ui-agent", "orchestrator"],
    subject="API Design Question",
    body="""
    Planning widget endpoint design.
    
    Option 1: Nested under dashboard
    GET /api/dashboard/{id}/widgets
    
    Option 2: Separate resource
    GET /api/widgets?dashboard_id={id}
    
    Which pattern does UI prefer?
    """
)
```

### Blocker Report
```python
mcp__mail__mcp__mail_send(
    from_agent="test-agent",
    to_agents=["orchestrator", "api-agent"],
    subject="Blocked: API Returns 500",
    body="""
    Integration test failing:
    
    Test: test_dashboard_load
    Endpoint: GET /api/dashboard/123
    Error: 500 Internal Server Error
    
    Looks like database connection issue.
    Need api-agent to investigate.
    """
)
```

## Orchestrator Monitoring

The orchestrator agent typically:

```python
# Check status regularly
messages = mcp__mail__mcp__mail_inbox(to_agent="orchestrator")

for msg in messages:
    if not msg['read']:
        full_msg = mcp__mail__mcp__mail_read(message_id=msg['id'])
        
        # Route based on content
        if "blocked" in full_msg['subject'].lower():
            # Handle blockers
            pass
        elif "complete" in full_msg['subject'].lower():
            # Track progress
            pass
        elif "question" in full_msg['subject'].lower():
            # Provide guidance
            pass
```

## Final Integration

Once all agents complete:

```bash
cd /workspaces/main

# Merge in order
git merge db-agent     # Schema first
git merge api-agent    # Then API
git merge ui-agent     # Then UI
git merge test-agent   # Finally tests

# Run everything
alembic upgrade head
python api/main.py &
npm start &
pytest tests/integration/
```

## Benefits of Multi-Agent

1. **Parallel Development**: UI and API built simultaneously
2. **Specialization**: Each agent focuses on its domain
3. **Clear Interfaces**: Forced to define contracts
4. **Easy Debugging**: Isolated work in branches
5. **Natural Documentation**: Mail thread shows decisions

## Common Patterns

### Sequential Dependencies
```
Parser Agent → Validator Agent → Generator Agent
```

### Parallel + Integration
```
Frontend Agent ─┐
                ├─→ Integration Agent
Backend Agent ──┘
```

### Review Cycle
```
Dev Agent → Review Agent → Dev Agent (fixes) → Test Agent
```

### A/B Testing
```
Solution-A Agent ─┐
                  ├─→ Evaluator Agent
Solution-B Agent ─┘
```

## Tips for Orchestration

1. **Clear handoffs**: Define what each agent produces
2. **Explicit contracts**: Document interfaces early
3. **Regular check-ins**: Don't let agents work too long solo
4. **Handle conflicts**: Plan for integration issues
5. **Track progress**: Maintain status overview

This multi-agent pattern excels for features that naturally decompose into parallel work streams.