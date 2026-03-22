import streamlit as st
from backend.reading.reading_loader import (
    generate_basque_text,
    translate_to_english,
    evaluate_summary,
)

def show():
    st.subheader("Reading Practice")

    # Selection menu
    topic = st.selectbox("Choose a topic:", ["food", "travel", "weather", "school", "sports"])
    level = st.selectbox("Choose your level:", ["beginner", "intermediate", "advanced"])
    length = st.selectbox("Text length:", ["short", "medium", "long"])

    # Generate a text
    if st.button("Generate New Text"):
        basque_text = generate_basque_text(topic, length, level)
        english_ref = translate_to_english(basque_text)

        st.session_state.basque_text = basque_text
        st.session_state.english_ref = english_ref
        st.session_state.feedback = None

    # Show text
    if "basque_text" in st.session_state:
        st.markdown("### Basque Text")
        st.write(st.session_state.basque_text)

        st.markdown("---")
        st.markdown("### Your Task")
        st.write("Summarize the text in **English** in one or two sentences.")
        user_summary = st.text_area("Your summary:")

        if st.button("Check Summary"):
            if user_summary.strip():
                ref = st.session_state.english_ref
                score = evaluate_summary(user_summary, ref)

                # Feedback interpretation
                if score > 0.85:
                    feedback = "Excellent! Your summary captures almost everything accurately."
                elif score > 0.65:
                    feedback = "Good! You understood the main ideas, but a few details are missing."
                else:
                    feedback = "Needs improvement. Try rereading the text and identifying key details."

                st.session_state.feedback = feedback
                st.session_state.score = score

        if st.session_state.get("feedback"):
            st.markdown("---")
            st.markdown("### Feedback")
            st.write(st.session_state.feedback)
            st.caption(f"Similarity Score: {st.session_state.score:.2f}")

            with st.expander("Show Reference Translation"):
                st.write(st.session_state.english_ref)

