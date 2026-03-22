import streamlit as st

def show():
    st.subheader("Speaking Practice")

    st.write("""
    Practice pronunciation and speaking in Basque.
    Eventually, this will support:
    - Speech-to-text pronunciation checks
    - Conversation simulations
    - AI-based feedback
    """)

    st.button("🎤 Start Recording")
    st.info("Add this later")
