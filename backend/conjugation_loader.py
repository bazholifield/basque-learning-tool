import csv
from collections import defaultdict

def load_conjugations(path="data/conjugations.csv"):
    """Load conjugation data into a dictionary grouped by tense."""
    data = defaultdict(list)
    with open(path, encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for row in reader:
            verb = row["verb"].strip(),
            translation = row["translation"].strip(),
            tense = row["tense"].strip()
            person = row["person"].strip()
            conj = row["conjugation"].strip()
            data[tense].append({
                "verb": verb,
                "translation": translation,
                "tense": tense,
                "person": person,
                "conjugation": conj
            })
    return dict(data)
