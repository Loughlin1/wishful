# Makefile for Wishful Project

.PHONY: backend frontend backend-dev frontend-dev

backend:
	cd backend && source .venv/bin/activate && uvicorn app.main:app --host 0.0.0.0 --port 8000

backend-dev:
	cd backend && source .venv/bin/activate && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

frontend:
	cd frontend && flutter run

frontend-web:
	cd frontend && flutter run -d web-server --web-port=8080
