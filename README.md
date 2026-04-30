# Basque Learning App

This is a small project I started as a way to help myself learn Basque. I wanted something more interactive and customizable than traditional resources, so I built a simple app with different tools to practice vocabulary and grammar.

Right now, the app includes things like:

* Practice activities for vocabulary, noun declensions, and verb conjugations
* Flashcards with spaced repetition (SM-2 algorithm) for long-term retention
* A "learn" section with explanations and examples for each grammatical case
* Reading and writing activities with automated evaluation
* An offline translator I've been experimenting with

It's still a work in progress, but I've been gradually expanding it as I learn more Basque and as I think of new features that would actually be useful for studying.

---

## Features

* **Practice**

  * Exercises for noun declensions and verb conjugations
  * Flashcards for vocabulary with spaced repetition
  * Reading comprehension with similarity-based summary evaluation
  * Writing practice with automated translation and scoring

* **Learning**

  * Plain-English explanations of grammatical concepts
  * Examples for each case and structure

* **Translator**

  * Bidirectional Basque ↔ English translation
  * Runs on a locally downloaded model (no API required)
  * Still experimental but useful for quick checks

---

## Structure

* The app now has two frontends: a **Flutter app** (in `lib/`) for desktop and eventually mobile, and the original **Streamlit interface** (in `frontend/`) still around for quick testing.
* The **backend** (in `backend/`) handles data loading and model logic.
* A **FastAPI server** (in `api/`) sits between the Flutter app and the Python backend, exposing everything over a local REST API.
* Data (like declensions, conjugations, vocabulary, and explanations) lives in `data/` and is loaded dynamically.

The goal was to keep things modular so I can easily:

* Add new activities
* Swap in better datasets
* Improve individual components without breaking everything

---

## Running It

You need two terminals:

```bash
# Terminal 1 — start the API server
source venv/bin/activate && uvicorn api.main:app --host 0.0.0.0 --port 8000

# Terminal 2 — run the Flutter app
flutter run -d linux
```

The API docs are available at `http://localhost:8000/docs` when the server is running.

---

## Future Plans

* Improve the interface and add more practice modes (sentence building, lessons, speaking and listening practice, etc.)
* Get the app running on Android
* Expand the translation system and reading/writing tools
* Support additional languages beyond Basque
* Clean up and standardize the linguistic data

---

## Why I Built This

This project is mainly for personal use so I could figure out how I learn best. At the same time, it's been a great way to practice building tools, working with language data, and applying NLP concepts in a practical setting. Long term, the goal is to turn this into a genuinely useful language learning app for English speakers — Basque is just where the framework is being developed.
