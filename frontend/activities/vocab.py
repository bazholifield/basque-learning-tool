import streamlit as st
from backend.flashcards import Flashcard, Deck, ReviewSession
from backend.vocab_loader import load_vocab

def show():
    vocab = load_vocab()

    category = st.selectbox("Choose a category:", sorted(vocab.keys()))

    if "session" not in st.session_state or st.session_state.get("category") != category:
        pairs = vocab[category]
        deck = Deck(category, [Flashcard(en, eu) for en, eu in pairs])
        st.session_state.session = ReviewSession(deck)
        st.session_state.category = category
        st.session_state.show_back = False

    session = st.session_state.session
    card = session.next_card()

    if card:
        st.header(f"{category.capitalize()} • Card {session.index + 1}/{len(session.cards)}")

        if not st.session_state.show_back:
            st.subheader(card.en)
            st.button("Reveal", on_click=lambda: st.session_state.update({"show_back": True}))
        else:
            st.subheader(card.eu)
            cols = st.columns(3)
            if cols[0].button("Easy"):
                session.review_card(card, "easy")
                st.session_state.show_back = False
            elif cols[1].button("Medium"):
                session.review_card(card, "medium")
                st.session_state.show_back = False
            elif cols[2].button("Hard"):
                session.review_card(card, "hard")
                st.session_state.show_back = False

            st.caption(f"Next review: {card.next_review.strftime('%Y-%m-%d')}")
    else:
        st.success("🎉 Session complete!")
        st.write(f"You’ve finished all the {category} flashcards!")
        for c in session.reviewed:
            st.markdown(f"- **{c.en}** → *{c.eu}* (Next review in {c.interval:.2f} days)")

        if st.button("Restart Category"):
            st.session_state.clear()
            st.rerun()
