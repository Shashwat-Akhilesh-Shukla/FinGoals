from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from contextlib import asynccontextmanager
import os

from database import engine, Base, SessionLocal, SEED_CATEGORIES
from models import Category
from routers import transactions, analytics, goals
from routers import export as export_mod


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        if db.query(Category).count() == 0:
            for name, bucket, tx_type in SEED_CATEGORIES:
                cat = Category(
                    name=name, bucket=bucket,
                    transaction_type=tx_type, is_custom=False
                )
                db.add(cat)
            db.commit()
    finally:
        db.close()
    yield


app = FastAPI(title="FinGoals API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(transactions.router, prefix="/api")
app.include_router(analytics.router, prefix="/api")
app.include_router(goals.router, prefix="/api")
app.include_router(export_mod.router, prefix="/api")

# Serve built React frontend in production
FRONTEND_DIST = os.path.join(os.path.dirname(__file__), "..", "frontend", "dist")
if os.path.exists(FRONTEND_DIST):
    app.mount(
        "/assets",
        StaticFiles(directory=os.path.join(FRONTEND_DIST, "assets")),
        name="assets",
    )

    @app.get("/{full_path:path}")
    async def serve_spa(full_path: str):
        return FileResponse(os.path.join(FRONTEND_DIST, "index.html"))


@app.get("/api/health")
async def health():
    return {"status": "ok", "version": "1.0.0"}
