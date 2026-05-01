from backend.translator_model import translate_text


def translate_to_english(text: str) -> str:
    return translate_text(text, "eu", "en")


CONVERSATIONS = [
    {
        "id": "1",
        "title": "At the Restaurant",
        "situation": "Jatetxean",
        "questions": [
            {"basque": "Egun on! Zer nahi duzu jateko?", "english": "Good morning! What would you like to eat?"},
            {"basque": "Eta edateko, zer hartuko duzu?", "english": "And to drink, what will you have?"},
            {"basque": "Gustatu zaizu janaria?", "english": "Did you like the food?"},
            {"basque": "Postre bat nahi duzu?", "english": "Would you like a dessert?"},
            {"basque": "Zenbat da guztira, mesedez?", "english": "How much is it in total, please?"},
        ],
    },
    {
        "id": "2",
        "title": "At the Train Station",
        "situation": "Tren geltokian",
        "questions": [
            {"basque": "Barkatu, non dago tren geltokia?", "english": "Excuse me, where is the train station?"},
            {"basque": "Bilborako txartel bat nahi dut. Zenbat kostatzen da?", "english": "I'd like a ticket to Bilbao. How much does it cost?"},
            {"basque": "Zein ordutan irteten da hurrengo trena?", "english": "What time does the next train leave?"},
            {"basque": "Non dago nire trenbidea?", "english": "Where is my platform?"},
            {"basque": "Trena berandu dator?", "english": "Is the train late?"},
            {"basque": "Eskerrik asko! Agur!", "english": "Thank you! Goodbye!"},
        ],
    },
    {
        "id": "3",
        "title": "Introducing Yourself",
        "situation": "Norberaren aurkezpena",
        "questions": [
            {"basque": "Kaixo! Nola duzu izena?", "english": "Hi! What is your name?"},
            {"basque": "Nongoa zara?", "english": "Where are you from?"},
            {"basque": "Zenbat urte dituzu?", "english": "How old are you?"},
            {"basque": "Zer egiten duzu lanerako?", "english": "What do you do for work?"},
            {"basque": "Zergatik ikasten duzu euskara?", "english": "Why are you learning Basque?"},
            {"basque": "Gustatu zaizu Euskal Herria?", "english": "Do you like the Basque Country?"},
        ],
    },
    {
        "id": "4",
        "title": "Shopping",
        "situation": "Dendetan",
        "questions": [
            {"basque": "Kaixo! Nola lagun diezazuket?", "english": "Hi! How can I help you?"},
            {"basque": "Zenbat kostatzen da hau?", "english": "How much does this cost?"},
            {"basque": "Tamaina txikiagoa daukazu?", "english": "Do you have a smaller size?"},
            {"basque": "Beste kolore batean dago?", "english": "Does it come in another color?"},
            {"basque": "Txartelarekin ordain dezaket?", "english": "Can I pay by card?"},
            {"basque": "Poltsa bat nahi duzu?", "english": "Would you like a bag?"},
        ],
    },
    {
        "id": "5",
        "title": "Making Plans with a Friend",
        "situation": "Lagunarekin planak egiten",
        "questions": [
            {"basque": "Aizu! Zer egin nahi duzu gaur arratsaldean?", "english": "Hey! What do you want to do this afternoon?"},
            {"basque": "Non bildu nahi duzu?", "english": "Where do you want to meet?"},
            {"basque": "Zenbat ordutan etorriko zara?", "english": "What time will you come?"},
            {"basque": "Nor ekarriko duzu zurekin?", "english": "Who will you bring with you?"},
            {"basque": "Ados! Gero arte. Zer erantzungo zenuke?", "english": "Great! See you later. What would you reply?"},
        ],
    },
]

_conversation_map = {c["id"]: c for c in CONVERSATIONS}


def get_all_conversations() -> list:
    return [
        {"id": c["id"], "title": c["title"], "situation": c["situation"],
         "question_count": len(c["questions"])}
        for c in CONVERSATIONS
    ]


def get_conversation_by_id(conversation_id: str) -> dict | None:
    return _conversation_map.get(conversation_id)
