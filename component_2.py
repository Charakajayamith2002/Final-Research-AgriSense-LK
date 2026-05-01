"""
========================================================
COMPONENT 2: MARKET OPPORTUNITY RANKING
========================================================
Ranks agricultural markets by predicted price, road distance,
and transport cost. Supports both buyer (minimize cost) and
seller (maximize profit) roles.
"""

import os
import joblib
import numpy as np
import pandas as pd
import requests
import warnings
from datetime import datetime
from geopy.distance import geodesic

warnings.filterwarnings('ignore')


class MarketRankingPredictor:

    def __init__(self, model_dir='models/2/', markets_geo=None):
        self.model_dir   = model_dir
        self.markets_geo = markets_geo or {}

        self.model       = None
        self.features    = []
        self.encoders    = {}
        self.market_data = pd.DataFrame()

    # ------------------------------------------------------------------
    # LOAD
    # ------------------------------------------------------------------
    def load(self):
        """Load LightGBM model, encoders, features, and historical CSV."""
        try:
            self.model = joblib.load(
                os.path.join(self.model_dir, 'price_prediction_model_final.joblib')
            )
            self.features = joblib.load(
                os.path.join(self.model_dir, 'model_features.joblib')
            )
            self.encoders = joblib.load(
                os.path.join(self.model_dir, 'label_encoders.joblib')
            )

            raw = pd.read_csv(os.path.join(self.model_dir, 'data_with_predictions.csv'))
            raw['report_date'] = pd.to_datetime(raw['report_date'])
            self.market_data = (
                raw.sort_values('report_date')
                   .groupby(['item_standard', 'market', 'price_type'], as_index=False)
                   .last()
            )

            print("Component 2 (Market Ranking) loaded successfully")
            return True

        except Exception as e:
            print(f"Error loading Component 2: {e}")
            self.model       = None
            self.features    = []
            self.encoders    = {}
            self.market_data = pd.DataFrame()
            return False

    # ------------------------------------------------------------------
    # MAIN PREDICT (public entry point)
    # ------------------------------------------------------------------
    def predict(self, input_data):
        """Rank all markets for a given item, quantity, role, and location."""
        try:
            user_location          = (input_data['latitude'], input_data['longitude'])
            transport_cost_per_km  = float(input_data.get('transport_cost_per_km', 160))
            additional_transport   = float(input_data.get('additional_transport_cost', 0))
            user_role              = input_data.get('user_role', 'buyer')
            reference_price        = float(input_data.get('reference_price', 0)) or None

            quantity      = float(input_data.get('quantity', 1))
            quantity_unit = input_data.get('quantity_unit', 'kg')
            quantity_kg   = quantity / 1000.0 if quantity_unit == 'g' else quantity

            cultivation_cost = 0
            if user_role == 'seller':
                cultivation_cost = float(input_data.get('cultivation_cost', 0))
                if cultivation_cost <= 0:
                    base_price       = self._estimate_price(input_data['item'], 'Dambulla', input_data['price_type'], reference_price)
                    profitability    = float(input_data.get('profitability', 0.7))
                    cultivation_cost = base_price * (1 - profitability) if profitability > 0 else base_price * 0.3

            recommendations = []
            for market, coords in self.markets_geo.items():
                try:
                    distance            = self._road_distance_km(user_location, coords)
                    base_transport      = distance * transport_cost_per_km
                    transport_total     = base_transport + additional_transport
                    price_per_kg        = self._estimate_price(input_data['item'], market, input_data['price_type'], reference_price)
                    anomaly             = self._get_anomaly_score(input_data['item'], market, input_data['price_type'])
                    total_price         = price_per_kg * quantity_kg
                    total_cost          = total_price + transport_total

                    recommendations.append({
                        'market':                  market,
                        'predicted_price':         round(price_per_kg, 2),
                        'distance_km':             round(distance, 2),
                        'distance':                round(distance, 2),
                        'base_transport_cost':     round(base_transport, 2),
                        'additional_transport_cost': round(additional_transport, 2),
                        'transport_cost':          round(transport_total, 2),
                        'total_price':             round(total_price, 2),
                        'total_cost':              round(total_cost, 2),
                        'cultivation_cost':        round(cultivation_cost, 2),
                        'anomaly_score':           round(anomaly, 2),
                    })
                except Exception as e:
                    print(f"Skipping market {market}: {e}")
                    continue

            if user_role == 'buyer':
                reference_cost = max(r['total_cost'] for r in recommendations) if recommendations else 0
                for rec in recommendations:
                    rec['net_advantage'] = round(reference_cost - rec['total_cost'], 2)
                    rec['explanation']   = self._explain_buyer(
                        rec['predicted_price'], quantity_kg, rec['transport_cost'],
                        rec['distance'], rec['net_advantage'],
                        rec['base_transport_cost'], rec['additional_transport_cost']
                    )
                recommendations.sort(key=lambda x: x['net_advantage'], reverse=True)
            else:
                for rec in recommendations:
                    profit             = rec['total_price'] - (rec['cultivation_cost'] + rec['transport_cost'])
                    rec['net_advantage'] = round(profit, 2)
                    rec['explanation']   = self._explain_seller(
                        rec['predicted_price'], quantity_kg, rec['cultivation_cost'],
                        rec['transport_cost'], rec['distance'], rec['net_advantage'],
                        rec['base_transport_cost'], rec['additional_transport_cost']
                    )
                recommendations.sort(key=lambda x: x['net_advantage'], reverse=True)

            for i, rec in enumerate(recommendations, 1):
                rec['rank'] = i

            return {
                'recommendations': recommendations,
                'total_markets':   len(recommendations),
                'best_market':     recommendations[0]['market'] if recommendations else None,
                'quantity_kg':     quantity_kg,
                'user_role':       user_role,
            }

        except Exception as e:
            raise Exception(f"Component 2 prediction error: {e}")

    # ------------------------------------------------------------------
    # PRICE ESTIMATION
    # ------------------------------------------------------------------
    def _estimate_price(self, item, market, price_type, reference_price=None):
        """Live LightGBM prediction, with CSV pre-computed price as fallback."""
        if self.market_data is None or self.market_data.empty:
            raise Exception("Component 2 market data not loaded")

        live = self._predict_price_live(item, market, price_type)
        if live is not None:
            return live

        mask = (
            (self.market_data['item_standard'].str.lower() == item.lower()) &
            (self.market_data['market'] == market) &
            (self.market_data['price_type'] == price_type)
        )
        row = self.market_data[mask]
        if row.empty:
            mask = (
                self.market_data['item_standard'].str.contains(item, case=False, na=False) &
                (self.market_data['market'] == market) &
                (self.market_data['price_type'] == price_type)
            )
            row = self.market_data[mask]

        if row.empty:
            raise Exception(f"No prediction data for '{item}' at {market} ({price_type})")

        return float(row.iloc[0]['predicted_price'])

    def _predict_price_live(self, item, market, price_type):
        """Run LightGBM with today's date + latest historical lag features."""
        if self.model is None or not self.encoders or self.market_data.empty:
            return None

        mask = (
            (self.market_data['item_standard'].str.lower() == item.lower()) &
            (self.market_data['market'] == market) &
            (self.market_data['price_type'] == price_type)
        )
        row = self.market_data[mask]
        if row.empty:
            mask = (
                self.market_data['item_standard'].str.contains(item, case=False, na=False) &
                (self.market_data['market'] == market) &
                (self.market_data['price_type'] == price_type)
            )
            row = self.market_data[mask]
        if row.empty:
            return None

        latest = row.iloc[0]
        today  = datetime.now()

        try:
            feature_row = {
                'month':                 today.month,
                'day_of_week':           today.weekday(),
                'week_of_year':          int(today.strftime('%W')),
                'category_encoded':      int(self.encoders['category'].transform([latest['category']])[0]),
                'item_standard_encoded': int(self.encoders['item_standard'].transform([latest['item_standard']])[0]),
                'origin_type_encoded':   int(self.encoders['origin_type'].transform([latest['origin_type']])[0]),
                'price_type_encoded':    int(self.encoders['price_type'].transform([price_type])[0]),
                'market_encoded':        int(self.encoders['market'].transform([market])[0]),
                'price_prev':            float(latest['price_prev']),
                'anomaly_score':         float(latest['anomaly_score']),
                'price_volatility':      float(latest['price_volatility']),
                'price_change_pct':      float(latest['price_change_pct']),
                'price_lag_1':           float(latest['price_lag_1']),
                'price_lag_7':           float(latest['price_lag_7']),
                'price_rolling_mean_7':  float(latest['price_rolling_mean_7']),
            }
            X = pd.DataFrame([feature_row], columns=self.features)
            return round(float(self.model.predict(X)[0]), 2)

        except Exception as e:
            print(f"Live prediction failed for {item}/{market}/{price_type}: {e}")
            return None

    def _get_anomaly_score(self, item, market, price_type):
        """Return Isolation Forest anomaly score from CSV (0.0 if not found)."""
        if self.market_data is None or self.market_data.empty:
            return 0.0
        mask = (
            (self.market_data['item_standard'].str.lower() == item.lower()) &
            (self.market_data['market'] == market) &
            (self.market_data['price_type'] == price_type)
        )
        row = self.market_data[mask]
        return float(row.iloc[0]['anomaly_score']) if not row.empty else 0.0

    # ------------------------------------------------------------------
    # DISTANCE
    # ------------------------------------------------------------------
    def _road_distance_km(self, origin, destination):
        """OSRM road distance in km. Falls back to geodesic × 1.4."""
        try:
            lat1, lon1 = origin
            lat2, lon2 = destination
            url  = (
                f"http://router.project-osrm.org/route/v1/driving/"
                f"{lon1},{lat1};{lon2},{lat2}?overview=false"
            )
            resp = requests.get(url, timeout=5)
            data = resp.json()
            if data.get('code') == 'Ok':
                return data['routes'][0]['distance'] / 1000.0
        except Exception:
            pass
        return geodesic(origin, destination).km * 1.4

    # ------------------------------------------------------------------
    # EXPLANATION GENERATORS
    # ------------------------------------------------------------------
    def _explain_buyer(self, price_per_kg, quantity_kg, transport_cost, distance,
                       net_advantage, base_transport=0, additional_transport=0):
        total_price = price_per_kg * quantity_kg
        txt = (
            f"Buying {quantity_kg:.2f} kg: Total cost Rs.{total_price:.2f} "
            f"(Price: Rs.{price_per_kg:.2f}/kg × {quantity_kg:.2f} kg) "
            f"+ Transport: Rs.{transport_cost:.2f}"
        )
        if additional_transport > 0:
            txt += f" [Distance: Rs.{base_transport:.2f} + Additional: Rs.{additional_transport:.2f}]"
        txt += f" (Distance: {distance:.1f} km)"
        return txt

    def _explain_seller(self, price_per_kg, quantity_kg, cultivation_cost, transport_cost,
                        distance, net_advantage, base_transport=0, additional_transport=0):
        total_price = price_per_kg * quantity_kg
        total_cost  = cultivation_cost + transport_cost
        txt = (
            f"Selling {quantity_kg:.2f} kg: Revenue Rs.{total_price:.2f} "
            f"(Price: Rs.{price_per_kg:.2f}/kg × {quantity_kg:.2f} kg) "
            f"- Costs: Rs.{total_cost:.2f} "
            f"(Cultivation: Rs.{cultivation_cost:.2f} + Transport: Rs.{transport_cost:.2f})"
        )
        if additional_transport > 0:
            txt += f" [Transport split: Distance Rs.{base_transport:.2f} + Additional Rs.{additional_transport:.2f}]"
        txt += f" (Distance: {distance:.1f} km)"
        return txt
