import csv
from collections import defaultdict

def load_declensions(path="data/declensions.csv"):
    """Load declension data into a dictionary grouped by case."""
    data = defaultdict(list)
    with open(path, encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for row in reader:
            noun = row["noun"].strip()
            translation = row["translation"].strip()
            case = row["case"].strip()
            number = row["number"].strip()
            decl = row["declension"].strip()
            data[case].append({
                "noun": noun,
                "translation": translation,
                "case": case,
                "number": number,
                "declension": decl
            })
    return dict(data)
