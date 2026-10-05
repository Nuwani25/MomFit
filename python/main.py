import json, time
from flask import Flask, jsonify, request, make_response, send_from_directory
from flask_cors import CORS
import cv2
import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing.image import load_img, img_to_array
from keras.models import load_model
from tensorflow.keras.preprocessing import image
import tensorflow_hub as hub
import os
import pickle
from tensorflow.keras.utils import custom_object_scope
import re
import speech_recognition as sr
import random
import pytesseract
from PIL import Image
import easyocr

pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

def anc_image(image_path):
    img = cv2.imread(image_path)

    # Convert to grayscale
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # Use adaptive threshold to isolate handwriting (darker ink)
    thresh = cv2.adaptiveThreshold(
        gray, 255, cv2.ADAPTIVE_THRESH_MEAN_C, cv2.THRESH_BINARY_INV, 25, 15
    )

    # Remove small noise
    kernel = np.ones((2, 2), np.uint8)
    clean = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, kernel, iterations=1)

    # Find connected components
    contours, _ = cv2.findContours(clean, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # Initialize OCR (English only)
    reader = easyocr.Reader(['en'])

    handwritten_texts = []

    for c in contours:
        x, y, w, h = cv2.boundingRect(c)
        # Skip small printed text areas
        if 20 < w < 400 and 10 < h < 100:
            roi = gray[y:y+h, x:x+w]
            roi = cv2.bitwise_not(roi)
            ocr_result = reader.readtext(roi, detail=0, paragraph=False)
            for text in ocr_result:
                if text.strip():
                    handwritten_texts.append(text.strip())

    # Sort results by vertical position
    handwritten_texts = handwritten_texts[::-1]  # simple top-to-bottom heuristic
    print("Detected handwritten values:\n", handwritten_texts)

def extract_form_values(image_path):
    """
    Extract marked values from medical form using OCR
    """
    # Read image
    img = cv2.imread(image_path)
    if img is None:
        print(f"Error: Could not read image from {image_path}")
        return
    
    # Convert to grayscale
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    # Apply preprocessing for better OCR
    # Increase contrast
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)
    
    # Thresholding
    _, thresh = cv2.threshold(enhanced, 150, 255, cv2.THRESH_BINARY)
    
    # Full text extraction with pytesseract
    full_text = pytesseract.image_to_string(Image.fromarray(enhanced), lang='eng')
    
    # Extract data with confidence scores
    data = pytesseract.image_to_data(Image.fromarray(enhanced), output_type=pytesseract.Output.DICT)
    
    # Filter results with reasonable confidence
    high_confidence_results = []
    for i in range(len(data['text'])):
        if int(data['conf'][i]) > 30 and data['text'][i].strip():
            high_confidence_results.append({
                'text': data['text'][i],
                'confidence': int(data['conf'][i]),
                'left': data['left'][i],
                'top': data['top'][i],
                'width': data['width'][i],
                'height': data['height'][i]
            })
    
    for result in high_confidence_results:
        if result['confidence'] > 50:
            print(f"Text: '{result['text']}' | Confidence: {result['confidence']}%")
    
    return full_text, high_confidence_results

def extract_postprandial_glucose(text: str):
    
    patterns = [
        r'POSTPRANDIAL\s+PLASMA\s+GLUCOSE[^\d\n\r\-]*([0-9]+(?:\.[0-9]+)?)\s*([A-Za-zμµ/%\.]+)?',
        r'POSTPRANDIAL[^\d\n\r\-]*([0-9]+(?:\.[0-9]+)?)\s*([A-Za-zμµ/%\.]+)?'
    ]

    for p in patterns:
        m = re.search(p, text, flags=re.IGNORECASE)
        if m:
            return m.group(1)

    m2 = re.search(r'GLUCOSE[^\d\n\r]*([0-9]+(?:\.[0-9]+)?)\s*([A-Za-zμµ/%\.]+)?', text, flags=re.IGNORECASE)
    if m2:
        return m2.group(1)

    return None

def extract_haemoglobin(text: str):
    
    pattern = r'HAEMOGLOBIN[^\d\n\r]*([0-9]+(?:\.[0-9]+)?)\s*([A-Za-z/%µμ\.]+)?'

    match = re.search(pattern, text, flags=re.IGNORECASE)
    if match:
        return match.group(1)
    return None

def extract_glucose_values(text):
    # Define regex patterns for each value
    fasting_pattern = r"FASTING\s+PLASMA\s+GLUCOSE\s+VENOUS\s*=\s*(\d+)"
    one_hr_pattern = r"PLASMA\s+GLUCOSE\s+1hr.*?=\s*(\d+)"
    two_hr_pattern = r"PLASMA\s+GLUCOSE\s+2hrs.*?=\s*(\d+)"

    # Search values using regex
    fasting = re.search(fasting_pattern, text, re.IGNORECASE)
    one_hr = re.search(one_hr_pattern, text, re.IGNORECASE)
    two_hr = re.search(two_hr_pattern, text, re.IGNORECASE)

    # Return only numbers (no units)
    return {
        "fasting": fasting.group(1) if fasting else 0,
        "1hr": one_hr.group(1) if one_hr else 0,
        "2hr": two_hr.group(1) if two_hr else 0
    }

with open("models/model_nlp.dat", "rb") as f:
    nlp_model = pickle.load(f)

with open("models/m_model.dat", "rb") as f:
    meal_model = pickle.load(f)

with open("models/recom_model.dat", "rb") as f:
    recom_model = pickle.load(f)

with open("models/risk_model.dat", "rb") as f:
    risk_model = pickle.load(f)

with open("models/diabetes_model.dat", "rb") as f:
    diabetes_model = pickle.load(f)

with open("models/birth_weight_model.dat", "rb") as f:
    birth_weight_model = pickle.load(f)


def sound_convert(file):
    print(file.split(".")[0] + ".mp3 ")
    commandwav = (
        "ffmpeg -i " + file.split(".")[0] + ".mp3 " + file.split(".")[0] + ".wav"
    )
    os.system(commandwav)


def wav_to_text(file_path):
    # Initialize recognizer
    recognizer = sr.Recognizer()

    # Load audio file
    with sr.AudioFile(file_path) as source:
        audio_data = recognizer.record(source)

    try:
        # Recognize speech using Google's speech recognition
        text = recognizer.recognize_google(audio_data)
        return text
    except sr.UnknownValueError:
        return "Could not understand audio"
    except sr.RequestError as e:
        return f"Error with speech recognition service: {e}"


