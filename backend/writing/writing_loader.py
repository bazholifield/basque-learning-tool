from transformers import MarianMTModel, MarianTokenizer
from sentence_transformers import SentenceTransformer, util
import torch
import random

class BasqueWritingEvaluator:
    def __init__(self):
        # Load translation model
        self.model_name = "Helsinki-NLP/opus-mt-eu-en"
        self.tokenizer = MarianTokenizer.from_pretrained(self.model_name)
        self.model = MarianMTModel.from_pretrained(self.model_name)

        # Load sentence similarity model
        self.sim_model = SentenceTransformer("all-MiniLM-L6-v2")

        # Sample prompts
        self.prompts = [
            "Describe your daily routine.",
            "What did you do last weekend?",
            "Talk about your favorite food.",
            "Describe your family.",
            "What would you like to do in the future?"
        ]

    def get_prompt(self):
        return random.choice(self.prompts)

    def translate_to_english(self, text):
        inputs = self.tokenizer(text, return_tensors="pt", padding=True)
        translated = self.model.generate(**inputs)
        return self.tokenizer.decode(translated[0], skip_special_tokens=True)

    def evaluate(self, user_basque, reference_basque):
        # Translate both to English
        user_en = self.translate_to_english(user_basque)
        ref_en = self.translate_to_english(reference_basque)

        # Compute similarity
        emb1 = self.sim_model.encode(user_en, convert_to_tensor=True)
        emb2 = self.sim_model.encode(ref_en, convert_to_tensor=True)
        score = util.cos_sim(emb1, emb2).item()

        return {
            "user_translation": user_en,
            "reference_translation": ref_en,
            "similarity": score
        }
