from fastapi import APIRouter
from backend.vocab_loader import load_vocab

router = APIRouter()
_data = load_vocab()


@router.get("")
def get_vocab():
    return _data


@router.get("/categories")
def get_categories():
    return list(_data.keys())


@router.get("/{category}")
def get_vocab_by_category(category: str):
    return _data.get(category, [])