sys_keywords = {"data": ["dealing", "rarely", "occasionally", "several", "advice", "back", "nausea",
        "should", "mood", "swings", "having", "heartburn", "constipation", "restless",
        "syndrome", "dizziness", "swelling", "cramps", "insomnia", "shortness", "breath",
        "food", "cravings", "fatigue", "carpal", "tunnel", "bleeding", "itchy", "skin",
        "pelvic", "pressure", "nasal", "congestion", "vivid", "dreams", "varicose",
        "veins", "braxton", "hicks", "contractions", "round", "ligament", "headaches",
        "metallic", "taste", "urination", "sensitive", "teeth"]}

def detect_txt_key(text):
    text_lower = text.lower()
    scores = {txt_key: 0 for txt_key in sys_keywords}

    for txt_key, keywords in sys_keywords.items():
        for keyword in keywords:
            if re.search(r"\b" + re.escape(keyword) + r"\b", text_lower):
                scores[txt_key] += 1

    # Get txt_key with the highest count
    top_txt_key = max(scores, key=scores.get)

    if scores[top_txt_key] == 0:
        return "no_keyword"
    return top_txt_key

cat1BF = [
    "String hoppers (idiyappam) 5–6 + pol sambal 1/4 cup + boiled egg, 1",
    "Red rice 1 cup (cooked) + dhal (parippu) curry, ½ cup + pol sambal 2 tbsp + boiled egg, 1",
    "Idli 2–3 + sambar, ¾ cup + coconut chutney 1 tbsp",
    "Finger millet (Kurakkan) roti 2 small + chickpea (kadala) curry, ¾ cup",
    "Plain oatmeal ¾ cup dry (60 g) cooked in 200 ml milk + crushed nuts 1 tbsp + sliced fruit ½ cup",
    "Whole-grain toast 2 slices (~60 g) + scrambled eggs (2) + avocado ½",
    "Three Kiribath slices (small) + 1 ripe banana",
    "1 cup boiled chickpeas + 1 boiled egg",
]

cat1MMS = [
    "Fresh seasonal fruit, 1 cup + unsalted nuts, 20–25 g",
    "Unsweetened curd/yogurt, 100–150 ml + sliced fruit ½ cup",
    "Boiled corn",
    "Milk (unsweetened) 150–200 ml + small banana 1",
    "Fresh coconut water 200 ml + few peanuts 15 g",
    "Fresh juice (unsweetened)",
]

cat1L = [
    "Red rice 1 cup + beans (Bonchi) curry, ½ cup + skinless chicken curry, 75–90 g + fresh vegetable salad with lime, ½ cup",
    "Red rice 1 cup + pumpkin (Wattakka) curry, ½ cup + fish curry, 90–120 g + cucumber salad with lime, ½ cup",
    "1 cup red rice + ½ cup lady finger (Bandakka) curry + ½ cup dhal curry + 2 fish slices",
    "1 cup red rice + 1 egg (boiled or egg curry) + ½ cup snake gourd (Pathola) curry + gotu kola sambol with lime, ½ cup",
    "1 cup red rice + ½ cup jackfruit (Kos) curry + ½ cup spinach (Nivithi) stir-fry + 1 boiled egg",
    "1 cup red rice + ½ cup dhal (Parippu) curry + ½ cup beetroot curry + ½ cup fish curry",
    "1 cup red rice + ½ cup radish (Raabu) stir-fry + ½ cup dhal (Parippu) curry + tomato-onion salad with lemon juice, ½ cup",
]

cat1ES = [
    "Steamed sweet potato 1 small",
    "1 small healthy muffin (banana/oats-based) + 1 cup plain tea (no sugar)",
    "Whole-grain crackers 3–4 + unsweetened yogurt 2 tbsp",
    "Roasted peanuts 25 g",
    "1 cup plain tea + 2 small squares of dark chocolate (70% cocoa)",
]

cat1D = [
    "Red rice ¾–1 cup + vegetable curry, ½ cup + fish curry, 90–120 g (light gravy)",
    "String hoppers 5 + dhal (parippu) curry, ½ cup",
    "1 egg hopper + 2 plain hoppers + 1 teaspoon lunu miris",
    "Chapati 2 small + skinless chicken curry, 75–90 g (light gravy)",
    "2 dosa + ½ cup sambar + 1 teaspoon coconut chutney",
    "1 cup pittu + ½ cup fish curry",
    "2 oats pancakes (unsweetened) + 1 teaspoon bee honey + ½ cup fresh fruits",
    "1 bowl soup + 1 slice whole grain bread",
]

cat2BF = [
    "String hoppers 5–6 + fish curry, 90–120 g + 2 tbsp coconut sambol",
    "Idli 2 + sambar, ¾ cup + coconut chutney 1 tsp",
    "Finger millet (Kurakkan) roti 2 small + chickpea (kadala) curry, ¾ cup",
    "Plain oatmeal ¾ cup dry (60 g) cooked in 200 ml milk + crushed nuts 1 tbsp + sliced fruit ½ cup",
    "Whole-grain toast 2 slices (~60 g) + scrambled eggs (2) + avocado ½",
    "1 cup boiled green grams (mung beans) + 1 small ripe banana",
    "1 cup boiled chickpeas + 1 boiled egg",
]

cat2MMS = [
    "Guava 1 medium + unsalted nuts, 20–25 g",
    "Unsweetened curd/yogurt, 100–150 ml",
    "Roasted chickpeas 30 g",
    "Apple/pear 1 small + peanuts 15 g",
    "Papaya ¾ cup + 10–12 almonds",
    "1 glass of Kola Keda + 2 dates",
    "1 glass fresh juice (unsweetened)",
]

cat2L = [
    "Red rice 1 cup + ½ cup ridge gourd (Wetakolu) curry + skinless chicken curry, 90–120 g (grilled/curried)",
    "Red rice 1 cup + tofu/soya curry, ¾ cup + vegetable salad with lime, ½ cup",
    "Red rice 1 cup + beans (Bonchi) curry, ½ cup + skinless chicken curry, 75–90 g + fresh vegetable salad with lime, ½ cup",
    "Red rice 1 cup + pumpkin (Wattakka) curry, ½ cup + fish curry, 90–120 g + cucumber salad with lime, ½ cup",
    "1 cup red rice + ½ cup lady finger (Bandakka) curry + ½ cup potato curry + 2 fish slices",
    "1 cup red rice + 1 egg (boiled or egg curry) + ½ cup snake gourd (Pathola) curry + gotu kola sambol with lime, ½ cup",
    "1 cup red rice + ½ cup jackfruit (Kos) curry + ½ cup spinach (Nivithi) stir-fry + 1 boiled egg",
    "1 cup red rice + ½ cup dhal (Parippu) curry + ½ cup beetroot curry + ½ cup fish curry",
    "1 cup red rice + ½ cup radish (Raabu) stir-fry + ½ cup dhal (Parippu) curry + tomato-onion salad with lemon juice, ½ cup + 1 egg (boiled or fried)",
]

