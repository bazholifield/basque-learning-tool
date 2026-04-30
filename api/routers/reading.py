from fastapi import APIRouter
from pydantic import BaseModel
from backend.reading.reading_loader import TOPICS, get_passage, evaluate_summary

router = APIRouter()


class EvaluateRequest(BaseModel):
    user_summary: str
    reference_translation: str


@router.get("/topics")
def get_topics():
    return TOPICS


@router.get("/passage")
def reading_passage(topic: str = "food", level: str = "beginner", length: str = "short"):
    return get_passage(topic, level, length)


@router.post("/evaluate")
def evaluate_reading(req: EvaluateRequest):
    return evaluate_summary(req.user_summary, req.reference_translation)
