# Basque Learning Tool

A full-stack language learning app for Basque, built during a year living in the Basque Country. The app combines spaced repetition, NLP-based writing evaluation, and an offline neural translator into a modular platform designed to be extended to other languages.

> **Stack:** Flutter (desktop) · FastAPI · Python · Streamlit · HuggingFace Transformers

---

## Architecture

```
Flutter Desktop App (lib/)
        │
        ▼
FastAPI Server (api/)          ← REST API, auto-docs at /docs
        │
        ▼
Python Backend (backend/)      ← data loading, model logic, SM-2 algorithm
        │
        ├── data/              ← declensions, conjugations, vocabulary, grammar explanations
        └── Helsinki-NLP/opus-mt-eu-en  ← offline Basque - English translation
```

The Flutter app is the primary interface for desktop use. The original Streamlit interface (`frontend/`) is still available for quick testing and development. Everything the frontend needs is exposed through the FastAPI layer, which keeps the backend fully decoupled and individually replaceable.

---

## Features

### Practice
- Exercises for Basque noun declensions across all grammatical cases
- Verb conjugation drills
- Vocabulary flashcards with spaced repetition (SM-2 algorithm) for long-term retention
- Reading comprehension with similarity-based summary evaluation
- Writing practice with automated translation and scoring

### Learn
- Plain-English explanations of Basque grammatical concepts
- Examples for each case and structure
- Designed for English speakers with no prior Basque exposure

### Translator
- Bidirectional Basque - English translation
- Runs on Helsinki-NLP/opus-mt-eu-en downloaded locally, so no internet or API key required at runtime
- Integrated into writing practice for automated answer evaluation

---

## Running It

**Requirements:** Flutter SDK, Python 3.10+, and a virtual environment with the dependencies installed.

```bash
pip install -r requirements.txt
```

Start both processes in separate terminals:

```bash
# Terminal 1 — API server
source venv/bin/activate
uvicorn api.main:app --host 0.0.0.0 --port 8000

# Terminal 2 — Flutter app
flutter run -d linux
```

API docs are available at `http://localhost:8000/docs` once the server is running.

To use the Streamlit interface instead:

```bash
streamlit run frontend/app.py
```

---

## Project Status

This is an active personal project. Currently working on:

- Android support via Flutter's mobile build
- Expanded sentence-building and listening practice modes
- Improved translation pipeline and writing evaluation
- Standardized linguistic data format to support additional languages

The long-term goal is a framework flexible enough to support other low-resource or morphologically complex languages beyond Basque.

---

## Why Basque

Basque (*Euskara*) is a language isolate — unrelated to any other known language — with a highly agglutinative morphology and a complex case system that makes it genuinely difficult for English speakers. Existing learning resources are sparse compared to major European languages, and none of them were interactive or customizable in the way I wanted.

Building this was partly about learning Basque and partly about working through the practical problems of building NLP tooling for a low-resource language: limited training data, limited pre-trained model availability, and morphological complexity that breaks assumptions baked into tools designed for Indo-European languages. Those are exactly the kinds of problems I want to keep working on.
