# Scalping Robot with Machine Learning Signal Filter

This project integrates a scalping trading bot with an ML-based signal filter to improve trade accuracy.

## Features

- The bot places trades based on high and low levels and trailing stop-loss logic.
- A Python ML model classifies signals as high-probability or not based on market data.

## Requirements

- MetaTrader 5 platform installed
- Python 3.8+
- Required Python libraries: `pandas`, `sklearn`, `joblib`, `MetaTrader5`

## Setup

1. **Train the ML Model**
   - Prepare your historical market data in `market_data.csv`.
   - Run the `ml_signal_filter.py` script to train and save the model:
     ```bash
     python ml_signal_filter.py
     ```

2. **Run the Trading Bot**
   - Place the `scalping_robot.mq5` file in the `Experts` folder of your MetaTrader 5 platform.
   - Add the compiled `.ex5` file to the chart.

3. **Integrate ML with MT5**
   - Use the `MetaTrader5` Python API to fetch live market data:
     ```python
     import MetaTrader5 as mt5

     mt5.initialize()
     rates = mt5.copy_rates_from_pos("EURUSD", mt5.TIMEFRAME_M1, 0, 100)
     # Use these rates to generate features and predict with your model
     ```

   - Predict signals using the saved model:
     ```python
     from joblib import load

     model = load("scalping_signal_classifier.pkl")
     prediction = model.predict([[price_change, high_low_diff, rsi]])  # Replace with actual features
     if prediction[0] == 1:
         print("High-probability signal. Proceed with trading.")
     else:
         print("Signal filtered out.")
     ```

4. **Monitor Trades**
   - Check the trading bot's performance in MetaTrader 5 and optimize settings based on results.

---

Feel free to tweak the ML model and trading parameters to better suit your trading strategy! 🚀