cat2ES = [
    "Unsweetened curd/yogurt, 100–150 ml + nuts 15 g",
    "Boiled gram (kadala) ½ cup",
    "Small banana 1 + peanuts 15 g",
    "Fresh coconut water 200 ml + roasted gram 20 g",
    "Papaya ¾ cup",
    "1 glass fresh milk (unsweetened) + 2 oatmeal cookies (unsweetened)",
]

cat2D = [
    "String hoppers 5 + dhal (parippu) curry, ½ cup",
    "Chapati 2 small + grilled fish, 100–120 g",
    "Finger millet (Kurakkan) roti 2 small + skinless chicken curry, ¾ cup + vegetables ¾ cup",
    "Whole-grain toast 2 slices (~60 g) + scrambled eggs (2)",
    "1 bowl soup + 1 slice whole grain bread + 1 teaspoon butter",
    "1 cup pittu + ½ cup kiri hodi (coconut milk gravy) + 1 boiled egg",
    "2 dosa + ½ cup sambar + 1 teaspoon coconut chutney",
]

cat3BF = [
    "String hoppers 6 + skinless chicken curry, ½ cup (low salt)",
    "Red rice 1 cup + dhal (parippu) curry, ½ cup (low salt) + leafy greens (mallum), ½ cup",
    "Idli 2–3 + sambar, ¾ cup (no added salt at table)",
    "Finger millet (Kurakkan) roti 2 small + chickpea (kadala) curry, ¾ cup (low salt)",
    "1 cup boiled green grams (mung beans) + 1 small ripe banana",
    "1 cup kurakkan porridge + papaya slices",
    "1 cup cooked oats with ½ cup milk + 1 teaspoon jaggery + 5 almonds",
    "Whole-grain toast 2 slices (~60 g) + scrambled eggs (2)",
    "2 dosa + ½ cup sambar + 1 teaspoon coconut chutney (low salt)",
]

cat3MMS = [
    "Fresh seasonal fruit, 1 cup",
    "Banana (small) 1 + unsalted peanuts 15 g",
    "King coconut water 200 ml + roasted gram 20 g",
    "1 glass of Kola Keda + 2 dates",
    "½ cup Greek yogurt + 1 teaspoon bee honey + 5 almonds",
    "1 handful (20 g) mixed nuts + 1 glass fresh lime juice (unsweetened)",
    "½ cup fresh fruit salad (papaya, banana, orange) + sprinkle of chia seeds",
]

cat3L = [
    "Red rice 1 cup + beans (Bonchi) curry, ½ cup + skinless chicken curry, 75–90 g + fresh vegetable salad with lime, ½ cup",
    "Red rice 1 cup + pumpkin (Wattakka) curry, ½ cup + fish curry, 90–120 g + cucumber salad with lime, ½ cup",
    "1 cup red rice + ½ cup lady finger (Bandakka) curry + ½ cup dhal curry + 2 fish slices",
    "1 cup red rice + 1 egg (boiled or egg curry) + ½ cup snake gourd (Pathola) curry + gotu kola sambol with lime, ½ cup",
    "1 cup red rice + ½ cup jackfruit (Kos) curry + ½ cup spinach (Nivithi) stir-fry + 1 boiled egg",
    "1 cup red rice + ½ cup dhal (Parippu) curry + ½ cup beetroot curry + ½ cup fish curry",
    "1 cup red rice + ½ cup radish (Raabu) stir-fry + ½ cup dhal (Parippu) curry + tomato-onion salad with lemon juice, ½ cup",
]

cat3ES = [
    "Steamed corn 1 (no added salt)",
    "Roasted unsalted peanuts 20 g",
    "Steamed sweet potato 1 small",
    "1 small healthy muffin (banana/oats-based) + 1 cup plain tea (no sugar)",
    "Whole‑grain crackers 3–4 + unsweetened yogurt 2 tbsp",
    "Roasted peanuts 25 g",
    "1 cup plain tea + 2 small squares of dark chocolate (70% cocoa)",
]

cat3D = [
    "Red rice ¾–1 cup + vegetable curry, ½ cup + fish curry, 90–120 g (light gravy)",
    "String hoppers 5 + dhal (parippu) curry, ½ cup",
    "1 egg hopper + 2 plain hoppers + 1 teaspoon lunu miris (less salt)",
    "Chapati 2 small + skinless chicken curry, 75–90 g (light gravy)",
    "2 dosa + ½ cup sambar + 1 teaspoon coconut chutney",
    "1 cup pittu + ½ cup fish curry",
    "2 oats pancakes (unsweetened) + 1 teaspoon bee honey + ½ cup fresh fruits",
    "1 bowl soup + 1 slice whole grain bread",
]

cat4BF = [
    "Three Kiribath slices(small) + 1 Tablespoon lunumiris (squeeze lemon juice) + 1 ripe banana",
    "1 cup cooked oats with ½ cup milk + 1 teaspoon jaggery + 5 almonds",
    "1 cup boiled chickpeas + 1 boiled egg + pinch of salt and lime juice",
    "2 slices whole grain bread + 1 boiled egg + 1 teaspoon peanut butter",
    "Two boiled sweet potatoes (medium size) + 1 glass warm milk + 3 cashew nuts",
    "1 cup boiled green grams (mung beans) + 1 small ripe banana",
    "2 dosa + ½ cup sambar + 1 teaspoon coconut chutney(squeeze lemon juice)",
    "1 cup boiled red cowpeas + 2 Tablespoons coconut sambol(squeeze lemon juice) + 1 small banana",
    "2 idlis + ½ cup coconut chutney + 1 banana",
    "3 medium finger millet (kurakkan) rottis +1 tablespoon coconut sambol",
]

cat4MMS = [
    "Guava 1 medium (vit‑C) + peanuts 15 g",
    "Papaya 1 cup",
    "Fresh lime water (unsweetened) 200 ml + 3 cashews nuts",
    "Unsweetened curd/yogurt, 100–150 ml",
    "Banana (small) 1 + peanuts 15 g",
    "Orange 1 medium",
]

