# app

Demo app: Python/FastAPI with `/health`, `/metrics` (Prometheus format), and
Swagger docs at `/docs`. Built and containerized in **Stage 1 (Docker)**.

Every request is instrumented via middleware into two Prometheus metrics
(`http_requests_total`, `http_request_duration_seconds`), scraped later in
Stage 5.

## Run locally

```
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn src.main:app --reload
```

## Run in Docker

```
docker build -t demo-app .
docker run -p 8000:8000 demo-app
```

## Test

```
pytest app
```

## Layout

```
app/
├── Dockerfile
├── .dockerignore
├── requirements.txt
├── conftest.py       # puts app/ on sys.path so tests can `import src`
├── src/
│   ├── __init__.py
│   └── main.py
└── tests/
    └── test_main.py
```
