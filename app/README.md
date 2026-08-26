# app

Demo app: Python/FastAPI with `/health`, `/metrics` (Prometheus format),
`/items` CRUD (POST/GET), and Swagger docs at `/docs`. Built and
containerized in **Stage 1 (Docker)**.

Every request is instrumented via middleware into two Prometheus metrics
(`http_requests_total`, `http_request_duration_seconds`), scraped later in
Stage 5.

`/items` persists via SQLAlchemy to whatever `DATABASE_URL` points at
(defaults to a local `sqlite:///./local.db` file for dev/tests; Stage 3
points it at Postgres via the Helm values overlay).

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
├── conftest.py       # puts app/ on sys.path, provides a per-test `client` fixture
├── src/
│   ├── __init__.py
│   ├── main.py
│   ├── db.py         # SQLAlchemy engine/session, reads DATABASE_URL
│   ├── models.py      # Item ORM model
│   └── schemas.py     # Pydantic request/response models
└── tests/
    ├── test_main.py
    └── test_items.py
```