cat4L = [
    "Red rice 1–1¼ cup + leafy greens (mallum) (squeeze lemon juice), ½ cup + fresh fish curry, 90–120 g + ½ dhal (Parippu) curry",
    "Red rice 1 cup + chickpea (kadala) curry, ¾ cup + tomato/cucumber salad ½ cup with lemon juice",
    "1 cup rice + ½ cup chicken curry + ½ cup ridge gourd (Wetakolu) curry + 1 teaspoon lime pickle",
    "1 cup red rice + ½ cup dhal curry + ½ cup beetroot curry + ½ cup fish curry",
    "1 cup steamed rice + ½ cup soya meat curry + ½ cup ash plantain (Alu Kesel) curry + cucumber salad with lime juice",
    "1 cup rice + ½ cup fish ambul thiyal + ½ cup drumstick (Murunga) curry + tomato-onion salad with lemon juice",
    "1 cup red rice + 1 egg (boiled or egg curry) + ½ cup snake gourd (Pathola) curry + gotu kola sambol with lime juice",
    "1 cup red rice + ½ cup dhal curry + ½ cup cabbage & carrot stir-fry + 2–3 small pieces dry fish fry (karawala thel dala)",
    "1 cup steamed rice + ½ cup potato & leeks curry + ½ cup long beans (Maa karal) stir-fry + tomato-onion salad with lime juice",
    "1 cup red rice + ½ cup lady finger (Bandakka) curry + ½ cup dhal curry + 2 fish slices",
    "1 cup white rice + ½ cup capsicum (Maalu miris) stir-fry + ½ cup pumpkin curry + 1 boiled egg",
    "1 cup red rice + ½ cup radish (Rabu) stir-fry + ½ cup dhal curry + boiled egg + tomato-onion salad with lemon juice",
]

cat4ES = [
    "1 lavariya (steamed coconut & jaggery-filled string hopper) + 1 glass warm milk",
    "1 pancake (coconut & treacle filling) + 1 small ripe banana",
    "1 handful (20g) mixed nuts + 2 dates",
    "1 glass fresh milk + 2 oatmeal cookies (unsweetened)",
    "1 glass fresh fruit juice (mango or papaya, no added sugar) + 1 muffin",
    "1 handful (20g) roasted cashew nuts + 3 raisins",
    "2 grain crackers(small) + 1 glass plain milk (less sugar)",
    "2 small squares of dark chocolate (70% cocoa) + 1 small handful of mixed nuts",
]

cat4D = [
    "String hoppers 6 + dhal (parippu) curry, ½ cup + 1 egg",
    "1 egg hopper + 2 plain hoppers + 1 teaspoon lunu miris with lime juice",
    "1 Baked potato(small) + grilled fish slices (2-3) + fresh salad with lime, ½ cup",
    "1 small bowl noodles with mixed vegetables + 1 boiled egg",
    "2 rottis with dhal curry + tomato salad with lime juice",
]

cat5BF = [
    "String hoppers 6 + kiri hodi ½ cup + boiled egg, 1",
    "Idli 2–3 + sambar, ¾ cup + coconut chutney 1 tbsp",
    "1 cup kurakkan porridge + jaggery (1 small piece)",
    "1 cup boiled chickpeas + 1 boiled egg",
    "2 slices whole grain bread + 1 boiled egg + 1 teaspoon peanut butter",
    "Two boiled sweet potatoes (medium size) + 1 glass warm milk",
    "1 cup boiled green grams (mung beans) + 1 small ripe banana",
    "2 dosa + ½ cup sambar + 1 teaspoon coconut chutney",
]

cat5MMS = [
    "1 yoghurt cup",
    "3 roasted cashews",
    "banana (small) 1 + nuts 15–20 g",
    "papaya 1 cup",
    "king coconut water 200 ml + roasted peanuts 20 g",
]

cat5L = [
    "Red rice 1–1¼ cup + leafy greens (mallum), ½ cup + fresh fish curry1 cup + ½ dhal (Parippu) curry",
    "1 cup red rice + ½ cup dhal curry + ½ cup beetroot curry + ½ cup fish curry",
    "1 cup steamed rice + ½ cup soya meat curry + ½ cup ash plantain (Alu Kesel) curry + cucumber salad with lime juice",
    "1 cup rice + ½ cup fish ambul thiyal + ½ cup drumstick (Murunga) curry + tomato-onion salad with lemon juice",
    "1 cup red rice + 1 egg (boiled or egg curry) + ½ cup snake gourd (Pathola) curry + gotu kola sambol with lime juice",
    "1 cup red rice + ½ cup dhal curry + ½ cup cabbage & carrot stir-fry + 2–3 small pieces dry fish fry (karawala thel dala)",
    "1 cup steamed rice + ½ cup potato & leeks curry + ½ cup long beans (Maa karal) stir-fry + tomato-onion salad with lime juice",
    "1 cup red rice + ½ cup lady finger (Bandakka) curry + ½ cup dhal curry + 2 fish slices",
    "1 cup white rice + ½ cup capsicum (Maalu miris) stir-fry + ½ cup pumpkin curry + 1 boiled egg",
    "1 cup red rice + ½ cup radish (Rabu) stir-fry + ½ cup dhal curry + boiled egg + tomato-onion salad with lemon juice",
]

cat5ES = [
    "roasted peanuts 20–25 g",
    "steamed corn 1",
    "2 grain crackers(small) + 1 glass plain milk coffee (less sugar)",
    "1 small healthy muffin (banana/oats-based) + 1 cup plain tea (no sugar or less sugar)",
    "1 lavariya (steamed coconut & jaggery-filled string hopper) + 1 glass warm milk (no sugar)",
]

cat5D = [
    "2 dosa + ½ cup sambar + 1 teaspoon coconut chutney",
    "3 idlis + ½ cup sambar",
    "1 small bowl noodles with mixed vegetables + 1 boiled egg",
    "2 rottis with dhal curry",
    "1 cup pittu + ½ cup kiri hodi (coconut milk gravy) + 1 boiled egg",
    "½ cup baked chicken (skinless, low oil) + baked potato (small) + salad",
]

cat6BF = [
    "3 Kiribath slices (~150 g) + 1 tbsp lunumiris + maalu abul thiyal (2-3 slices)",
    "String hoppers 8–10 + veg kiri hodi ¾ cup + boiled egg, 1",
    "Idli 4 + sambar, ¾ cup + coconut chutney 1 tbsp",
    "Kurakkan roti 3 small + dhal (parippu) curry, ½ cup + fresh salad with lime, ½ cup",
    "1 cup cooked oats with ½ cup milk + 1 teaspoon jaggery + 5 almonds",
    "Two boiled sweet potatoes (medium size) + 1 glass warm milk + 3 cashew nuts",
]

