import openai
import os

openai.api_key = os.getenv("OPENAI_API_KEY")

def generate_basque_text(topic="food", length="short", level="beginner"):
    prompt = (
        f"Write a {length} Basque text suitable for a {level} learner about '{topic}'. "
        f"Then provide an English translation separated by '---'."
    )
    response = openai.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.7,
        max_tokens=300
    )
    content = response.choices[0].message.content
    if "---" in content:
        basque, english = content.split("---", 1)
        return basque.strip(), english.strip()
    else:
        return content.strip(), None

def evaluate_summary(user_summary, reference_summary):
    """
    Compare user's English summary to reference English text.
    Returns feedback as a string.
    """
    prompt = (
        f"Here is a reference English summary:\n{reference_summary}\n\n"
        f"Here is a user's summary:\n{user_summary}\n\n"
        f"Give a short evaluation: what is correct, what is missing or inaccurate. "
        f"Provide a score out of 10."
    )
    response = openai.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": prompt}],
        temperature=0,
        max_tokens=150
    )
    return response.choices[0].message.content.strip()
