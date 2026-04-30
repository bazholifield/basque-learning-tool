from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.routers import vocab, conjugation, declension, translator, writing, reading


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Models load at import time inside each router module.
    # This lifespan exists as an extension point for future async init.
    yield


app = FastAPI(title="Basque Trainer API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(vocab.router, prefix="/vocab", tags=["vocab"])
app.include_router(conjugation.router, prefix="/conjugations", tags=["conjugations"])
app.include_router(declension.router, prefix="/declensions", tags=["declensions"])
app.include_router(translator.router, prefix="/translate", tags=["translator"])
app.include_router(writing.router, prefix="/writing", tags=["writing"])
app.include_router(reading.router, prefix="/reading", tags=["reading"])


@app.get("/health")
def health():
    return {"status": "ok"}
