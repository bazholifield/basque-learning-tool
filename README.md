# Basque Learning App

This is a small project I started as a way to help myself learn Basque. I wanted something more interactive and customizable than traditional resources, so I built a simple app with different tools to practice vocabulary and grammar

Right now, the app includes things like:

* Practice activities for noun declensions and other grammar concepts
* A “learn” section with explanations and examples
* An offline translator I’ve been experimenting with

It’s still a work in progress, but I’ve been gradually expanding it as I learn more Basque and as I think of new features that would actually be useful for studying.

---

## Features

* **Practice**

  * Exercises (noun declensions and verb conjugations)
  * Flash cards for vocabulary with case, number, etc. 
  * Barebones reading/writing activities to practice translation

* **Learning**

  * Plain-English explanations of grammatical concepts
  * Examples for each case and structure

* **Translator**

  * Basque to English translation
  * Runs on a locally downloaded model (no API required)
  * Still experimental but useful for quick checks

---

## Structure

* The app is built with Streamlit right now for UI and interaction.
* The **frontend** (in `frontend/`) defines what the user sees and interacts with.
* The **backend** (in `backend/`) handles data loading and model logic.
* Data (like declensions and explanations) lives in `data/` and is loaded dynamically.

The goal was to keep things modular so I can easily:

* Add new activities
* Swap in better datasets
* Improve individual components without breaking everything

---

## Future Plans

* Improve the interface (it’s pretty barebones right now)
* Add more and better practice modes (sentence building, lessons, maybe speakin and listening practice, etc.)
* Expand the translation system
* Support additional languages beyond Basque
* Clean up and standardize the linguistic data

---

## Why I Built This

This project is mainly for personal use so I could figure out how I learn best. At the same time, it’s been a great way to practice building tools, working with language data, and applying NLP concepts in a practical setting.
