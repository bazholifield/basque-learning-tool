from sentence_transformers import SentenceTransformer, util
from backend.translator_model import translate_text
import random

_sim_model = SentenceTransformer("all-MiniLM-L6-v2")

PROMPTS = [
    "Describe your daily routine.",
    "What did you do last weekend?",
    "Talk about your favorite food.",
    "Describe your family.",
    "What would you like to do in the future?",
]


def get_prompt() -> str:
    return random.choice(PROMPTS)


def evaluate(user_basque: str, reference_basque: str) -> dict:
    user_en = translate_text(user_basque, "eu", "en")
    ref_en = translate_text(reference_basque, "eu", "en")
    emb1 = _sim_model.encode(user_en, convert_to_tensor=True)
    emb2 = _sim_model.encode(ref_en, convert_to_tensor=True)
    score = util.cos_sim(emb1, emb2).item()
    return {"user_translation": user_en, "reference_translation": ref_en, "similarity": score}
