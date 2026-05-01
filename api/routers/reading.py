from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from backend.reading.reading_loader import get_all_passages, get_passage_by_id, evaluate_summary

router = APIRouter()


class EvaluateRequest(BaseModel):
    user_summary: str
    reference_translation: str


@router.get("/passages")
def list_passages():
    return get_all_passages()


@router.get("/passage/{passage_id}")
def get_passage(passage_id: str):
    passage = get_passage_by_id(passage_id)
    if not passage:
        raise HTTPException(status_code=404, detail=f"Passage '{passage_id}' not found")
    return passage


@router.post("/evaluate")
def evaluate_reading(req: EvaluateRequest):
    return evaluate_summary(req.user_summary, req.reference_translation)
