from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from backend.translator_model import translate_text

router = APIRouter()


class TranslateRequest(BaseModel):
    text: str
    source: str = "eu"
    target: str = "en"


@router.post("")
def translate(req: TranslateRequest):
    key = f"{req.source}-{req.target}"
    if key not in ("eu-en", "en-eu"):
        raise HTTPException(status_code=400, detail=f"Unsupported language pair: {key}")
    return {"translation": translate_text(req.text, req.source, req.target)}
