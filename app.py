# app.py
import streamlit as st
from frontend.tabs import show_practice_tab, show_learn_tab, show_translator_tab

st.set_page_config(page_title="Basque Trainer", page_icon="🇪🇺", layout="centered")
st.title("Learning Basque")

tab1, tab2, tab3= st.tabs(["📖 Practice", "Translate", "📊 Learn"])

with tab1:
    show_practice_tab()

with tab2:
    show_translator_tab()

with tab3:
    show_learn_tab()


