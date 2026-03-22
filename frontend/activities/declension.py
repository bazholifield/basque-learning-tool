import streamlit as st
import random
from backend.declension_loader import load_declensions
from data.declension_reference import basque_declensions
from utils import unwrap

def show():
    st.subheader("Noun Declension Practice")

    # Load data
    if "declensions" not in st.session_state:
        st.session_state.declensions = load_declensions()

    data = st.session_state.declensions
    cases = sorted(data.keys())

    # Select cases
    selected_cases = st.multiselect("Select cases to practice:", cases, default=cases)

    # Filter for singular/plural
    all_numbers = sorted(list({entry["number"] for entries in data.values() for entry in entries}))
    selected_numbers = st.multiselect("Select numbers to practice:", all_numbers, default=all_numbers)
    filtered_data = {c: [e for e in data[c] if e["number"] in selected_numbers] for c in selected_cases}

    # Initialize state
    if (
        "current_decl" not in st.session_state
        or st.session_state.get("last_cases") != selected_cases
        or st.session_state.get("last_numbers") != selected_numbers
    ):
        st.session_state.last_cases = selected_cases
        st.session_state.last_numbers = selected_numbers
        st.session_state.current_decl = random.choice(
            random.choice([filtered_data[c] for c in selected_cases if filtered_data[c]])
        )
        st.session_state.feedback_decl = ""
        st.session_state.correct_decl = 0
        st.session_state.total_decl = 0

    current = st.session_state.current_decl
    noun = unwrap(current["noun"])
    translation = unwrap(current["translation"])
    case = current["case"]
    number = current["number"]

    st.markdown(
        f"**Noun:** {noun} (*{translation}*)  \n"
        f"**Case:** {case}  \n"
        f"**Number:** {number}"
    )

    # Show case explanation + example
    if case in basque_declensions:
        case_info = basque_declensions[case]
        with st.expander("Learn about this case"):
            st.write(f"**Explanation:** {case_info.get('description', 'No description available.')}")
            st.write(f"**Example:** {case_info.get('example', 'No example provided.')}")

    # User input
    user_input = st.text_input("Type the correct declension:")

    if st.button("Check", key="check_decl"):
        st.session_state.total_decl += 1
        if user_input.lower().strip() == current["declension"].lower():
            st.session_state.correct_decl += 1
            st.session_state.feedback_decl = f"Correct! **{noun} ({case}, {number}) → {current['declension']}**"
        else:
            st.session_state.feedback_decl = (
                f"Incorrect. The correct form of **{noun} ({case}, {number})** is **{current['declension']}**."
            )

        # Next random card
        st.session_state.current_decl = random.choice(
            random.choice([filtered_data[c] for c in selected_cases if filtered_data[c]])
        )
        st.rerun()

    # Feedback + stats
    if st.session_state.feedback_decl:
        st.info(st.session_state.feedback_decl)

    st.caption(f"Score: {st.session_state.correct_decl}/{st.session_state.total_decl}")
