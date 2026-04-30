from fastapi import APIRouter
from pydantic import BaseModel
from backend.writing.writing_loader import get_prompt, evaluate

router = APIRouter()


class EvaluateRequest(BaseModel):
    user_text: str
    reference_text: str


@router.get("/prompt")
def writing_prompt():
    return {"prompt": get_prompt()}


@router.post("/evaluate")
def evaluate_writing(req: EvaluateRequest):
    return evaluate(req.user_text, req.reference_text)