cat6MMS = [
    "Cup of yoghurt + banana (small) 1",
    "fruit smoothie (no added sugar) 200 ml",
    "avocado ½ medium",
    "milk 200 ml + dates 2",
    "½ cup fresh fruit salad (papaya, banana, orange) + sprinkle of chia seeds",
]

cat6L = [
    "1 cup rice + ½ cup mutton curry + ½ cup ridge gourd (Wetakolu) curry + 1 teaspoon lime pickle",
    "1 cup red rice + ½ cup dhal curry + ½ cup beetroot curry + ½ cup prawns curry",
    "1 cup steamed rice + ½ cup pork curry + ½ cup ash plantain (Alu Kesel) curry + cucumber salad",
    "1 cup red rice + ½ cup mutton curry + ½ cup snake gourd (Pathola) curry + gotu kola sambol",
    "1 cup red rice + ½ cup dhal curry + ½ cup cabbage & carrot stir-fry + 2–3 small pieces dry fish fry (karawala thel dala)",
    "1 cup steamed rice + ½ cup potato & leeks curry + ½ cup long beans (Maa karal) stir-fry + beef curry, ½ cup",
    "1 cup red rice + ½ cup lady finger (Bandakka) curry + ½ cup carrot curry + ½ prawns curry",
    "1 cup white rice + ½ cup capsicum (Maalu miris) stir-fry + ½ cup pumpkin curry + 1 boiled egg",
]

cat6ES = [
    "1 small healthy muffin (banana/oats-based) + 1 cup plain tea (no sugar or less sugar)",
    "2 biscuits + 1 handful (20g) mixed nuts + 2 dates",
    "1 glass fresh milk + 2 oatmeal cookies (unsweetened)",
    "1 handful (20g) roasted cashew nuts + 3 raisins + 1 small piece jaggery",
    "2 grain crackers(small) + 1 glass plain milk coffee (less sugar)",
]

cat6D = [
    "1 small bowl noodles with vegetables and chicken + 1 boiled egg",
    "2 rottis with pork curry(1/2 cup)",
    "1 cup pittu + ½ cup kiri hodi (coconut milk gravy) + 1 boiled egg",
    "1 oven-baked beef slice + ½ cup steamed vegetables (broccoli, carrot, beans) + 1 small baked potato",
    "1 bowl vegetable soup + 1 slice whole grain bread + 1 teaspoon butter",
    "1 egg hopper + 2 plain hoppers + 1 teaspoon lunu miris",
]


cat7BF = [
    "String hoppers 4–6 + egg curry, ½ cup (light gravy)",
    "Hoppers 1–2 + veg stew ½–¾ cup",
    "Idli 2 + sambar, ¾ cup (no extra oil)",
    "Kurakkan roti 1–2 small + dhal (parippu) curry, ¾ cup",
    "Plain oatmeal ¾ cup dry (60 g) cooked in 200 ml milk + crushed nuts 1 tbsp + sliced fruit ½ cup",
    "Whole-grain toast 2 slices (~60 g) + scrambled eggs (2) + avocado ½",
]
cat7MMS = [
    "roasted unsalted peanuts 15–20 g",
    "king coconut water 200 ml",
    "½ cup Greek yogurt + 1 teaspoon bee honey",
    "1 glass of Kola Keda + 2 dates",
    "1 glass fresh orange juice",
]
cat7L = [
    "1 cup red rice + ½ cup carrot curry + 1 boiled egg + gotu kola sambol",
    "1 cup white rice + ½ cup chicken curry + ½ cup pumpkin (Wattakka) curry + grilled prawns",
    "1 cup red rice + ½ cup fish curry + ½ cup brinjal (Wambatu) moju + ½ cup beans (Bonchi) curry",
    "1 cup steamed rice + ½ cup dhal (Parippu) curry + ½ cup carrot & bean stir-fry + 1 boiled egg",
    "1 cup red rice + ½ cup jackfruit (Kos) curry + ½ cup spinach (Nivithi) stir-fry + 1 small beef piece",
    "1 cup rice + ½ cup mutton curry + ½ cup ridge gourd (Wetakolu) curry + tomato-onion salad ½ cup",
    "1 cup red rice + ½ cup dhal curry + ½ cup beetroot curry + ½ cup prawns curry",
    "1 cup steamed rice + ½ cup soya meat curry + ½ cup ash plantain (Alu Kesel) curry + fish curry ½ cup",
    "1 cup rice + ½ cup fish ambul thiyal + ½ cup drumstick (Murunga) curry + 1 teaspoon coconut sambol",
    "1 cup red rice + 1 egg (boiled or egg curry) + ½ cup snake gourd (Pathola) curry + gotu kola sambol",
]
cat7ES = [
    "2 grain crackers(small) + 1 glass plain milk coffee (no sugar)",
    "1 cup plain tea + 2 small squares of dark chocolate (70% cocoa) + 1 small handful of mixed nuts",
    "1 small healthy muffin (banana/oats-based) + 1 cup plain tea (no sugar or less sugar)",
    "1 glass fresh fruit juice (mango or papaya, no added sugar)",
    "small banana 1 + peanuts 15 g",
]
cat7D = [
    "2 dosa + ½ cup sambar + 1 teaspoon coconut chutney",
    "3 idlis + ½ cup sambar",
    "1 small bowl noodles with mixed vegetables + 1 boiled egg",
    "2 oats pancakes (unsweetened) + 1 teaspoon bee honey + ½ cup fresh fruit salad",
    "1 bowl chicken soup + 1 slice whole grain bread",
    "1 cup fresh fruit salad (papaya, apple, banana) + ½ cup low-fat yogurt + sprinkle of chia seeds",
]

