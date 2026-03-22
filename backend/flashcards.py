from datetime import datetime, timedelta
import random


class Flashcard:
    def __init__(self, en, eu, example_en=None, example_eu=None):
        self.en = en
        self.eu = eu
        self.example_en = example_en
        self.example_eu = example_eu
        self.interval = 1
        self.ease_factor = 2.5
        self.repetitions = 0
        self.last_reviewed = None
        self.next_review = datetime.now()

    def review(self, difficulty: str):
        self.repetitions += 1

        if difficulty == "easy":
            self.ease_factor += 0.1
            self.interval *= self.ease_factor
        elif difficulty == "medium":
            self.interval *= 1.0
        else:  # hard
            self.ease_factor = max(1.3, self.ease_factor - 0.2)
            self.interval = 1

        self.last_reviewed = datetime.now()
        self.next_review = self.last_reviewed + timedelta(days=self.interval)


class Deck:
    def __init__(self, name, flashcards):
        self.name = name
        self.flashcards = flashcards


class ReviewSession:
    def __init__(self, deck):
        self.deck = deck
        self.cards = random.sample(deck.flashcards, len(deck.flashcards))
        self.index = 0
        self.reviewed = []

    def has_next(self):
        return self.index < len(self.cards)

    def next_card(self):
        if self.has_next():
            return self.cards[self.index]
        return None

    def review_card(self, card, difficulty):
        card.review(difficulty)
        self.reviewed.append(card)
        self.index += 1
