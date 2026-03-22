import os

def load_opus_corpus(folder_path):
    en_file = next(f for f in os.listdir(folder_path) if f.endswith('.en'))
    eu_file = next(f for f in os.listdir(folder_path) if f.endswith('.eu'))
    
    with open(os.path.join(folder_path, en_file), 'r', encoding='utf-8') as en_f:
        en_lines = en_f.read().splitlines()
    with open(os.path.join(folder_path, eu_file), 'r', encoding='utf-8') as eu_f:
        eu_lines = eu_f.read().splitlines()
    
    return list(zip(en_lines, eu_lines))

pairs = load_opus_corpus("en-eu.txt/")
print(pairs)