cat8BF = [
    "String hoppers 6 + kiri hodi ½ cup + boiled egg, 1",
    "Red rice 1 cup + dhal (parippu) curry, ½ cup + pol sambol, ½ cup",
    "Idli 3 + sambar, ¾ cup + coconut chutney, 2 tbsp",
    "1 cup boiled chickpeas + 1 boiled egg",
    "2 slices whole grain bread + 1 boiled egg + 1 teaspoon peanut butter",
]
cat8MMS = [
    "banana (small) 1 + nuts 15–20 g",
    "curd/yogurt, 100–150 ml",
    "fruit bowl 1 cup",
    "1 glass fresh king coconut water + 3 cashew nuts",
    "1 glass of Kola Keda + 2 dates",
]
cat8L = [
    "1 cup red rice + ½ cup dhal curry + ½ cup beetroot curry + ½ cup prawns curry",
    "1 cup rice + ½ cup fish ambul thiyal + ½ cup drumstick (Murunga) curry + 1 teaspoon coconut sambol",
    "1 cup rice + fish curry, ½ cup + ½ cup snake gourd (Pathola) curry + gotu kola sambol",
    "1 cup rice + ½ cup dhal curry + ½ cup cabbage & carrot stir-fry + 2–3 small pieces dry fish fry (karawala thel dala)",
    "1 cup steamed rice + ½ cup potato & leeks curry + ½ cup long beans (Maa karal) stir-fry + boiled egg + tomato-onion salad, ½ cup",
    "1 cup red rice + ½ cup lady finger (Bandakka) curry + ½ cup dhal curry + 2 fish slices(fried)+ mallung, ½ cup",
    "1 cup white rice + ½ cup capsicum (Maalu miris) stir-fry + ½ cup pumpkin curry + 1 boiled egg",
    "1 cup rice + ½ cup beef curry + ½ cup brinjal (Wambatu) moju + dhal curry + cucumber salad",
]
cat8ES = [
    "1 small healthy muffin (banana/oats-based) + 1 cup plain tea (no sugar or less sugar)",
    "1 glass fresh milk + 2 oatmeal cookies (unsweetened)",
    "1 slice baked vegetable roll (less oil) + 1 cup plain tea",
    "1 handful (20g) roasted cashew nuts + 3 raisins",
    "2 grain crackers(small) + 1 glass plain milk coffee (less sugar)",
    "1 cup plain tea + 2 small squares of dark chocolate (70% cocoa) + 1 small handful of mixed nuts",
]
cat8D = [
    "2 dosa + ½ cup sambar + 1 teaspoon coconut chutney",
    "3 idlis + ½ cup sambar",
    "1 small bowl noodles with mixed vegetables + 1 boiled egg",
    "2 medium rottis with dhal curry",
    "1 cup pittu + ½ cup kiri hodi (coconut milk gravy) + 1 boiled egg",
    "1-2 baked chicken pieces + medium potato, baked + salad, ½ cup",
    "2 oats pancakes (unsweetened) + 1 teaspoon bee honey + ½ cup fresh fruit salad",
    "1 oven-baked fish fillet + ½ cup steamed vegetables (broccoli, carrot, beans) + 1 small baked potato",
    "1 bowl vegetable soup + 1 slice whole grain bread + 1 teaspoon butter",
    "1 egg hopper + 2 plain hoppers + 1 teaspoon lunu miris",
]

cat9BF = [
    "String hoppers 6–8 + kiri hodi, ½ cup + coconut sambal, 2-3 tbs",
    "Idli 3–4 + sambar, ¾ cup + coconut chutney 1 tbsp",
    "1 cup boiled green grams (mung beans) + 1 small ripe banana",
    "Three Kiribath slices + 1 Tablespoon lunumiris + 1 ripe banana",
    "1 cup cooked oats with ½ cup milk + 1 teaspoon jaggery + 5 almonds",
]
cat9MMS = [
    "½ cup Greek yogurt + 1 teaspoon bee honey + 5 almonds",
    "½ cup fresh fruit salad (papaya, banana, orange) + sprinkle of chia seeds",
    "1 glass fresh orange juice + 2 oatmeal cookies (unsweetened)",
    "½ cup curd + 2 dates",
    "1 glass fresh king coconut water + 3 cashew nuts",
]
cat9L = [
    "Red rice 1 cup + vegetable curry, ½ cup + tofu/soya curry, ¾ cup + fresh salad with lime, ½ cup",
    "Brown/red rice 1 cup + chickpea (kadala) curry, ¾ cup + vegetables ¾ cup",
    "1 cup red rice + ½ cup dhal (Parippu) curry + ½ cup beans (Bonchi) curry + gotu kola sambol",
    "1 cup rice + ½ cup dhal (Parippu) curry + ½ cup brinjal (Wambatu) moju + cucumber salad",
    "1 cup rice + ½ cup soya meat curry + ½ cup ash plantain (Alu Kesel) curry + tomato-onion salad with lime juice",
]
cat9ES = [
    "1 small healthy muffin (banana/oats-based) + 1 cup plain tea (no sugar or less sugar)",
    "1 glass fresh milk + 2 oatmeal cookies (unsweetened)",
    "1 glass fresh fruit juice (mango,papaya,banana, no added sugar) + 1 muffin",
    "1 handful (20g) roasted cashew nuts + 3 dates",
    "2 grain crackers(small) + 1 glass plain milk coffee (less sugar)",
    "1 cup plain tea + 2 small squares of dark chocolate (70% cocoa) + 1 small handful of mixed nuts",
]
cat9D = [
    "2 dosa + ½ cup sambar + 1 teaspoon coconut chutney",
    "3 idlis + ½ cup sambar",
    "1 small bowl noodles with mixed vegetables",
    "2 rottis with dhal curry",
    "1 cup pittu + ½ cup kiri hodi (coconut milk gravy)",
    "2 oats pancakes (unsweetened) + 1 teaspoon bee honey + ½ cup fresh fruit salad",
    "1 bowl vegetable soup + 1 slice whole grain bread + 1 teaspoon butter",
    "1 cup fresh fruit salad (papaya, apple, banana) + ½ cup low-fat yogurt + sprinkle of chia seeds",
]

