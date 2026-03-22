import streamlit as st
from backend.writing.writing_loader import BasqueWritingEvaluator

def show():
    st.subheader("✍️ Writing Practice")

    if "writing_eval" not in st.session_state:
        st.session_state.writing_eval = BasqueWritingEvaluator()

    evaluator = st.session_state.writing_eval

    prompt = st.session_state.get("prompt", evaluator.get_prompt())
    st.markdown(f"**Prompt:** {prompt}")

    user_input = st.text_area("Write your answer in Basque:")
    reference_answer = st.text_area("Reference answer (for testing):")

    if st.button("Evaluate"):
        if user_input and reference_answer:
            result = evaluator.evaluate(user_input, reference_answer)
            st.write(f"**Your English translation:** {result['user_translation']}")
            st.write(f"**Reference translation:** {result['reference_translation']}")
            st.write(f"**Similarity score:** {result['similarity']:.2f}")
        else:
            st.warning("Please fill both fields before evaluating.")
