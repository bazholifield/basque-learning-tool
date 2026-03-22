import streamlit as st
from backend.reading import reading_gpt

def show():
    st.subheader("📚 Reading Comprehension")

    topic = st.text_input("Enter a topic for the text:", "food")
    length = st.selectbox("Select length:", ["short", "medium", "long"])
    level = st.selectbox("Select difficulty level:", ["beginner", "intermediate", "advanced"])

    if st.button("Generate Text"):
        basque_text, english_text = reading_gpt.generate_basque_text(topic, length, level)
        st.session_state.basque_text = basque_text
        st.session_state.english_text = english_text
        st.session_state.user_summary = ""
        st.session_state.feedback = ""

    if "basque_text" in st.session_state:
        st.markdown(f"**Basque text:**\n\n{st.session_state.basque_text}")

        st.session_state.user_summary = st.text_area("Write your English summary here:")

        if st.button("Check Summary"):
            feedback = reading_gpt.evaluate_summary(
                st.session_state.user_summary,
                st.session_state.english_text
            )
            st.session_state.feedback = feedback

        if st.session_state.feedback:
            st.info(st.session_state.feedback)
