from transformers import MarianMTModel, MarianTokenizer

src_tgt_map = {
    "eu-en": "Helsinki-NLP/opus-mt-eu-en",
    "en-eu": "Helsinki-NLP/opus-mt-en-eu"
}

models = {}
tokenizers = {}

for k, model_name in src_tgt_map.items():
    tokenizers[k] = MarianTokenizer.from_pretrained(model_name)
    models[k] = MarianMTModel.from_pretrained(model_name)

def translate_text(text, source="eu", target="en"):
    key = f"{source}-{target}"
    tokenizer = tokenizers[key]
    model = models[key]

    batch = tokenizer([text], return_tensors="pt", padding=True)
    translated = model.generate(**batch)
    return tokenizer.decode(translated[0], skip_special_tokens=True)
