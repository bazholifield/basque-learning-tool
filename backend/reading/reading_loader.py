from sentence_transformers import SentenceTransformer, util
from backend.translator_model import translate_text

_embedding_model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")

PASSAGES = [
    {
        "id": "1",
        "title": "Reading 1",
        "topic": "food",
        "level": "beginner",
        "basque_text": "Gaur afaltzeko ogia eta gazta jango dut. Esnea ere edango dut. Janaria ona da.",
    },
    {
        "id": "2",
        "title": "Reading 2",
        "topic": "travel",
        "level": "beginner",
        "basque_text": "Udan Donostiara joango naiz oporretan. Hondartzan egongo naiz. Itsasoa ikusiko dut.",
    },
    {
        "id": "3",
        "title": "Reading 3",
        "topic": "weather",
        "level": "beginner",
        "basque_text": "Gaur eguzkia dago eta bero handia egiten du. Parkean joango naiz. Euria ez dago.",
    },
    {
        "id": "4",
        "title": "Reading 4",
        "topic": "school",
        "level": "beginner",
        "basque_text": "Ikastolan euskaraz ikasten dugu. Irakaslea ona da. Lagunekin hitz egiten dut.",
    },
    {
        "id": "5",
        "title": "Reading 5",
        "topic": "sports",
        "level": "beginner",
        "basque_text": "Futbola nire kirol gogokoena da. Goizean korrika egiten dut parkean. Kirola ona da osasunerako.",
    },
    {
        "id": "6",
        "title": "Reading 6",
        "topic": "food",
        "level": "intermediate",
        "basque_text": "Fruta freskoa gustatzen zait, batez ere sagarrak eta laranjak. Barazkiak ere jaten ditut egunero. Osasuntsu jatea garrantzitsua da.",
    },
    {
        "id": "7",
        "title": "Reading 7",
        "topic": "travel",
        "level": "intermediate",
        "basque_text": "Hiri berriak bisitatzea atsegina da. Museoak eta parkeak ikusten ditut bidaiatzen dudanean. Kultura ezberdinak ezagutzea gustatzen zait.",
    },
    {
        "id": "8",
        "title": "Reading 8",
        "topic": "weather",
        "level": "intermediate",
        "basque_text": "Euria ari du goizean eta hotza dago. Aterki bat eraman behar dut. Arratsaldean eguzkia aterako dela uste dut.",
    },
    {
        "id": "9",
        "title": "Reading 9",
        "topic": "school",
        "level": "intermediate",
        "basque_text": "Gaur matematikako ariketa zaila egin dugu klasean. Irakasleari galderak egin dizkiot ez nuelako ulertzen. Etxean gehiago ikasiko dut.",
    },
    {
        "id": "10",
        "title": "Reading 10",
        "topic": "sports",
        "level": "intermediate",
        "basque_text": "Astero bi aldiz futbola jokatzen dut lagunekin. Taldea ona da eta irabazten saiatzen gara. Kirola egitea oso gustuko dut.",
    },
]

_passage_map = {p["id"]: p for p in PASSAGES}


def get_all_passages() -> list:
    return [
        {"id": p["id"], "title": p["title"], "topic": p["topic"], "level": p["level"]}
        for p in PASSAGES
    ]


def get_passage_by_id(passage_id: str) -> dict | None:
    passage = _passage_map.get(passage_id)
    if not passage:
        return None
    english_translation = translate_text(passage["basque_text"], "eu", "en")
    return {**passage, "english_translation": english_translation}


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
