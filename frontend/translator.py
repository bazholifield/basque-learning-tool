# frontend/activities/translator.py
import streamlit as st
from backend.translator_model import translate_text  # your offline model function

def show():
    st.subheader("🌐 Basque ↔ English Translator")

    # Choose direction
    direction = st.radio("Translation direction:", ["Basque → English", "English → Basque"])

    # Input text
    text_input = st.text_area("Enter text to translate:")

    if st.button("Translate"):
        if not text_input.strip():
            st.warning("Please enter some text to translate.")
            return

        # Call your translation function
        try:
            if direction == "Basque → English":
                translation = translate_text(text_input, source="eu", target="en")
            else:
                translation = translate_text(text_input, source="en", target="eu")

            st.success("Translation complete!")
            st.text_area("Translation:", value=translation, height=150)
        except Exception as e:
            st.error(f"Error during translation: {e}")
