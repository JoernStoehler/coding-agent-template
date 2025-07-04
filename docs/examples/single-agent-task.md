# Example: Single Agent Task

This example shows how to use one agent to add a feature to a Python project.

## Scenario

Add user authentication to a Flask web application.

## Step 1: Prepare Main Repository

```bash
# Inside container
cd /workspaces/main

# Create basic Flask app
cat > app.py << 'EOF'
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({"message": "Welcome!"})

@app.route('/users')
def users():
    # TODO: Add authentication
    return jsonify({"users": ["alice", "bob"]})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Commit initial code
git add app.py
git commit -m "feat: initial Flask app"
```

## Step 2: Create CLAUDE.md

```bash
cat > CLAUDE.md << 'EOF'
# Flask App - AI Agent Context

## Project Overview
Simple Flask API that needs authentication added.

## Tech Stack
- Python 3.11
- Flask 2.0+
- JWT for authentication

## Project Structure
- `app.py` - Main application
- `requirements.txt` - Dependencies
- `tests/` - Test files

## Conventions
- Use Flask-JWT-Extended for JWT
- All endpoints except /login require authentication
- Return JSON responses
- Write tests for new endpoints

## Running the App
```bash
pip install -r requirements.txt
python app.py
```

## Testing
```bash
pytest tests/
```
EOF

git add CLAUDE.md
git commit -m "docs: add agent context"
```

## Step 3: Create Agent

```bash
cd /workspaces
./scripts/setup-agent.sh add-auth "Add JWT authentication to protect /users endpoint"
```

## Step 4: Customize Agent Prompt

```bash
cd /workspaces/add-auth

# Enhance the prompt
cat >> prompt.md << 'EOF'

## Specific Requirements

1. Install Flask-JWT-Extended
2. Add /login endpoint that returns JWT token
3. Protect /users endpoint with JWT
4. Add tests for authentication
5. Update requirements.txt

## Success Example

```bash
# Login
curl -X POST http://localhost:5000/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "secret"}'
# Returns: {"access_token": "eyJ0..."}

# Access protected endpoint
curl http://localhost:5000/users \
  -H "Authorization: Bearer eyJ0..."
# Returns: {"users": ["alice", "bob"]}

# Without token
curl http://localhost:5000/users
# Returns: {"msg": "Missing Authorization Header"}
```
EOF
```

## Step 5: Start Agent

```bash
# In new terminal
cd /workspaces/add-auth
source .env
claude --dangerously-skip-permissions "@prompt.md"
```

## Step 6: Monitor Progress

The agent will typically:

1. Read existing code
2. Install dependencies
3. Implement authentication
4. Write tests
5. Test the implementation
6. Commit changes

Watch for:
```bash
# Check commits
git log --oneline

# Watch for mail
ls -lt /workspaces/.mail/*.json | head -5

# Test the app
python app.py &
curl http://localhost:5000/
```

## Expected Outcome

Agent creates files like:

**requirements.txt**:
```
Flask==2.3.0
Flask-JWT-Extended==4.5.0
pytest==7.4.0
```

**Updated app.py**:
```python
from flask import Flask, jsonify, request
from flask_jwt_extended import JWTManager, create_access_token, jwt_required

app = Flask(__name__)
app.config['JWT_SECRET_KEY'] = 'your-secret-key'  # Change in production!
jwt = JWTManager(app)

@app.route('/')
def home():
    return jsonify({"message": "Welcome!"})

@app.route('/login', methods=['POST'])
def login():
    username = request.json.get('username')
    password = request.json.get('password')
    
    # Simple auth check (use proper validation in production)
    if username == 'admin' and password == 'secret':
        access_token = create_access_token(identity=username)
        return jsonify(access_token=access_token)
    
    return jsonify({"msg": "Bad credentials"}), 401

@app.route('/users')
@jwt_required()
def users():
    return jsonify({"users": ["alice", "bob"]})
```

**tests/test_auth.py**:
```python
import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home_accessible(client):
    rv = client.get('/')
    assert rv.status_code == 200

def test_users_requires_auth(client):
    rv = client.get('/users')
    assert rv.status_code == 401

def test_login_success(client):
    rv = client.post('/login', json={
        'username': 'admin',
        'password': 'secret'
    })
    assert rv.status_code == 200
    assert 'access_token' in rv.json
```

## Step 7: Review and Merge

```bash
cd /workspaces/main

# Review changes
git diff main...add-auth

# If good, merge
git merge add-auth

# Clean up
git worktree remove ../add-auth
```

## Common Variations

### Different Task Types

**Bug Fix**:
```bash
./scripts/setup-agent.sh fix-500-error "Fix 500 error when user not found"
```

**Refactoring**:
```bash
./scripts/setup-agent.sh refactor-db "Extract database queries to repository pattern"
```

**Documentation**:
```bash
./scripts/setup-agent.sh docs-api "Generate OpenAPI documentation"
```

### Tips for Success

1. **Clear requirements**: Be specific in prompt.md
2. **Provide examples**: Show desired input/output
3. **Include context**: Reference existing patterns
4. **Set boundaries**: What NOT to change
5. **Define "done"**: Clear success criteria

## Debugging

If agent struggles:
- Check if requirements are clear
- Provide more examples
- Simplify the task
- Check for missing context in CLAUDE.md

This single-agent pattern works well for focused tasks that one developer would typically handle.