cat10BF = [
    "1 cup boiled chickpeas + 1 boiled egg",
    "2 slices whole grain bread + 1 boiled egg + 1 teaspoon peanut butter",
    "1 cup boiled green grams (mung beans) + 1 small ripe banana",
    "2 dosa + ½ cup sambar + 1 teaspoon coconut chutney",
    "Two boiled sweet potatoes (medium size) + 1 glass warm milk",
]
cat10MMS = [
    "banana (small) 1 + nuts 15–20 g",
    "½ cup Greek yogurt + 1 teaspoon bee honey + 5 almonds",
    "1 glass of Kola Keda + 2 dates",
    "1 glass fresh king coconut water + 3 cashew nuts",
    "1 glass fresh orange juice",
]
cat10L = [
    "1 cup red rice + ½ cup dhal (Parippu) curry + ½ cup beans (Bonchi) curry + 1 egg(fried) + gotu kola sambol",
    "1 cup white rice + ½ cup chicken curry (skinless) + ½ cup pumpkin (Wattakka) curry + 1 tbsp coconut sambol",
    "1 cup red rice + ½ cup fish curry + ½ cup brinjal (Wambatu) moju + cucumber salad with lime juice",
    "1 cup rice + ½ cup dhal (Parippu) curry + ½ cup carrot & bean stir-fry + 2-3 small pieces of fried dry fish(karawala thel dala)",
    "1 cup red rice + ½ cup jackfruit (Kos) curry + ½ cup spinach (Nivithi) stir-fry + 1 small beef piece, curry",
    "1 cup rice + ½ cup mutton curry + ½ cup ridge gourd (Wetakolu) curry + vegetable sad",
    "1 cup red rice + ½ cup potato curry + ½ cup beetroot curry + ½ cup prawns curry",
    "1 cup steamed rice + ½ cup soya meat curry + ½ cup ash plantain (Alu Kesel) curry + cucumber salad",
]
cat10ES = [
    "fruit bowl 1 cup (no syrup)",
    "roasted peanuts 20 g",
    "yoghurt + fruit ½ cup",
    "1 cup plain tea + 2 small squares of dark chocolate (70% cocoa) + 1 small handful of mixed nuts",
    "1 glass fresh fruit juice (mango or papaya, no added sugar)",
]
cat10D = [
    "2 dosa + ½ cup sambar + 1 teaspoon coconut chutney",
    "3 idlis + ½ cup sambar",
    "1 small bowl noodles with mixed vegetables + 1 boiled egg",
    "2 oats pancakes (unsweetened) + 1 teaspoon bee honey + ½ cup fresh fruit salad",
    "1 bowl vegetable, chicken soup + 1 slice whole grain bread + 1 teaspoon butter",
]

UPLOAD_FOLDER = "temp/"
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app = Flask(__name__)


@app.after_request
def after_request(response):
    response.headers.add("Access-Control-Allow-Origin", "*")
    response.headers.add("Access-Control-Allow-Headers", "Content-Type,Authorization")
    response.headers.add("Access-Control-Allow-Methods", "GET,PUT,POST,DELETE,OPTIONS")
    return response


@app.route("/chat", methods=["POST"])
def chat():

    try:

        text = str(request.form.get("text"))
        print(text)
        print(request.form.get("text"))

        if text.lower()=="hi":
            json_dump = json.dumps({"reply": str("hi"), "success": "true"})

            return json_dump
        elif text.lower()=="hello":
            json_dump = json.dumps({"reply": str("hi"), "success": "true"})

            return json_dump

        key_value = detect_txt_key(text)
        print(text)
        print(request.form.get("text"))
        if key_value != "no_keyword":

            results = nlp_model.predict([text])

            json_dump = json.dumps({"reply": str(results[0]), "success": "true"})

            return json_dump

        else:

            json_dump = json.dumps(
                {"reply": "this question something is wrong", "success": "true"}
            )

            return json_dump

    except:
        json_dump = json.dumps({"success": "false"})

        return json_dump


@app.route("/main_meal", methods=["POST"])
def main_meal():

    age = request.form.get("age")
    bmi = request.form.get("bmi")
    trimester = request.form.get("trimester")
    ethnicity = request.form.get("ethnicity")
    dietary_preference = request.form.get("dietary_preference")
    diabetes = request.form.get("diabetes")
    high_bp = request.form.get("high_bp")
    anemia = request.form.get("anemia")
    allergies = request.form.get("allergies")

    user_data = [
        [
            age * 1,
            bmi * 1,
            trimester * 1,
            ethnicity * 1,
            dietary_preference * 1,
            diabetes * 1,
            high_bp * 1,
            anemia * 1,
            allergies * 1,
        ]
    ]

    pre_data_main = meal_model.predict(user_data)[0]

    print(pre_data_main)

    if pre_data_main == 1:
        bf = random.choice(cat1BF)
        mms = random.choice(cat1MMS)
        l = random.choice(cat1L)
        es = random.choice(cat1ES)
        d = random.choice(cat1D)
    elif pre_data_main == 2:
        bf = random.choice(cat2BF)
        mms = random.choice(cat2MMS)
        l = random.choice(cat2L)
        es = random.choice(cat2ES)
        d = random.choice(cat2D)
    elif pre_data_main == 3:
        bf = random.choice(cat3BF)
        mms = random.choice(cat3MMS)
        l = random.choice(cat3L)
        es = random.choice(cat3ES)
        d = random.choice(cat3D)
    elif pre_data_main == 4:
        bf = random.choice(cat4BF)
        mms = random.choice(cat4MMS)
        l = random.choice(cat4L)
        es = random.choice(cat4ES)
        d = random.choice(cat4D)
    elif pre_data_main == 5:
        bf = random.choice(cat5BF)
        mms = random.choice(cat5MMS)
        l = random.choice(cat5L)
        es = random.choice(cat5ES)
        d = random.choice(cat5D)
    elif pre_data_main == 6:
        bf = random.choice(cat6BF)
        mms = random.choice(cat6MMS)
        l = random.choice(cat6L)
        es = random.choice(cat6ES)
        d = random.choice(cat6D)
    elif pre_data_main == 7:
        bf = random.choice(cat7BF)
        mms = random.choice(cat7MMS)
        l = random.choice(cat7L)
        es = random.choice(cat7ES)
        d = random.choice(cat7D)
    elif pre_data_main == 8:
        bf = random.choice(cat8BF)
        mms = random.choice(cat8MMS)
        l = random.choice(cat8L)
        es = random.choice(cat8ES)
        d = random.choice(cat8D)
    elif pre_data_main == 9:
        bf = random.choice(cat9BF)
        mms = random.choice(cat9MMS)
        l = random.choice(cat9L)
        es = random.choice(cat9ES)
        d = random.choice(cat9D)
    elif pre_data_main == 10:
        bf = random.choice(cat10BF)
        mms = random.choice(cat10MMS)
        l = random.choice(cat10L)
        es = random.choice(cat10ES)
        d = random.choice(cat10D)
    else:
        bf = mms = l = es = d = "No data for this category"

    return (
        jsonify(
            {
                "message": "Prediction successfully!",
                "main": str(pre_data_main),
                "BF": bf,
                "MMS": mms,
                "L": l,
                "ES": es,
                "D": d,
            }
        ),
        200,
    )


