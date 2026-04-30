from fastapi import APIRouter
from backend.declension_loader import load_declensions
from data.declension_reference import basque_declensions

router = APIRouter()
_data = load_declensions()


@router.get("")
def get_declensions():
    return _data


@router.get("/cases")
def get_cases():
    return sorted(_data.keys())


@router.get("/reference")
def get_reference():
    return basque_declensions


@router.get("/{case}")
def get_declensions_by_case(case: str):
    return _data.get(case, [])
