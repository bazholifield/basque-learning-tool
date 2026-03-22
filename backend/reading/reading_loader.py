import random
from transformers import MarianMTModel, MarianTokenizer
from sentence_transformers import SentenceTransformer, util

# Load translation model
translation_model_name = "Helsinki-NLP/opus-mt-eu-en"
translation_tokenizer = MarianTokenizer.from_pretrained(translation_model_name)
translation_model = MarianMTModel.from_pretrained(translation_model_name)

# Sentence transformer for eval
embedding_model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")

TOPICS = ["food", "travel", "weather", "school", "sports"]

def generate_basque_text(topic: str, length: str, level: str) -> str:
    """
    Returns a short Basque text for a given topic.
    """
    samples = {
        "food": [
            "Gaur afaltzeko ogia eta gazta jango dut.",
            "Fruta freskoa gustatzen zait, batez ere sagarrak."
        ],
        "travel": [
            "Udan Donostiara joango naiz oporretan.",
            "Hiri berriak bisitatzea atsegina da."
        ],
        "weather": [
            "Gaur eguzkia dago eta bero handia egiten du.",
            "Euria ari du goizean."
        ],
        "school": [
            "Ikastolan euskaraz ikasten dugu.",
            "Gaur matematikako ariketa zaila egin dugu."
        ],
        "sports": [
            "Futbola nire kirol gogokoena da.",
            "Goizean korrika egiten dut parkean."
        ]
    }
    return random.choice(samples.get(topic, ["Testu laburra hemen."]))

def translate_to_english(basque_text: str) -> str:
    """Translates Basque text to English."""
    tokens = translation_tokenizer(basque_text, return_tensors="pt", padding=True)
    translated = translation_model.generate(**tokens)
    return translation_tokenizer.decode(translated[0], skip_special_tokens=True)

def evaluate_summary(user_summary: str, reference: str) -> float:
    """
    Returns similarity score between summary and reference text.
    """
    user_emb = embedding_model.encode(user_summary, convert_to_tensor=True)
    ref_emb = embedding_model.encode(reference, convert_to_tensor=True)
    score = util.cos_sim(user_emb, ref_emb).item()
    return score
