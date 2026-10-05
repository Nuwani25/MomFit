# MomFit — AI-Driven Maternal Wellness System

MomFit is a pregnancy support mobile application developed as a final-year group research project at SLIIT in 2025.

The application brings together personalized meal planning, pregnancy risk forecasting, a support chatbot and exercise recommendations. It aims to help pregnant mothers access information and guidance tailored to their profiles throughout pregnancy.

## Main Features

### Personalized Maternal Meal Planning
Generates meal suggestions based on trimester, BMI, dietary preferences, cultural preferences, allergies and health conditions. Supports meal selection and daily calorie tracking.

### Pregnancy Risk Forecasting
Uses maternal health information, ANC card data and OCR-extracted laboratory information to support predictions of gestational diabetes, anemia and low birth weight.

### Pregnancy Support Assist Chatbot
Provides pregnancy-related information through text and voice interactions.

### Health Risk Identification and Exercise Recommendation
Identifies maternal health risks and recommends exercises based on the mother's profile, trimester and risk level.

## Technologies Used

- Flutter and Dart — Mobile application
- Python and Flask — Backend API
- Firebase — Authentication and data storage
- Scikit-learn — Machine learning models
- Pandas and NumPy — Data preparation and processing
- Jupyter Notebook — Model development and experiments
- OCR and speech recognition — Supporting features

## Team Contributions

### Nuwani Dahanayake
**Personalized Maternal Meal Planning**

- Developed the personalized nutrition and meal planning component.
- Prepared the meal dataset and experimented with Decision Tree and Random Forest models.
- Used maternal profiles, dietary preferences, cultural preferences, allergies and health conditions to personalize meal suggestions.
- Connected the meal recommendation API to the Flutter interface.
- Implemented meal selection and daily calorie tracking.

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

The maternal nutrition and exercise components were included in the research paper:

**Personalized AI System for Maternal Nutrition and Exercise**

[View the research paper](https://doi.org/10.1109/ICAC69156.2025.11361494)

The publication covers these two selected components of the wider MomFit project.

## Project Status

MomFit is an academic research prototype. Its predictions and recommendations are intended for research demonstration and have not been established as a clinically validated service.