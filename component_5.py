"""
========================================================
COMPONENT 5: BUSINESS IDEA PREDICTION MODEL
========================================================
This component loads the trained business idea prediction model
and provides prediction functionality for the web interface.
"""

import os
import sys
import json
import joblib
import numpy as np
import pandas as pd
from pathlib import Path
from datetime import datetime
import warnings
import random

warnings.filterwarnings('ignore')

# Add parent directory to path to allow imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


class BusinessIdeaPredictor:
    """
    Business Idea Prediction Model Component

    This class loads the trained model and provides methods for
    predicting business types based on user inputs.
    """

    def __init__(self, models_dir='models/5'):
        """
        Initialize the predictor with trained model and components

        Args:
            models_dir: Path to directory containing model files
        """
        self.models_dir = Path(models_dir)
        self.model = None
        self.scaler = None
        self.label_encoders = None
        self.target_encoder = None
        self.features = {}
        self.metadata = {}
        self.classes_ = None
        self.numerical_features = []
        self.categorical_features = []
        self.all_features = []
        self.engineered_features = []
        self.expected_feature_count = 0
        self.feature_names = []

        # Load business configuration from external config file
        _bus_cfg = self._load_business_config()
        self.business_mapping      = {int(k): v for k, v in _bus_cfg['business_mapping'].items()}
        self.business_names        = _bus_cfg['business_names']
        self.business_descriptions = _bus_cfg['business_descriptions']
        self.business_risk         = _bus_cfg['business_risk']
        self.capital_required      = _bus_cfg['capital_required']
        self.key_considerations    = _bus_cfg['key_considerations']
        self.potential_challenges  = _bus_cfg['potential_challenges']
        self.purpose_mapping       = _bus_cfg['purpose_mapping']

        # Load components
        self.load_components()

    def _load_business_config(self, path='config/business_config.json'):
        with open(path, 'r') as f:
            return json.load(f)

    def load_components(self):
        """Load all model components from the models directory with version handling"""
        print(f"📊 Loading Business Idea Prediction model from {self.models_dir}...")

        # Check if directory exists
        if not self.models_dir.exists():
            raise FileNotFoundError(f"Models directory not found: {self.models_dir}")

        # Try to load model with compatibility handling
        model_path = self.models_dir / 'model.pkl'
        if model_path.exists():
            self.model = self._load_model_compatible(model_path)
            print(f"  ✓ Model loaded: {type(self.model).__name__ if self.model else 'Unknown'}")

        # Get expected feature count from model
        if hasattr(self.model, 'n_features_in_'):
            self.expected_feature_count = self.model.n_features_in_
            print(f"  ✓ Model expects {self.expected_feature_count} features")

        # Get feature names from model
        if hasattr(self.model, 'feature_names_in_'):
            self.feature_names = list(self.model.feature_names_in_)
            print(f"  ✓ Model has {len(self.feature_names)} named features")

        # Load scaler
        scaler_path = self.models_dir / 'scaler.pkl'
        if scaler_path.exists():
            self.scaler = joblib.load(scaler_path)
            print("  ✓ Scaler loaded")
            if hasattr(self.scaler, 'n_features_in_'):
                print(f"  ✓ Scaler expects {self.scaler.n_features_in_} features")

        # Load label encoders
        encoders_path = self.models_dir / 'label_encoders.pkl'
        if encoders_path.exists():
            self.label_encoders = joblib.load(encoders_path)
            print(f"  ✓ Label encoders loaded: {len(self.label_encoders) if self.label_encoders else 0} encoders")

        # Load target encoder
        target_encoder_path = self.models_dir / 'target_encoder.pkl'
        if target_encoder_path.exists():
            self.target_encoder = joblib.load(target_encoder_path)
            print("  ✓ Target encoder loaded")
            if hasattr(self.target_encoder, 'classes_'):
                self.classes_ = self.target_encoder.classes_
                print(f"  ✓ Found {len(self.classes_)} classes in target encoder")

        # Try multiple possible feature file names
        feature_files = ['features.json', 'feature_list.json', 'feature_names.json']
        for feat_file in feature_files:
            features_path = self.models_dir / feat_file
            if features_path.exists():
                with open(features_path, 'r') as f:
                    self.features = json.load(f)

                if isinstance(self.features, dict):
                    self.numerical_features = self.features.get('numerical_features', [])
                    self.categorical_features = self.features.get('categorical_features', [])
                    self.all_features = self.features.get('all_features', [])
                elif isinstance(self.features, list):
                    self.all_features = self.features

                print(f"  ✓ Features loaded from {feat_file}: {len(self.all_features)} total")
                print(f"    • Numerical: {len(self.numerical_features)}")
                print(f"    • Categorical: {len(self.categorical_features)}")
                break

        # Load metadata
        metadata_path = self.models_dir / 'metadata.json'
        if metadata_path.exists():
            with open(metadata_path, 'r') as f:
                self.metadata = json.load(f)
            print("  ✓ Metadata loaded")

            model_name = self.metadata.get('model_name', 'Unknown')
            accuracy = self.metadata.get('accuracy', 0)
            print(f"\n📊 Model Information:")
            print(f"  • Model: {model_name}")
            print(f"  • Accuracy: {accuracy:.2%}")

        if self.model:
            print("✅ Business Idea Predictor initialized successfully")
        else:
            print("⚠️ Using rule-based fallback predictor")

    def _load_model_compatible(self, model_path):
        """Load model with compatibility handling"""
        try:
            return joblib.load(model_path)
        except Exception as e1:
            print(f"  ⚠️ Standard loading failed: {e1}")
            try:
                import pickle
                with open(model_path, 'rb') as f:
                    return pickle.load(f)
            except Exception as e2:
                print(f"  ⚠️ Pickle loading failed: {e2}")
                return None

    # ── lookup tables ─────────────────────────────────────────────────────────
    _REGION_COORDS = {
        'Western Province':       (6.9271, 79.8612),
        'Central Province':       (7.2906, 80.6337),
        'Southern Province':      (5.9549, 80.5550),
        'Northern Province':      (9.6615, 80.0255),
        'Eastern Province':       (7.8731, 81.3152),
        'North Western Province': (7.4818, 80.3609),
        'North Central Province': (8.3114, 80.4037),
        'Uva Province':           (6.9934, 81.0550),
        'Sabaragamuwa Province':  (6.6828, 80.3992),
    }
    _CROP_PRICE = {
        'Vegetables': 80, 'Fruits': 120, 'Grains': 55, 'Spices': 450, 'Mixed': 95,
    }
    _CROP_BASE = {   # (profitability, risk)
        'Vegetables': (0.75, 0.45), 'Fruits':  (0.80, 0.35),
        'Grains':     (0.65, 0.30), 'Spices':  (0.85, 0.40),
        'Mixed':      (0.72, 0.38),
    }
    _EXP_FACTOR = {  # (prof_mult, risk_mult)
        'beginner':     (0.85, 1.20),
        'intermediate': (1.00, 1.00),
        'expert':       (1.15, 0.80),
    }
    _MARKET_DISTANCE = {'local': 15, 'regional': 60, 'national': 150, 'export': 350}
    _FARM_INCOME_RATIO = {'small': 0.25, 'medium': 0.40, 'large': 0.60}

    def _create_feature_vector(self, user_data):
        """Map Flutter form fields → 30 raw features the model was trained on."""
        # ── Flutter form inputs ───────────────────────────────────────────────
        crop_type  = user_data.get('crop_type', 'Vegetables')
        farm_size  = user_data.get('farm_size', 'small')
        region     = user_data.get('region', 'Western Province')
        experience = user_data.get('experience_level', 'beginner')
        market_acc = user_data.get('market_access', 'local')
        budget     = float(user_data.get('budget', user_data.get('available_budget', 50000)))
        land_area  = float(user_data.get('land_area', 1.0))

        # ── location ──────────────────────────────────────────────────────────
        lat, lon = self._REGION_COORDS.get(region, (7.0, 80.5))

        # ── cultivation ───────────────────────────────────────────────────────
        predicted_price = float(self._CROP_PRICE.get(crop_type, 95))
        base_prof, base_risk = self._CROP_BASE.get(crop_type, (0.72, 0.40))
        pm, rm = self._EXP_FACTOR.get(experience, (1.0, 1.0))
        cultivation_profitability = min(0.98, base_prof * pm)
        cultivation_risk          = min(0.98, base_risk * rm)

        # ── market / distance ─────────────────────────────────────────────────
        distance_km    = float(self._MARKET_DISTANCE.get(market_acc, 15))
        transport_cost = distance_km * 55.0   # ~55 LKR/km

        # ── income / family ───────────────────────────────────────────────────
        income_ratio   = self._FARM_INCOME_RATIO.get(farm_size, 0.25)
        monthly_income = max(budget * income_ratio, 15000.0)
        family_members    = 4.0
        children_under_16 = 2.0
        adult_members     = family_members - children_under_16

        # ── loan (not in form → zeros) ────────────────────────────────────────
        loan_amount        = 0.0
        loan_rate          = 0.0
        loan_period_months = 0.0
        has_loan_data      = 0.0

        # ── derived financial features ────────────────────────────────────────
        land_area_kg            = land_area * 400.0
        gross_revenue           = predicted_price * land_area_kg
        input_cost              = budget * 0.40
        net_advantage           = gross_revenue - transport_cost - input_cost
        expected_monthly_profit = gross_revenue * cultivation_profitability - (transport_cost / 12.0)
        break_even_months       = float(max(1, round(budget / max(expected_monthly_profit, 1))))
        success                 = 1.0 if cultivation_profitability > 0.70 else 0.0
        feasibility_score       = cultivation_profitability * (budget / 200000.0) - cultivation_risk

        budget_to_income_ratio = budget / max(monthly_income, 1)
        loan_to_budget_ratio   = 0.0
        dependency_ratio       = children_under_16 / max(family_members, 1)
        cost_per_km            = transport_cost / max(distance_km, 1)
        price_distance_ratio   = predicted_price / max(distance_km, 1)
        advantage_per_kg       = net_advantage / max(predicted_price * land_area_kg, 1)
        market_attractiveness  = predicted_price / max(distance_km, 1) * 10.0
        financial_health       = (budget - loan_amount) / max(monthly_income, 1)
        optimal_month          = float(datetime.now().month)

        return {
            # ── 30 model features (same names/order as feature_names.json) ────
            'monthly_income':            monthly_income,
            'family_members':            family_members,
            'children_under_16':         children_under_16,
            'available_budget':          budget,
            'loan_amount':               loan_amount,
            'loan_rate':                 loan_rate,
            'loan_period_months':        loan_period_months,
            'location_lat':              lat,
            'location_lon':              lon,
            'cultivation_profitability': cultivation_profitability,
            'cultivation_risk':          cultivation_risk,
            'optimal_month':             optimal_month,
            'predicted_price':           predicted_price,
            'distance_km':               distance_km,
            'net_advantage':             net_advantage,
            'feasibility_score':         feasibility_score,
            'expected_monthly_profit':   expected_monthly_profit,
            'break_even_months':         break_even_months,
            'success':                   success,
            'has_loan_data':             has_loan_data,
            'budget_to_income_ratio':    budget_to_income_ratio,
            'loan_to_budget_ratio':      loan_to_budget_ratio,
            'adult_members':             adult_members,
            'dependency_ratio':          dependency_ratio,
            'cost_per_km':               cost_per_km,
            'price_distance_ratio':      price_distance_ratio,
            'advantage_per_kg':          advantage_per_kg,
            'market_attractiveness':     market_attractiveness,
            'financial_health':          financial_health,
            'role':                      'farmer',
            # ── extras for rule-based fallback ────────────────────────────────
            'purpose':          'cultivate_sell',
            'crop_type':        crop_type,
            'experience_level': experience,
            'market_access':    market_acc,
        }

    def _broad_class_to_specific_code(self, broad_class, features):
        """Map a broad class (FARMING/RETAIL_WHOLESALE/CONSUMER) to a specific BUS_Xxx code."""
        budget     = features.get('available_budget', 50000)
        experience = features.get('experience_level', 'beginner')
        market_acc = features.get('market_access', 'local')
        crop_type  = features.get('crop_type', 'Vegetables')

        if broad_class == 'FARMING':
            if experience == 'expert':
                if market_acc in ('national', 'export') and crop_type in ('Spices', 'Fruits'):
                    return 'BUS_F03'   # Value-Added Farm Products
                if budget >= 500000:
                    return 'BUS_F01'   # Commercial Crop Farming
                return 'BUS_F04'       # Contract Farming
            elif experience == 'intermediate':
                if market_acc in ('national', 'export'):
                    return 'BUS_F04'   # Contract Farming
                return 'BUS_F01'       # Commercial Crop Farming
            else:                       # beginner
                return 'BUS_F02'       # Organic Farming (lower risk entry)

        elif broad_class == 'RETAIL_WHOLESALE':
            if budget >= 1_000_000 and market_acc == 'export':
                return 'BUS_B02'       # Value-Added Products for Export
            if budget >= 500_000:
                return 'BUS_B03'       # Food Processing Business
            if budget >= 150_000:
                return 'BUS_B01'       # Retail Fruit & Vegetable Shop
            if budget >= 80_000:
                return 'BUS_S01'       # Wholesale Produce Trader
            return 'BUS_S02'           # Agricultural Collector

        else:  # CONSUMER
            if budget >= 50_000:
                return 'BUS_C02'       # Community Buying Group
            return 'BUS_C01'           # Monthly Budget Optimization

    def _rule_based_prediction(self, features):
        """Generate prediction based on rules when model is not available"""
        role = features['role']
        purpose = features.get('purpose', '')
        budget = features['available_budget']
        income = features['monthly_income']
        net_advantage = features['net_advantage']

        # Default to farmer if unknown
        if role == 'farmer':
            if budget > 500000:
                return 'BUS_F01', 0.85  # Commercial Farming
            elif purpose in ['food_business', 'value_added_export']:
                return 'BUS_F03', 0.80  # Value-Added Products
            elif net_advantage > 10000:
                return 'BUS_F04', 0.75  # Contract Farming
            else:
                return 'BUS_F02', 0.70  # Organic Farming

        elif role == 'buyer':
            if budget > 1000000:
                return 'BUS_B02', 0.85  # Export
            elif budget > 500000:
                return 'BUS_B03', 0.80  # Food Processing
            elif purpose in ['retail_main', 'retail_other']:
                return 'BUS_B01', 0.75  # Retail Shop
            else:
                return 'BUS_S01', 0.70  # Wholesale Trader

        elif role == 'seller':
            if budget > 500000:
                return 'BUS_S01', 0.85  # Wholesale Trader
            elif purpose == 'collector':
                return 'BUS_S02', 0.80  # Agricultural Collector
            else:
                return 'BUS_S03', 0.75  # Commission Agent

        elif role == 'consumer':
            if budget > 50000:
                return 'BUS_C02', 0.80  # Community Buying Group
            else:
                return 'BUS_C01', 0.85  # Budget Planning

        return 'BUS_F02', 0.75  # Default

    def _get_alternative_predictions(self, features, main_prediction):
        """Generate alternative business options"""
        role = features['role']
        alternatives = []

        # Get possible alternatives based on role and purpose
        purpose = features.get('purpose', '')
        possible_codes = self.purpose_mapping.get(role, {}).get(purpose, [])

        # Add some default alternatives if none found
        if not possible_codes:
            if role == 'farmer':
                possible_codes = ['BUS_F02', 'BUS_F03', 'BUS_F04']
            elif role == 'buyer':
                possible_codes = ['BUS_B01', 'BUS_S01', 'BUS_B03']
            elif role == 'seller':
                possible_codes = ['BUS_S02', 'BUS_S03', 'BUS_S01']
            else:
                possible_codes = ['BUS_C01', 'BUS_C02']

        # Remove the main prediction from alternatives
        possible_codes = [code for code in possible_codes if code != main_prediction]

        # Create alternative predictions with decreasing confidence
        for i, code in enumerate(possible_codes[:3]):  # Top 3 alternatives
            confidence = max(0.3, 0.6 - (i * 0.15))
            alternatives.append({
                'business_code': code,
                'business_name': self.business_names.get(code, code),
                'confidence': confidence,
                'risk_level': self.business_risk.get(code, 'Medium')
            })

        return alternatives

    def predict(self, user_data):
        """
        Predict business type for a user

        Args:
            user_data: Dictionary with user information

        Returns:
            Dictionary with prediction results and recommendations
        """
        try:
            # Extract features
            features = self._create_feature_vector(user_data)

            # ── Build feature DataFrame in exact model order ──────────────────
            feature_order = [
                'monthly_income', 'family_members', 'children_under_16',
                'available_budget', 'loan_amount', 'loan_rate',
                'loan_period_months', 'location_lat', 'location_lon',
                'cultivation_profitability', 'cultivation_risk', 'optimal_month',
                'predicted_price', 'distance_km', 'net_advantage',
                'feasibility_score', 'expected_monthly_profit', 'break_even_months',
                'success', 'has_loan_data', 'budget_to_income_ratio',
                'loan_to_budget_ratio', 'adult_members', 'dependency_ratio',
                'cost_per_km', 'price_distance_ratio', 'advantage_per_kg',
                'market_attractiveness', 'financial_health', 'role',
            ]

            # ── Generate prediction ───────────────────────────────────────────
            if self.model is not None and self.scaler is not None:
                try:
                    # 1. Encode categorical 'role'
                    role_val = features['role']
                    if self.label_encoders and 'role' in self.label_encoders:
                        role_encoded = int(self.label_encoders['role'].transform([role_val])[0])
                    else:
                        role_encoded = 2  # 'farmer' alphabetical fallback

                    # 2. Build raw feature row
                    row = {k: features[k] for k in feature_order}
                    row['role'] = float(role_encoded)

                    X_raw = pd.DataFrame([row], columns=feature_order)

                    # 3. Scale
                    X_scaled = self.scaler.transform(X_raw)

                    # 4. Predict broad class + probabilities
                    broad_idx   = self.model.predict(X_scaled)[0]
                    proba       = self.model.predict_proba(X_scaled)[0]
                    confidence  = float(np.max(proba))

                    if self.target_encoder is not None:
                        broad_class = self.target_encoder.inverse_transform([broad_idx])[0]
                    elif hasattr(self.model, 'classes_'):
                        broad_class = self.model.classes_[broad_idx]
                    else:
                        broad_class = 'FARMING'

                    # 5. Map broad class → specific business code
                    business_code = self._broad_class_to_specific_code(broad_class, features)

                    print(f"  ✓ RF predicted broad class: {broad_class} (conf={confidence:.2%})")
                    print(f"  ✓ Specific code: {business_code}")

                except Exception as e:
                    print(f"Model prediction error, using fallback: {e}")
                    import traceback; traceback.print_exc()
                    business_code, confidence = self._rule_based_prediction(features)
            else:
                business_code, confidence = self._rule_based_prediction(features)

            # Get alternatives
            alternatives = self._get_alternative_predictions(features, business_code)

            # Prepare top predictions list
            top_predictions = [{
                'business_code': business_code,
                'business_name': self.business_names.get(business_code, business_code),
                'confidence': confidence,
                'risk_level': self.business_risk.get(business_code, 'Medium'),
                'capital_required': self.capital_required.get(business_code, 'Varies'),
                'description': self.business_descriptions.get(business_code, '')
            }]
            top_predictions.extend(alternatives)

            # Determine confidence level
            if confidence > 0.8:
                confidence_level = "High"
                confidence_color = "success"
            elif confidence > 0.6:
                confidence_level = "Medium"
                confidence_color = "warning"
            else:
                confidence_level = "Low"
                confidence_color = "danger"

            # Prepare result
            result = {
                'success': True,
                'predicted_business_code': business_code,
                'predicted_business_name': self.business_names.get(business_code, business_code),
                'confidence': confidence,
                'confidence_level': confidence_level,
                'confidence_color': confidence_color,
                'description': self.business_descriptions.get(business_code, ''),
                'risk_level': self.business_risk.get(business_code, 'Medium'),
                'capital_required': self.capital_required.get(business_code, 'Varies'),
                'key_considerations': self.key_considerations.get(business_code,
                    ['Conduct market research', 'Start small and scale', 'Seek expert advice']),
                'potential_challenges': self.potential_challenges.get(business_code,
                    ['Market uncertainty', 'Financial management', 'Skill development']),
                'top_predictions': top_predictions,
                'all_classes': list(self.business_names.keys())
            }

            return result

        except Exception as e:
            import traceback
            traceback.print_exc()
            return {
                'success': False,
                'error': str(e)
            }

    def get_model_info(self):
        """Get model information"""
        return {
            'model_type': type(self.model).__name__ if self.model else 'Rule-based',
            'num_features': len(self.all_features) if self.all_features else 30,
            'num_classes': len(self.classes_) if self.classes_ is not None else 12,
            'business_names': self.business_names,
            'has_probabilities': hasattr(self.model, 'predict_proba') if self.model else False,
            'metadata': self.metadata
        }


