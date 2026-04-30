from fastapi import APIRouter
from backend.conjugation_loader import load_conjugations

router = APIRouter()
_data = load_conjugations()


@router.get("")
def get_conjugations():
    return _data


@router.get("/tenses")
def get_tenses():
    return sorted(_data.keys())


@router.get("/{tense}")
def get_conjugations_by_tense(tense: str):
    return _data.get(tense, [])
