import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
import joblib

# Load your historical market data
data = pd.read_csv("market_data.csv")  # Ensure this file contains the necessary features

# Feature engineering
# Add relevant features such as RSI, Moving Averages, High/Low levels, etc.
data["Price_Change"] = data["Close"] - data["Open"]
data["High_Low_Diff"] = data["High"] - data["Low"]
data["RSI"] = ...  # Compute RSI (use a library or your own function)

# Target: 1 for profitable signals, 0 for non-profitable signals
data["Target"] = (data["Profit"] > 0).astype(int)

# Prepare data for ML
features = ["Price_Change", "High_Low_Diff", "RSI"]
X = data[features]
y = data["Target"]

# Split the data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Train a Random Forest Classifier
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

# Save the trained model
joblib.dump(model, "scalping_signal_classifier.pkl")

print("Model trained and saved successfully!")
