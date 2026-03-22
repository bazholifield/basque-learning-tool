import streamlit as st

def show():
    st.subheader("Listening Practice")

    st.write("""
    Listen to short audio clips in Basque and type what you hear.
    Eventually, this section could include:
    - Audio recordings (dialogues, stories)
    - Dictation exercises
    - Comprehension questions
    """)

    st.audio("https://upload.wikimedia.org/wikipedia/commons/c/c8/Example.ogg")
    st.text_input("What did you hear?")
    st.button("Check")

    st.info("Add this later")