# Flask integration function
def create_app():
    """Create Flask app with prediction endpoints"""
    from flask import Flask, request, jsonify, render_template
    app = Flask(__name__)

    try:
        predictor = BusinessIdeaPredictor('models/5')
        print("✅ Predictor initialized successfully")
    except Exception as e:
        print(f"❌ Failed to initialize predictor: {e}")
        predictor = None

    @app.route('/')
    def index():
        return render_template('profitable_strategy.html')

    @app.route('/api/predict', methods=['POST'])
    def predict():
        if predictor is None:
            return jsonify({'success': False, 'error': 'Model not loaded'}), 500
        try:
            data = request.get_json()
            result = predictor.predict(data)
            return jsonify(result)
        except Exception as e:
            return jsonify({'success': False, 'error': str(e)}), 400

    @app.route('/api/model_info', methods=['GET'])
    def model_info():
        if predictor is None:
            return jsonify({'success': False, 'error': 'Model not loaded'}), 500
        return jsonify(predictor.get_model_info())

    return app


# Command line interface
if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Business Idea Prediction Model')
    parser.add_argument('--mode', choices=['cli', 'server'], default='cli',
                        help='Run mode: cli for command line, server for Flask server')
    parser.add_argument('--port', type=int, default=5000, help='Port for server mode')
    parser.add_argument('--model-dir', type=str, default='models/5',
                        help='Directory containing model files')

    args = parser.parse_args()

    try:
        predictor = BusinessIdeaPredictor(args.model_dir)
    except Exception as e:
        print(f"❌ Failed to initialize predictor: {e}")
        sys.exit(1)

    if args.mode == 'cli':
        print("\n" + "=" * 60)
        print("BUSINESS IDEA PREDICTION - CLI TEST")
        print("=" * 60)

        # Test with different scenarios
        test_users = [
            {
                'role': 'farmer',
                'purpose': 'cultivate_sell',
                'profession': 'farming',
                'monthly_income': 85000,
                'income_source': 'both',
                'marital_status': 'married',
                'family_members': 4,
                'children_under_16': 2,
                'available_budget': 250000,
                'budget_source': 'saving',
                'market_name': 'Dambulla',
                'predicted_price': 185.50,
                'distance_km': 45.2,
                'transport_cost': 7200,
                'net_advantage': 12800,
                'cultivation_item': 'Tomato',
                'cultivation_profitability': 0.85,
                'cultivation_risk': 0.40,
                'optimal_month': 3,
                'season': 'Spring',
                'latitude': 7.2906,
                'longitude': 80.6337
            },
            {
                'role': 'buyer',
                'purpose': 'retail_main',
                'profession': 'business',
                'monthly_income': 150000,
                'available_budget': 600000,
                'market_name': 'Pettah',
                'predicted_price': 192.50,
                'distance_km': 15.2,
                'transport_cost': 2432,
                'net_advantage': -19250
            },
            {
                'role': 'seller',
                'purpose': 'collector',
                'profession': 'business',
                'monthly_income': 75000,
                'available_budget': 150000,
                'market_name': 'Dambulla',
                'predicted_price': 175.50,
                'distance_km': 45.2,
                'transport_cost': 7232,
                'net_advantage': -7232
            },
            {
                'role': 'consumer',
                'purpose': 'budget_planning',
                'profession': 'private',
                'monthly_income': 65000,
                'available_budget': 25000,
                'market_name': 'Narahenpita',
                'predicted_price': 195.50,
                'distance_km': 8.5,
                'transport_cost': 1360,
                'net_advantage': -19550
            }
        ]

        for i, test_user in enumerate(test_users[:1]):  # Test first user
            print(f"\n{'='*50}")
            print(f"Test {i+1}: {test_user['role'].title()}")
            print(f"{'='*50}")

            result = predictor.predict(test_user)

            if result.get('success', False):
                print(f"\n✅ Prediction successful!")
                print(f"\n🎯 Recommended Business: {result['predicted_business_name']}")
                print(f"   Code: {result['predicted_business_code']}")
                print(f"   Confidence: {result.get('confidence', 0):.2%} ({result.get('confidence_level', 'N/A')})")
                print(f"   Risk Level: {result.get('risk_level', 'N/A')}")
                print(f"   Capital Required: {result.get('capital_required', 'N/A')}")
                print(f"\n📝 Description: {result.get('description', 'N/A')}")

                if result.get('top_predictions') and len(result['top_predictions']) > 1:
                    print(f"\n📊 Alternatives:")
                    for alt in result['top_predictions'][1:3]:
                        print(f"   • {alt['business_name']}: {alt['confidence']:.2%}")
            else:
                print(f"❌ Prediction failed: {result.get('error', 'Unknown error')}")

    else:
        app = create_app()
        print(f"\n🚀 Starting Flask server on port {args.port}...")
        app.run(debug=True, host='0.0.0.0', port=args.port)