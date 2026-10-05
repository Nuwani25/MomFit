# MomFit — AI-Driven Maternal Wellness System

MomFit is a mobile application developed as our final-year group research project at SLIIT. It brings together personalized meal planning, pregnancy risk forecasting, a support chatbot and exercise recommendations. It aims to help pregnant mothers access information and guidance tailored to their profiles throughout pregnancy.

## Main Features

### 🔵Personalized Maternal Meal Planning
Generates meal suggestions based on trimester, BMI, dietary preferences, cultural preferences, allergies and health conditions. Supports meal selection and daily calorie tracking.

### 🔵Pregnancy Risk Forecasting
Uses maternal health information, ANC card data and OCR-extracted laboratory information to support predictions of gestational diabetes, anemia and low birth weight.

### 🔵Pregnancy Support Assist Chatbot
Provides pregnancy-related information through text and voice interactions.

### 🔵Health Risk Identification and Exercise Recommendation
Identifies maternal health risks and recommends exercises based on the mother's profile, trimester and risk level.

## Technologies Used

- Flutter and Dart — Mobile application
- Python and Flask — Backend API
- Firebase — Authentication and data storage
- Scikit-learn — Machine learning models
- Pandas and NumPy — Data preparation and processing
- Jupyter Notebook — Model development and experiments
- OCR and speech recognition — Supporting features

## My Contribution – Personalised Maternal Meal Planning

I developed the personalised maternal meal planning component to support meal selection based on a pregnant mother's nutritional needs and preferences.

### Features of My Component

- Personalised meal recommendations using maternal information such as age, BMI and trimester.
- Consideration of dietary preferences, ethnicity, allergies and selected health conditions.
- Meal suggestions organised into breakfast, lunch, dinner and snacks.
- Meal planning screens and calorie tracking within the mobile application.

### My Work

- Prepared and processed the meal planning dataset.
- Explored Decision Tree and Random Forest models for meal classification.
- Integrated the meal recommendation model with the Flask backend.
- Developed the Flutter screens for my component and connected them to the backend.
- Contributed to the research documentation and publication.

## Team Contributions

### Dinuwan Kumara
**Pregnancy Risk Forecasting**

- Developed the pregnancy risk forecasting component.
- Integrated maternal health information, ANC card data and OCR-extracted laboratory information.
- Implemented prediction workflows for gestational diabetes, anemia and low birth weight.

### Adithya Ranawaka
**Pregnancy Support Assist Chatbot**

- Developed the pregnancy support chatbot.
- Implemented text and voice interactions.
- Provided pregnancy-related information and assistance through the mobile application.

### Thamasha Pasidunee
**Health Risk Identification and Exercise Recommendation**

- Developed the health risk identification component.
- Implemented personalized exercise recommendations based on maternal profiles, trimester and identified risk levels.

## Project Structure

- `momfit/` — Flutter mobile application
- `python/` — Flask backend and trained models
- `ml parts/` — Component datasets and model training notebooks
- `ui/` — User interface design resources

## Research Publication

Our work on the maternal nutrition and exercise components contributed to the research paper:

**Personalized AI System for Maternal Nutrition and Exercise**

[View the research paper](https://doi.org/10.1109/ICAC69156.2025.11361494)

## Project Status

MomFit is an academic research prototype. Its recommendations have not been clinically validated.

