import csv
from collections import defaultdict

def load_vocab(filename="data/vocab.csv"):
    """Load vocab CSV and group by category."""
    vocab_by_category = defaultdict(list)

    with open("data/vocab.csv", newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for row in reader:
            category = row["category"].strip()
            en = row["english"].strip()
            eu = row["basque"].strip()
            vocab_by_category[category].append((en, eu))

    return vocab_by_category

vocab = load_vocab()