@app.route("/recom", methods=["POST"])
def recom():

    risk = request.form.get("risk")
    trimester = request.form.get("trimester")
    fitness_level = request.form.get("fitness_level")
    pregnancy_complications = request.form.get("pregnancy_complications")
    specific_goal = request.form.get("specific_goal")
    activity_before_pregnancy = request.form.get("activity_before_pregnancy")

    user_data = [
        [
            int(risk),
            int(trimester),
            int(fitness_level),
            int(pregnancy_complications),
            int(specific_goal),
            int(activity_before_pregnancy),
        ]
    ]
    print(user_data)

    pre_data = recom_model.predict(user_data)[0]

    print(pre_data)

    return (
        jsonify({"message": "Prediction successfully!", "result": str(pre_data)}),
        200,
    )


@app.route("/risk", methods=["POST"])
def risk():

    age = request.form.get("age")
    bmi = request.form.get("bmi")
    previous_complications = request.form.get("previous_complications")
    preexisting_diabetes = request.form.get("preexisting_diabetes")
    bp = request.form.get("bp")
    blood_sugar = request.form.get("blood_sugar")
    heart_rate = request.form.get("heart_rate")

    user_data = [
        [
            age * 1,
            bmi * 1,
            previous_complications * 1,
            preexisting_diabetes * 1,
            bp * 1,
            blood_sugar * 1,
            heart_rate * 1,
        ]
    ]

    pre_data = risk_model.predict(user_data)[0]

    print(pre_data)

    return (
        jsonify({"message": "Prediction successfully!", "result": str(pre_data)}),
        200,
    )


@app.route("/diabetes", methods=["POST"])
def diabetes():

    age_years = request.form.get("age_years")
    bmi_prepreg = request.form.get("bmi_prepreg")
    fh_diabetes = request.form.get("fh_diabetes")
    blood_sugar_week_8 = request.form.get("Blood_suger_week_8")
    blood_sugar_ogtt_fasting = request.form.get("Bloog_suger_OGTT_Fasting")
    blood_sugar_ogtt_one_hour = request.form.get("Blood_suger_OGTT_one_hour")
    blood_sugar_ogtt_two_hour = request.form.get("Blood_suger_OGTT_two_hour")

    user_data = [
        [
            int(age_years),
            float(bmi_prepreg),
            int(fh_diabetes),
            float(blood_sugar_week_8),
            float(blood_sugar_ogtt_fasting),
            float(blood_sugar_ogtt_one_hour),
            float(blood_sugar_ogtt_two_hour),
        ]
    ]

    pre_data = diabetes_model.predict(user_data)[0]

    print(pre_data)

    return (
        jsonify({"message": "Prediction successfully!", "result": str(pre_data)}),
        200,
    )


@app.route("/birth_weight", methods=["POST"])
def birth_weight():

    age = request.form.get("age")
    pre_pregnancy_bmi = request.form.get("pre_pregnancy_bmi")
    gestational_age_weeks = request.form.get("gestational_age_weeks")
    blood_pressure_systolic = request.form.get("blood_pressure_systolic")
    blood_pressure_diastolic = request.form.get("blood_pressure_diastolic")
    hemoglobin_level = request.form.get("hemoglobin_level")
    has_diabetes = request.form.get("has_diabetes")
    has_hypertension = request.form.get("has_hypertension")
    iron_supplementation = request.form.get("iron_supplementation")

    user_data = [
        [
            int(age),
            float(pre_pregnancy_bmi),
            int(gestational_age_weeks),
            int(blood_pressure_systolic),
            int(blood_pressure_diastolic),
            float(hemoglobin_level),
            int(has_diabetes),
            int(has_hypertension),
            int(iron_supplementation),
        ]
    ]

    print(user_data)

    pre_data = birth_weight_model.predict(user_data)[0]

    print(pre_data)

    return (
        jsonify({"message": "Prediction successfully!", "result": str(pre_data)}),
        200,
    )


@app.route("/voice", methods=["POST"])
def voice():
    if "audio" not in request.files:
        return jsonify({"error": "No sound part"}), 400

    sound = request.files["audio"]
    if sound.filename == "":
        return jsonify({"error": "No selected sound"}), 400

    sound_path = os.path.join(UPLOAD_FOLDER, sound.filename)

    try:
        sound.save(sound_path)
        sound_convert(sound_path)

        print(wav_to_text(sound_path.split(".")[0] + ".wav"))

        text = wav_to_text(sound_path.split(".")[0] + ".wav")
        
        if text.lower()=="hi":
            json_dump = json.dumps({"reply": str("hi"), "success": "true"})

            return json_dump
        elif text.lower()=="hello":
            json_dump = json.dumps({"reply": str("hi"), "success": "true"})

            return json_dump

        key_value = detect_txt_key(text)
        print(text)
        print(request.form.get("text"))
        if key_value != "no_keyword":

            results = nlp_model.predict([text])

            json_dump = json.dumps({"reply": str(results[0]), "success": "true"})

            return json_dump

        else:

            json_dump = json.dumps(
                {"reply": "this question something is wrong", "success": "true"}
            )

            return json_dump

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
@app.route('/image_upload', methods=['POST'])
def image_upload():
    method = request.form.get("method")
    if "photo" not in request.files:
        return jsonify({"error": "No photo part"}), 400

    photo = request.files["photo"]
    if photo.filename == "":
        return jsonify({"error": "No selected photo"}), 400

    photo_path = os.path.join(UPLOAD_FOLDER, photo.filename)

    photo.save(photo_path)
    
    if method == "cbc":
        
        f_txt,h=extract_form_values(photo_path)

        print(extract_haemoglobin(f_txt))
        
        json_dump = json.dumps({"haemoglobin": str(extract_haemoglobin(f_txt)), "success": "true"})

        return json_dump

    if method == "fasting_bs":
        
        f_txt,h=extract_form_values(photo_path)

        print(extract_postprandial_glucose(f_txt))
        
        json_dump = json.dumps({"postprandial_glucose": str(extract_postprandial_glucose(f_txt)), "success": "true"})

        return json_dump
    if method == "ogtt":
        
        f_txt,h=extract_form_values(photo_path)

        print(extract_glucose_values(f_txt))
        
        json_dump = json.dumps({"fasting": str(extract_glucose_values(f_txt)['fasting']),"1hr": str(extract_glucose_values(f_txt)['1hr']),"2hr": str(extract_glucose_values(f_txt)['2hr']), "success": "true"})

        return json_dump
        

@app.route("/images/<filename>")
def get_image(filename):
    return send_from_directory("temp", filename)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=1111)
