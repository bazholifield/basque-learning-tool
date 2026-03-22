import streamlit as st
import random
from backend.conjugation_loader import load_conjugations
from utils import unwrap

def show():
    st.subheader("Verb Conjugation Practice")

    # Load data
    if "conjugations" not in st.session_state:
        st.session_state.conjugations = load_conjugations()

    data = st.session_state.conjugations
    tenses = sorted(data.keys())

    # Select tenses
    selected_tenses = st.multiselect("Select tenses to practice:", tenses, default=tenses)

    # Initialize state
    if "current" not in st.session_state or st.session_state.get("last_tenses") != selected_tenses:
        st.session_state.last_tenses = selected_tenses
        st.session_state.current = random.choice(
            random.choice([data[t] for t in selected_tenses])
        )
        st.session_state.feedback = ""
        st.session_state.correct_count = 0
        st.session_state.total = 0

    current = st.session_state.current

    # Display prompt
    verb = unwrap(current['verb'])
    translation = unwrap(current['translation'])
    person = current['person']
    tense = current['tense']

    st.markdown(
        f"**Verb:** {verb} (*{translation}*)  \n"
        f"**Person:** {person}  \n"
        f"**Tense:** {tense}"
    )


    # User input
    user_input = st.text_input("Type the correct conjugation:")

    if st.button("Check"):
        st.session_state.total += 1
        if user_input.lower().strip() == current["conjugation"].lower():
            st.session_state.correct_count += 1
            st.session_state.feedback = f"Correct! **{verb} ({person}) → {current['conjugation']}**"
        else:
            st.session_state.feedback = (
                f"Incorrect. The correct form of **{verb} ({person})** is **{current['conjugation']}**."
            )

        # Next random card
        st.session_state.current = random.choice(
            random.choice([data[t] for t in selected_tenses])
        )

        st.rerun()

    # Feedback + stats
    if st.session_state.feedback:
        st.info(st.session_state.feedback)

    st.caption(f"Score: {st.session_state.correct_count}/{st.session_state.total}")
