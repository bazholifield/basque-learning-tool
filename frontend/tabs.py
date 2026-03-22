# frontend/tabs.py
import streamlit as st
from frontend.activities import reading, vocab, conjugation, declension, writing, speaking, listening
from frontend import translator

def show_practice_tab():
    st.header("Practice")

    activity = st.radio(
        "Choose an activity:",
        ["Vocab", "Conjugation", "Declension", "Writing", "Reading", "Speaking", "Listening"],
        horizontal=True,
    )

    if activity == "Vocab":
        vocab.show()
    elif activity == "Conjugation":
        conjugation.show()
    elif activity == "Declension":
        declension.show()
    elif activity == "Writing":
        writing.show()
    elif activity == "Reading":
        reading.show()
    elif activity == "Speaking":
        speaking.show()
    elif activity == "Listening":
        listening.show()

def show_translator_tab():
    st.header("Translate")
    translator.show()

def show_learn_tab():
    st.header("Lessons")
    st.write("📖 Lesson content will go here later.")
