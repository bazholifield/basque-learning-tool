from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from backend.writing.writing_loader import get_all_conversations, get_conversation_by_id, translate_to_english

router = APIRouter()


class TranslateRequest(BaseModel):
    text: str


@router.post("/translate")
def translate(req: TranslateRequest):
    return {"translation": translate_to_english(req.text)}


@router.get("/conversations")
def list_conversations():
    return get_all_conversations()


@router.get("/conversation/{conversation_id}")
def get_conversation(conversation_id: str):
    conv = get_conversation_by_id(conversation_id)
    if not conv:
        raise HTTPException(status_code=404, detail=f"Conversation '{conversation_id}' not found")
    return conv
