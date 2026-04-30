import random
from sentence_transformers import SentenceTransformer, util
from backend.translator_model import translate_text

_embedding_model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")

TOPICS = ["food", "travel", "weather", "school", "sports"]

_SAMPLES = {
    "food": [
        "Gaur afaltzeko ogia eta gazta jango dut.",
        "Fruta freskoa gustatzen zait, batez ere sagarrak.",
    ],
    "travel": [
        "Udan Donostiara joango naiz oporretan.",
        "Hiri berriak bisitatzea atsegina da.",
    ],
    "weather": [
        "Gaur eguzkia dago eta bero handia egiten du.",
        "Euria ari du goizean.",
    ],
    "school": [
        "Ikastolan euskaraz ikasten dugu.",
        "Gaur matematikako ariketa zaila egin dugu.",
    ],
    "sports": [
        "Futbola nire kirol gogokoena da.",
        "Goizean korrika egiten dut parkean.",
    ],
}


def get_passage(topic: str, level: str = "beginner", length: str = "short") -> dict:
    basque_text = random.choice(_SAMPLES.get(topic, ["Testu laburra hemen."]))
    english_translation = translate_text(basque_text, "eu", "en")
    return {"basque_text": basque_text, "english_translation": english_translation}


def evaluate_summary(user_summary: str, reference_translation: str) -> dict:
    user_emb = _embedding_model.encode(user_summary, convert_to_tensor=True)
    ref_emb = _embedding_model.encode(reference_translation, convert_to_tensor=True)
    score = util.cos_sim(user_emb, ref_emb).item()
    if score > 0.85:
        label = "excellent"
    elif score > 0.65:
        label = "good"
    else:
        label = "needs work"
    return {"score": score, "label": label}
