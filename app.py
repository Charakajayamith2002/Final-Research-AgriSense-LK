"""
AGRISENSE - Flask Application Main File with User Authentication
Integrates all 4 components with MongoDB
"""
import json
import os
import logging
from flask import Flask, render_template, request, jsonify, session, redirect, url_for, flash
from flask_cors import CORS
from flask_login import current_user
from torch._export import db
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
from datetime import datetime, timedelta

# Import custom modules
from db_config import MongoDBHandler
from model_loader import ModelLoader

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
app.secret_key = os.urandom(24)
CORS(app, supports_credentials=True)

@app.after_request
def add_cors_headers(response):
    origin = request.headers.get('Origin', '')
    if origin:
        response.headers['Access-Control-Allow-Origin'] = origin
        response.headers['Access-Control-Allow-Credentials'] = 'true'
        response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, Cookie, X-Requested-With, X-User-Id'
    return response

@app.before_request
def handle_preflight():
    if request.method == 'OPTIONS':
        from flask import Response as FlaskResponse
        r = FlaskResponse()
        origin = request.headers.get('Origin', '')
        if origin:
            r.headers['Access-Control-Allow-Origin'] = origin
            r.headers['Access-Control-Allow-Credentials'] = 'true'
            r.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
            r.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, Cookie, X-Requested-With, X-User-Id'
        return r

# Configuration
app.config['UPLOAD_FOLDER'] = 'static/uploads'
app.config['PROFILE_PHOTO_FOLDER'] = 'static/profile_photos'
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size
app.config['ALLOWED_EXTENSIONS'] = {'png', 'jpg', 'jpeg', 'bmp', 'gif', 'tiff', 'webp'}
app.config['PROFILE_PHOTO_EXTENSIONS'] = {'png', 'jpg', 'jpeg', 'webp'}

# Ensure upload directories exist
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
os.makedirs(app.config['PROFILE_PHOTO_FOLDER'], exist_ok=True)
os.makedirs('static/history', exist_ok=True)

# Initialize components
db_handler = MongoDBHandler()
model_loader = ModelLoader()

# Authentication and Authorization Decorator
def login_required(f):
    """Decorator to require login for protected routes (returns HTML redirect)"""
    from functools import wraps
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash('Please login to access this page', 'warning')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

def api_login_required(f):
    """Decorator for mobile/API routes — accepts session cookie OR X-User-Id header."""
    from functools import wraps
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Primary: Flask session cookie (web browser)
        if 'user_id' in session:
            return f(*args, **kwargs)
        # Fallback: token header for Flutter/mobile clients
        user_id = request.headers.get('X-User-Id', '').strip()
        if user_id:
            user = db_handler.get_user_by_id(user_id)
            if user:
                session['user_id'] = user_id
                return f(*args, **kwargs)
        return jsonify({'success': False, 'message': 'Not authenticated', 'code': 401}), 401
    return decorated_function

# Province-District-DS Division data
PROVINCE_DISTRICTS = {
    'Western Province': {
        'Colombo District': {
            'Colombo': {'lat': 6.9271, 'lon': 79.8612},
            'Dehiwala': {'lat': 6.8567, 'lon': 79.8633},
            'Moratuwa': {'lat': 6.7833, 'lon': 79.8833},
            'Sri Jayawardenepura Kotte': {'lat': 6.9100, 'lon': 79.8950}
        },
        'Gampaha District': {
            'Gampaha': {'lat': 7.0916, 'lon': 79.9997},
            'Negombo': {'lat': 7.2083, 'lon': 79.8358},
            'Kelaniya': {'lat': 6.9500, 'lon': 79.9167}
        },
        'Kalutara District': {
            'Kalutara': {'lat': 6.5831, 'lon': 79.9597},
            'Panadura': {'lat': 6.7133, 'lon': 79.9042},
            'Horana': {'lat': 6.7167, 'lon': 80.0667}
        }
    },
    'Central Province': {
        'Kandy District': {
            'Kandy': {'lat': 7.2964, 'lon': 80.6350},
            'Kundasale': {'lat': 7.2667, 'lon': 80.7000}
        },
        'Matale District': {
            'Matale': {'lat': 7.4717, 'lon': 80.6242},
            'Dambulla': {'lat': 7.8569, 'lon': 80.6514}
        },
        'Nuwara Eliya District': {
            'Nuwara Eliya': {'lat': 6.9706, 'lon': 80.7828}
        }
    },
    'Southern Province': {
        'Galle District': {
            'Galle': {'lat': 6.0536, 'lon': 80.2117}
        },
        'Matara District': {
            'Matara': {'lat': 5.9483, 'lon': 80.5353}
        },
        'Hambantota District': {
            'Hambantota': {'lat': 6.1244, 'lon': 81.1186}
        }
    },
    'Northern Province': {
        'Jaffna District': {
            'Jaffna': {'lat': 9.6617, 'lon': 80.0256}
        }
    },
    'Eastern Province': {
        'Batticaloa District': {
            'Batticaloa': {'lat': 7.7167, 'lon': 81.7000}
        }
    },
    'North Western Province': {
        'Kurunegala District': {
            'Kurunegala': {'lat': 7.4833, 'lon': 80.3667}
        },
        'Puttalam District': {
            'Puttalam': {'lat': 8.0333, 'lon': 79.8167}
        }
    },
    'North Central Province': {
        'Anuradhapura District': {
            'Anuradhapura': {'lat': 8.3350, 'lon': 80.4108}
        },
        'Polonnaruwa District': {
            'Polonnaruwa': {'lat': 7.9333, 'lon': 81.0000}
        }
    },
    'Uva Province': {
        'Badulla District': {
            'Badulla': {'lat': 6.9897, 'lon': 81.0560}
        },
        'Monaragala District': {
            'Monaragala': {'lat': 6.8714, 'lon': 81.3486}
        }
    },
    'Sabaragamuwa Province': {
        'Ratnapura District': {
            'Ratnapura': {'lat': 6.6828, 'lon': 80.3992}
        },
        'Kegalle District': {
            'Kegalle': {'lat': 7.2514, 'lon': 80.3464}
        }
    }
}

# Market coordinates for Component 2 — loaded from markets.json
with open('markets.json') as _f:
    _markets_data = json.load(_f)
MARKET_COORDINATES = {
    m['name']: {'lat': m['lat'], 'lon': m['lon']}
    for m in _markets_data['markets']
}

# Item data based on categories
ITEM_DATA = {
    'Vegetables': {
        'local': ['Beans', 'Carrot', 'Cabbage', 'Tomato', 'Brinjal', 'Pumpkin', 'Snake gourd', 'Green Chilli', 'Lime'],
    },
    'Fruits': {
        'local': ['Banana', 'Papaw', 'Pineapple'],
        'imported': ['Apple', 'Orange'],
    },
    'Rice': {
        'local': ['Samba', 'Nadu', 'Kekulu'],
        'imported': ['Ponni Samba'],
    },
    'Other': {
        'local': ['Big Onion', 'Potato', 'Coconut', 'Coconut oil', 'Sugar', 'Egg'],
        'imported': ['Red Onion', 'Big Onion', 'Potato', 'Dried Chilli', 'Red Dhal', 'Katta', 'Sprat'],
    },
    'Fish': {
        'local': ['Kelawalla', 'Thalapath', 'Balaya', 'Paraw', 'Salaya', 'Hurulla', 'Linna'],
    }
}

# ============ MOBILE API ROUTES (for Flutter app) ============

@app.route('/api/mobile/login', methods=['POST'])
def mobile_login():
    """Mobile login - returns JSON"""
    try:
        data = request.get_json() or request.form
        email = str(data.get('email', '')).lower().strip()
        password = str(data.get('password', ''))
        if not email or not password:
            return jsonify({'success': False, 'message': 'Email and password required'}), 400
        user = db_handler.get_user_by_email(email)
        if not user:
            return jsonify({'success': False, 'message': 'Invalid email or password'}), 401
        if not check_password_hash(user['password_hash'], password):
            return jsonify({'success': False, 'message': 'Invalid email or password'}), 401
        db_handler.update_user_login(str(user['_id']))
        session['user_id'] = str(user['_id'])
        session['username'] = user['username']
        session['user_type'] = user.get('user_type', 'buyer')
        session['email'] = user['email']
        return jsonify({
            'success': True,
            'username': user['username'],
            'email': user['email'],
            'user_type': user.get('user_type', 'buyer'),
            'user_id': str(user['_id'])
        })
    except Exception as e:
        logger.error(f"Mobile login error: {str(e)}")
        return jsonify({'success': False, 'message': 'Server error'}), 500

@app.route('/api/mobile/register', methods=['POST'])
def mobile_register():
    """Mobile register - returns JSON"""
    try:
        data = request.get_json() or request.form
        username = str(data.get('username', '')).strip()
        email = str(data.get('email', '')).lower().strip()
        password = str(data.get('password', ''))
        user_type = str(data.get('user_type', 'farmer'))
        if not username or not email or not password:
            return jsonify({'success': False, 'message': 'All fields required'}), 400
        existing = db_handler.get_user_by_email(email)
        if existing:
            return jsonify({'success': False, 'message': 'Email already registered'}), 400
        password_hash = generate_password_hash(password)
        user_data = {
            'username': username,
            'email': email,
            'password_hash': password_hash,
            'user_type': user_type,
            'created_at': datetime.now()
        }
        user_id = db_handler.create_user(user_data)
        session['user_id'] = str(user_id)
        session['username'] = username
        session['user_type'] = user_type
        session['email'] = email
        return jsonify({
            'success': True,
            'username': username,
            'email': email,
            'user_type': user_type
        })
    except Exception as e:
        logger.error(f"Mobile register error: {str(e)}")
        return jsonify({'success': False, 'message': 'Server error'}), 500

@app.route('/api/mobile/resolve-user', methods=['GET'])
def resolve_user_by_email():
    """Return user_id for a given email — lets the app recover auth without re-login."""
    email = request.args.get('email', '').lower().strip()
    if not email:
        return jsonify({'success': False}), 400
    user = db_handler.get_user_by_email(email)
    if not user:
        return jsonify({'success': False, 'message': 'User not found'}), 404
    return jsonify({
        'success': True,
        'user_id': str(user['_id']),
        'username': user.get('username', ''),
        'user_type': user.get('user_type', ''),
        'profile_photo': user.get('profile_photo', ''),
    })

@app.route('/api/mobile/logout', methods=['POST', 'GET'])
def mobile_logout():
    """Mobile logout - returns JSON"""
    session.clear()
    return jsonify({'success': True})

@app.route('/api/mobile/cultivation-targeting', methods=['POST'])
def mobile_cultivation_targeting():
    """Mobile API for cultivation targeting - returns JSON with recommendations + weather"""
    try:
        import requests as req_lib
        data = request.get_json() or {}
        validated_input = {
            'month': int(data.get('month', 1)),
            'category': data.get('category', 'All'),
            'risk_tolerance': data.get('risk_tolerance', 'medium'),
            'budget': float(data.get('budget', 10000)),
            'land_size': float(data.get('land_size', 1.0)),
            'water_availability': data.get('water_availability', 'medium'),
            'soil_type': data.get('soil_type', 'loam'),
        }
        recommendations = model_loader.predict_component3(validated_input)

        # Fetch real weather from Open-Meteo (free, no key needed)
        lat = float(data.get('latitude', 7.75))
        lon = float(data.get('longitude', 80.75))
        weather = None
        forecast_days = []
        try:
            w_url = (
                f"https://api.open-meteo.com/v1/forecast"
                f"?latitude={lat}&longitude={lon}"
                f"&current=temperature_2m,relative_humidity_2m,precipitation,"
                f"wind_speed_10m,soil_temperature_0cm,weather_code"
                f"&daily=temperature_2m_max,temperature_2m_min,"
                f"relative_humidity_2m_max,relative_humidity_2m_min,"
                f"precipitation_sum,wind_speed_10m_max,weather_code"
                f"&timezone=Asia%2FColombo&forecast_days=7"
            )
            w_resp = req_lib.get(w_url, timeout=8)
            if w_resp.status_code == 200:
                w_data = w_resp.json()
                cur = w_data.get('current', {})
                daily = w_data.get('daily', {})
                weather = {
                    'temperature': round(cur.get('temperature_2m', 25), 1),
                    'humidity': cur.get('relative_humidity_2m', 70),
                    'precipitation': round(cur.get('precipitation', 0), 2),
                    'wind_speed': round(cur.get('wind_speed_10m', 10), 1),
                    'soil_temp': round(cur.get('soil_temperature_0cm', 24), 1),
                    'weather_code': cur.get('weather_code', 0),
                    'latitude': lat,
                    'longitude': lon,
                }
                dates = daily.get('time', [])
                t_max = daily.get('temperature_2m_max', [])
                t_min = daily.get('temperature_2m_min', [])
                hum_max = daily.get('relative_humidity_2m_max', [])
                hum_min = daily.get('relative_humidity_2m_min', [])
                precip = daily.get('precipitation_sum', [])
                wind = daily.get('wind_speed_10m_max', [])
                codes = daily.get('weather_code', [])
                for i in range(len(dates)):
                    forecast_days.append({
                        'date': dates[i],
                        'temp_max': round(t_max[i], 1) if i < len(t_max) else 0,
                        'temp_min': round(t_min[i], 1) if i < len(t_min) else 0,
                        'humidity_max': hum_max[i] if i < len(hum_max) else 0,
                        'humidity_min': hum_min[i] if i < len(hum_min) else 0,
                        'precipitation': round(precip[i], 2) if i < len(precip) else 0,
                        'wind_max': round(wind[i], 1) if i < len(wind) else 0,
                        'weather_code': codes[i] if i < len(codes) else 0,
                    })
        except Exception as we:
            logger.warning(f"Weather fetch failed: {we}")
            # Fallback simulated weather
            weather = {
                'temperature': 25.0, 'humidity': 70, 'precipitation': 0.0,
                'wind_speed': 10.0, 'soil_temp': 24.0, 'weather_code': 0,
                'latitude': lat, 'longitude': lon,
            }

        return jsonify({
            'success': True,
            **recommendations,
            'weather': weather,
            'forecast': forecast_days,
        })
    except Exception as e:
        logger.error(f"Mobile cultivation targeting error: {str(e)}")
        return jsonify({'success': False, 'message': str(e)}), 400

@app.route('/api/mobile/market-ranking', methods=['POST'])
def mobile_market_ranking():
    """Mobile API for market ranking - returns JSON"""
    try:
        data = request.get_json() or {}
        latitude = float(data.get('latitude', 7.2906))
        longitude = float(data.get('longitude', 80.6337))
        quantity = float(data.get('quantity', 1))
        quantity_unit = data.get('quantity_unit', 'kg')
        user_role = data.get('user_role', 'seller')
        additional_transport_cost = float(data.get('additional_transport_cost', 0))
        cultivation_cost = float(data.get('cultivation_cost', 0))
        reference_price = float(data.get('reference_price', 0) or 0)

        model_input = {
            'item': data.get('item'),
            'price_type': data.get('price_type', 'Wholesale'),
            'user_role': user_role,
            'latitude': latitude,
            'longitude': longitude,
            'transport_cost_per_km': float(data.get('transport_cost', 160)),
            'additional_transport_cost': additional_transport_cost,
            'quantity': quantity,
            'quantity_unit': quantity_unit,
            'cultivation_cost': cultivation_cost,
            'reference_price': reference_price,
        }

        recommendations = model_loader.predict_component2(model_input)

        if recommendations and 'recommendations' in recommendations:
            for rec in recommendations['recommendations']:
                market_name = rec['market']
                if market_name in MARKET_COORDINATES:
                    rec['market_lat'] = MARKET_COORDINATES[market_name]['lat']
                    rec['market_lon'] = MARKET_COORDINATES[market_name]['lon']

        return jsonify({'success': True, **recommendations})
    except Exception as e:
        logger.error(f"Mobile market ranking error: {str(e)}")
        return jsonify({'success': False, 'message': str(e)}), 400

@app.route('/api/mobile/profitable-strategy', methods=['POST'])
def mobile_profitable_strategy():
    """Mobile API for profitable strategy prediction - returns JSON"""
    if business_predictor is None:
        return jsonify({'success': False, 'message': 'Business predictor not initialized'}), 500
    try:
        data = request.get_json() or {}
        result = business_predictor.predict(data)
        return jsonify({'success': True, **result})
    except Exception as e:
        logger.error(f"Mobile profitable strategy error: {str(e)}")
        return jsonify({'success': False, 'message': str(e)}), 400

@app.route('/api/mobile/yield-quality', methods=['POST'])
def mobile_yield_quality():
    """Mobile API for yield quality prediction - returns JSON (no image_urls)"""
    try:
        if 'images' not in request.files:
            return jsonify({'success': False, 'message': 'No image files uploaded'}), 400

        files = request.files.getlist('images')
        if not files or all(f.filename == '' for f in files):
            return jsonify({'success': False, 'message': 'No images selected'}), 400

        valid_files = [f for f in files if f and allowed_file(f.filename)]
        if not valid_files:
            return jsonify({'success': False, 'message': 'No valid image files provided'}), 400

        best_unit_price = request.form.get('best_unit_price')
        if not best_unit_price:
            return jsonify({'success': False, 'message': 'Best unit price is required'}), 400
        try:
            best_unit_price = float(best_unit_price)
        except ValueError:
            return jsonify({'success': False, 'message': 'Best unit price must be a valid number'}), 400

        import torch
        from torchvision import transforms
        from PIL import Image as PILImage
        import io

        # Load and cache model — share with web yield_quality endpoint
        if not hasattr(yield_quality, 'model'):
            import torch.nn as nn

            class ResNet50HealthClassifier(nn.Module):
                def __init__(self, num_classes=1, pretrained=False, freeze_backbone=False):
                    super().__init__()
                    from torchvision import models
                    self.backbone = models.resnet50(pretrained=pretrained)
                    num_features = self.backbone.fc.in_features
                    self.backbone.fc = nn.Identity()
                    self.classifier = nn.Sequential(
                        nn.Dropout(p=0.5),
                        nn.Linear(num_features, 512),
                        nn.ReLU(inplace=True),
                        nn.BatchNorm1d(512),
                        nn.Dropout(p=0.3),
                        nn.Linear(512, 128),
                        nn.ReLU(inplace=True),
                        nn.BatchNorm1d(128),
                        nn.Linear(128, num_classes)
                    )
                    if freeze_backbone:
                        for param in self.backbone.parameters():
                            param.requires_grad = False

                def forward(self, x):
                    x = self.backbone(x)
                    x = self.classifier(x)
                    return x

            model = ResNet50HealthClassifier(num_classes=1, pretrained=False, freeze_backbone=True)
            model_path = 'models/4/model_latest.pth'
            model.load_state_dict(torch.load(model_path, map_location='cpu'))
            model.eval()
            yield_quality.model = model

        model = yield_quality.model

        preprocess = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ])

        probabilities = []
        predicted_classes = []

        for file in valid_files:
            img_bytes = file.read()
            img = PILImage.open(io.BytesIO(img_bytes)).convert('RGB')
            input_tensor = preprocess(img).unsqueeze(0)

            with torch.no_grad():
                output = model(input_tensor)
                if isinstance(output, tuple):
                    output = output[0]
                probability = torch.sigmoid(output).item() if output.numel() == 1 else torch.softmax(output, dim=1).max().item()
                if probability <= 0.1:
                    probability = probability * 10

            probabilities.append(probability)

            if output.numel() == 1:
                if probability < 0.1:
                    predicted_class = 'NULL OR ROTTEN'
                elif probability < 0.4:
                    predicted_class = 'Grade_C'
                elif probability < 0.9:
                    predicted_class = 'Grade_B'
                else:
                    predicted_class = 'Grade_A'
            else:
                predicted_idx = torch.softmax(output, dim=1).argmax().item()
                class_names = ['Grade_A', 'Grade_B', 'Grade_C', 'NULL']
                predicted_class = class_names[predicted_idx]
            predicted_classes.append(predicted_class)

        mean_probability = sum(probabilities) / len(probabilities)

        if mean_probability < 0.1:
            overall_class = 'NULL OR ROTTEN'
        elif mean_probability < 0.4:
            overall_class = 'Grade_C'
        elif mean_probability < 0.9:
            overall_class = 'Grade_B'
        else:
            overall_class = 'Grade_A'

        prediction = {
            'mean_probability': round(mean_probability, 4),
            'individual_probabilities': [round(p, 4) for p in probabilities],
            'predicted_class': overall_class,
            'individual_classes': predicted_classes,
            'num_images': len(valid_files),
            'best_unit_price': best_unit_price,
            'upload_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }

        history_data = {
            'component': 'yield_quality',
            'input': {'num_files': len(valid_files), 'best_unit_price': best_unit_price},
            'output': prediction,
            'timestamp': datetime.now(),
            'user_id': session.get('user_id')
        }
        db_handler.save_prediction(history_data)

        return jsonify({'success': True, **prediction})

    except Exception as e:
        logger.error(f"Mobile yield quality error: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'success': False, 'message': str(e)}), 400

# ============ AUTHENTICATION ROUTES ============

@app.route('/register', methods=['GET', 'POST'])
def register():
    """User registration"""
    if request.method == 'POST':
        try:
            # Get form data
            email = request.form.get('email').lower().strip()
            username = request.form.get('username').strip()
            password = request.form.get('password')
            confirm_password = request.form.get('confirm_password')
            user_type = request.form.get('user_type', 'buyer')

            # Validation
            if not all([email, username, password, confirm_password]):
                flash('All fields are required', 'error')
                return redirect(url_for('register'))

            if password != confirm_password:
                flash('Passwords do not match', 'error')
                return redirect(url_for('register'))

            if len(password) < 6:
                flash('Password must be at least 6 characters', 'error')
                return redirect(url_for('register'))

            # Check if user already exists
            if db_handler.get_user_by_email(email):
                flash('Email already registered', 'error')
                return redirect(url_for('register'))

            if db_handler.get_user_by_username(username):
                flash('Username already taken', 'error')
                return redirect(url_for('register'))

            # Create new user
            user_data = {
                'email': email,
                'username': username,
                'password_hash': generate_password_hash(password),
                'user_type': user_type,  # 'buyer' or 'seller'
                'created_at': datetime.now(),
                'last_login': datetime.now(),
                'preferences': {},
                'history': []
            }

            # Save to database
            user_id = db_handler.create_user(user_data)

            if user_id:
                # Set session
                session['user_id'] = str(user_id)
                session['username'] = username
                session['user_type'] = user_type
                session['email'] = email

                flash('Registration successful! Welcome to AgriSense', 'success')
                return redirect(url_for('home'))
            else:
                flash('Registration failed. Please try again.', 'error')

        except Exception as e:
            logger.error(f"Registration error: {str(e)}")
            flash('An error occurred during registration', 'error')

    return render_template('signup.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    """User login"""
    if request.method == 'POST':
        try:
            email = request.form.get('email').lower().strip()
            password = request.form.get('password')

            # Validate input
            if not email or not password:
                flash('Please enter both email and password', 'error')
                return redirect(url_for('login'))

            # Get user from database
            user = db_handler.get_user_by_email(email)

            if not user:
                flash('Invalid email or password', 'error')
                return redirect(url_for('login'))

            # Check password
            if not check_password_hash(user['password_hash'], password):
                flash('Invalid email or password', 'error')
                return redirect(url_for('login'))

            # Update last login
            db_handler.update_user_login(str(user['_id']))

            # Set session
            session['user_id'] = str(user['_id'])
            session['username'] = user['username']
            session['user_type'] = user.get('user_type', 'buyer')
            session['email'] = user['email']

            flash(f'Welcome back, {user["username"]}!', 'success')
            next_page = request.args.get('next', url_for('home'))
            return redirect(next_page)

        except Exception as e:
            logger.error(f"Login error: {str(e)}")
            flash('An error occurred during login', 'error')

    return render_template('signin.html')

@app.route('/logout')
def logout():
    """User logout"""
    session.clear()
    flash('You have been logged out successfully', 'info')
    return redirect(url_for('home'))

@app.route('/profile')
@login_required
def profile():
    """User profile page"""
    user_data = db_handler.get_user_by_id(session['user_id'])
    if not user_data:
        flash('User not found', 'error')
        return redirect(url_for('logout'))

    # Get user history
    history = db_handler.get_user_history(session['user_id'])

    return render_template('profile.html',
                         user=user_data,
                         history=history[:10])  # Show last 10 predictions

@app.route('/update-profile', methods=['POST'])
@login_required
def update_profile():
    """Update user profile"""
    try:
        username = request.form.get('username').strip()
        user_type = request.form.get('user_type')

        # Update in database
        updated = db_handler.update_user_profile(
            session['user_id'],
            username=username,
            user_type=user_type
        )

        if updated:
            session['username'] = username
            session['user_type'] = user_type
            flash('Profile updated successfully', 'success')
        else:
            flash('Failed to update profile', 'error')

    except Exception as e:
        logger.error(f"Profile update error: {str(e)}")
        flash('An error occurred', 'error')

    return redirect(url_for('profile'))

def _save_photo_to_mongo(user_id, file):
    """Read file bytes, store as base64 in MongoDB, return the serving URL."""
    import base64
    ext = file.filename.rsplit('.', 1)[-1].lower() if '.' in file.filename else 'jpg'
    mime = 'image/jpeg' if ext in ('jpg', 'jpeg') else f'image/{ext}'
    photo_bytes = file.read()
    photo_b64 = base64.b64encode(photo_bytes).decode('utf-8')
    photo_url = f'/api/profile-photo/{user_id}'
    db_handler.update_user_profile(
        user_id,
        profile_photo=photo_url,
        profile_photo_data=photo_b64,
        profile_photo_type=mime,
    )
    return photo_url


@app.route('/api/profile-photo/<user_id>', methods=['GET'])
def serve_profile_photo(user_id):
    """Serve profile photo stored in MongoDB — no filesystem needed."""
    import base64
    from flask import Response
    try:
        user_data = db_handler.get_user_by_id(user_id)
        if not user_data or 'profile_photo_data' not in user_data:
            return '', 404
        photo_bytes = base64.b64decode(user_data['profile_photo_data'])
        mime = user_data.get('profile_photo_type', 'image/jpeg')
        return Response(photo_bytes, mimetype=mime,
                        headers={'Cache-Control': 'public, max-age=86400'})
    except Exception as e:
        logger.error(f"Serve profile photo error: {str(e)}")
        return '', 500


@app.route('/upload-profile-photo', methods=['POST'])
@login_required
def upload_profile_photo_web():
    """Upload profile photo from the web UI — stored in MongoDB."""
    if 'photo' not in request.files:
        flash('No file selected', 'error')
        return redirect(url_for('profile'))

    file = request.files['photo']
    if not file or file.filename == '':
        flash('No file selected', 'error')
        return redirect(url_for('profile'))

    ext = file.filename.rsplit('.', 1)[-1].lower() if '.' in file.filename else ''
    if ext not in app.config['PROFILE_PHOTO_EXTENSIONS']:
        flash('Invalid file type. Use JPG, PNG, or WEBP.', 'error')
        return redirect(url_for('profile'))

    try:
        photo_url = _save_photo_to_mongo(session['user_id'], file)
        session['profile_photo'] = photo_url
        flash('Profile photo updated successfully', 'success')
    except Exception as e:
        logger.error(f"Profile photo upload error: {str(e)}")
        flash('Failed to upload photo', 'error')

    return redirect(url_for('profile'))


@app.route('/api/mobile/upload-profile-photo', methods=['POST'])
@api_login_required
def upload_profile_photo_api():
    """Mobile API: Upload profile photo — stored in MongoDB."""
    if 'photo' not in request.files:
        return jsonify({'success': False, 'message': 'No file provided'}), 400

    file = request.files['photo']
    if not file or file.filename == '':
        return jsonify({'success': False, 'message': 'Empty file'}), 400

    ext = file.filename.rsplit('.', 1)[-1].lower() if '.' in file.filename else ''
    if ext not in app.config['PROFILE_PHOTO_EXTENSIONS']:
        return jsonify({'success': False, 'message': 'Invalid file type. Use JPG, PNG, or WEBP.'}), 400

    try:
        user_id = session['user_id']
        photo_url = _save_photo_to_mongo(user_id, file)
        session['profile_photo'] = photo_url
        return jsonify({'success': True, 'photo_url': photo_url})
    except Exception as e:
        logger.error(f"Mobile profile photo upload error: {str(e)}")
        return jsonify({'success': False, 'message': 'Server error'}), 500


@app.route('/api/mobile/get-profile', methods=['GET'])
@api_login_required
def get_profile_api():
    """Mobile API: Get current user profile"""
    try:
        user_data = db_handler.get_user_by_id(session['user_id'])
        if not user_data:
            return jsonify({'success': False, 'message': 'User not found'}), 404

        return jsonify({
            'success': True,
            'username': user_data.get('username', ''),
            'email': user_data.get('email', ''),
            'user_type': user_data.get('user_type', ''),
            'profile_photo': user_data.get('profile_photo', ''),
        })
    except Exception as e:
        logger.error(f"Get profile API error: {str(e)}")
        return jsonify({'success': False, 'message': 'Server error'}), 500


# ============ PROTECTED APPLICATION ROUTES ============

@app.route('/')
def home():
    """Home page"""
    return render_template('home.html', user=session)


@app.route('/price-demand', methods=['GET', 'POST'])
@login_required
def price_demand():
    """Price & Demand Prediction Page"""
    form_data = None
    prediction = {}
    error = None

    if request.method == 'POST':
        try:
            # Extract form data
            form_data = {
                'category': request.form.get('category'),
                'item_standard': request.form.get('item_standard'),
                'origin_type': request.form.get('origin_type'),
                'price_type': request.form.get('price_type'),
                'market': request.form.get('market'),
                'previous_price': float(request.form.get('previous_price', 250)),
                'year': int(request.form.get('year', 2024)),
                'month': int(request.form.get('month', 1)),
                'day': int(request.form.get('day', 1)),
                'dayofweek': int(request.form.get('dayofweek', 0)),
                'week': int(request.form.get('week', 1)),
                'quarter': int(request.form.get('quarter', 1)),
                'season': request.form.get('season', 'Maha'),
                'rolling_mean_7': float(request.form.get('rolling_mean_7', 245)),
                'rolling_std_7': float(request.form.get('rolling_std_7', 8)),
                'rolling_mean_3': float(request.form.get('rolling_mean_3', 248)),
                'volatility_index': float(request.form.get('volatility_index', 1.2)),
                'market_sentiment': request.form.get('market_sentiment', 'neutral'),
                'supply_status': request.form.get('supply_status', 'adequate')
            }

            # Call the model loader for prediction
            if 'model_loader' not in globals():
                from model_loader import ModelLoader
                global model_loader
                model_loader = ModelLoader()
                model_loader.load_all_models()

            # Prepare input data for the model
            prediction_input = form_data.copy()

            # Get prediction
            prediction_result = model_loader.predict_component1(prediction_input)

            # Ensure prediction is a dictionary
            if not isinstance(prediction_result, dict):
                error = "Prediction returned unexpected type"
                print(f"ERROR: {error}")
                prediction = {}
            else:
                prediction = prediction_result

                # Save prediction to database
                try:
                    prediction_doc = {
                        'user_id': current_user.id,
                        'timestamp': datetime.now(),
                        'input_data': form_data,
                        'prediction_result': prediction,
                        'model_used': prediction.get('model_used', 'unknown')
                    }
                    db.predictions.insert_one(prediction_doc)
                    print("INFO: Prediction saved")
                except Exception as db_error:
                    print(f"WARNING: Could not save prediction to DB: {db_error}")

        except Exception as e:
            error = str(e)
            print(f"ERROR: {error}")
            prediction = {}

    # Always render the template with all required variables
    return render_template('price_demand.html',
                           items=ITEM_DATA,
                           form_data=form_data or {},
                           prediction=prediction or {},
                           error=error)

@app.route('/market-ranking', methods=['GET', 'POST'])
@login_required
def market_ranking():
    """Component 2: Market Opportunity Ranking"""
    if request.method == 'POST':
        try:
            form_data = request.form.to_dict()

            # Extract DS Division if provided
            ds_division = form_data.get('ds_division')

            # Get coordinates - first try DS Division, then fallback to District
            latitude = None
            longitude = None

            if ds_division:
                # Find coordinates for DS Division
                province = form_data.get('province')
                district = form_data.get('district')

                if province and district:
                    districts = PROVINCE_DISTRICTS.get(province, {})
                    ds_divisions = districts.get(district, {})
                    if ds_division in ds_divisions:
                        coords = ds_divisions[ds_division]
                        latitude = coords['lat']
                        longitude = coords['lon']

            # If no DS Division coordinates, use district coordinates
            if latitude is None or longitude is None:
                province = form_data.get('province')
                district = form_data.get('district')
                if province and district:
                    # Get first DS Division in the district as fallback
                    districts = PROVINCE_DISTRICTS.get(province, {})
                    ds_divisions = districts.get(district, {})
                    if ds_divisions:
                        first_ds = next(iter(ds_divisions.values()))
                        latitude = first_ds['lat']
                        longitude = first_ds['lon']

            # Final fallback to default coordinates
            if latitude is None or longitude is None:
                latitude = float(form_data.get('latitude', 7.2906))
                longitude = float(form_data.get('longitude', 80.6337))

            # Validate quantity
            quantity = float(form_data.get('quantity', 1))
            if quantity <= 0:
                raise Exception("Quantity must be greater than 0")

            quantity_unit = form_data.get('quantity_unit', 'kg')
            additional_transport_cost = float(form_data.get('additional_transport_cost', 0))
            if additional_transport_cost < 0:
                raise Exception("Additional transport cost cannot be negative")

            # Validate cultivation cost for sellers
            user_role = form_data.get('user_role')
            cultivation_cost = 0
            if user_role == 'seller':
                cultivation_cost = float(form_data.get('cultivation_cost', 0))
                if cultivation_cost <= 0:
                    raise Exception("Cultivation cost is required for sellers and must be greater than 0")

            # Prepare input
            model_input = {
                'item': form_data.get('item'),
                'price_type': form_data.get('price_type'),
                'user_role': user_role,
                'latitude': latitude,
                'longitude': longitude,
                'transport_cost_per_km': float(form_data.get('transport_cost', 160)),
                'additional_transport_cost': additional_transport_cost,
                'quantity': quantity,
                'quantity_unit': quantity_unit,
                'cultivation_cost': cultivation_cost,
                'reference_price': float(form_data.get('reference_price', 0) or 0),
            }

            # Get recommendations
            recommendations = model_loader.predict_component2(model_input)

            # Add market coordinates to recommendations for map display
            if recommendations and 'recommendations' in recommendations:
                for rec in recommendations['recommendations']:
                    market_name = rec['market']
                    if market_name in MARKET_COORDINATES:
                        rec['market_lat'] = MARKET_COORDINATES[market_name]['lat']
                        rec['market_lon'] = MARKET_COORDINATES[market_name]['lon']

            # Save to history
            history_data = {
                'component': 'market_ranking',
                'input': model_input,
                'output': recommendations,
                'timestamp': datetime.now(),
                'user_id': session.get('user_id')
            }
            db_handler.save_prediction(history_data)

            return render_template('market_ranking.html',
                                   recommendations=recommendations,
                                   form_data=form_data,
                                   provinces=PROVINCE_DISTRICTS,
                                   items=ITEM_DATA)

        except Exception as e:
            logger.error(f"Market ranking error: {str(e)}")
            import traceback
            traceback.print_exc()
            return render_template('market_ranking.html',
                                   error=str(e),
                                   provinces=PROVINCE_DISTRICTS,
                                   items=ITEM_DATA)

    return render_template('market_ranking.html',
                           provinces=PROVINCE_DISTRICTS,
                           items=ITEM_DATA)

@app.route('/cultivation-targeting', methods=['GET', 'POST'])
@login_required
def cultivation_targeting():
    """Component 3: Cultivation Targeting with better error handling"""
    if request.method == 'POST':
        try:
            form_data = request.form.to_dict()

            # Validate input
            validated_input = {
                'month': int(form_data.get('month', 1)),
                'category': form_data.get('category', 'All'),
                'risk_tolerance': form_data.get('risk_tolerance', 'medium'),
                'budget': float(form_data.get('budget', 10000)),
                'land_size': float(form_data.get('land_size', 1.0)),
                'water_availability': form_data.get('water_availability', 'medium'),
                'soil_type': form_data.get('soil_type', 'loam')
            }

            # Get recommendations
            recommendations = model_loader.predict_component3(validated_input)

            # Save to history
            history_data = {
                'component': 'cultivation_targeting',
                'input': validated_input,
                'output': recommendations,
                'timestamp': datetime.now(),
                'user_id': session.get('user_id')
            }
            db_handler.save_prediction(history_data)

            return render_template('cultivation_targeting.html',
                                   recommendations=recommendations,
                                   form_data=validated_input,
                                   success=True)

        except Exception as e:
            logger.error(f"Cultivation targeting error: {str(e)}")
            return render_template('cultivation_targeting.html',
                                   error=str(e),
                                   form_data=request.form.to_dict() if 'form_data' in locals() else {},
                                   success=False)

    return render_template('cultivation_targeting.html', success=False)

# Updated code of component 04
@app.route('/yield-quality', methods=['GET', 'POST'])
@login_required
def yield_quality():
    """Component 4: Yield Quality Scaling using a separate PyTorch model (.pth)"""
    if request.method == 'POST':
        try:
            # Check if files were uploaded
            if 'images' not in request.files:
                return render_template('yield_quality_scaling.html',
                                       error='No image files uploaded')

            files = request.files.getlist('images')

            if not files or all(f.filename == '' for f in files):
                return render_template('yield_quality_scaling.html',
                                       error='No images selected')

            # Filter valid files
            valid_files = [f for f in files if f and allowed_file(f.filename)]

            if not valid_files:
                return render_template('yield_quality_scaling.html',
                                       error='No valid image files provided')

            # Get best unit price from form
            best_unit_price = request.form.get('best_unit_price')
            if not best_unit_price:
                return render_template('yield_quality_scaling.html',
                                       error='Best unit price is required')
            
            try:
                best_unit_price = float(best_unit_price)
            except ValueError:
                return render_template('yield_quality_scaling.html',
                                       error='Best unit price must be a valid number')

            # Load the separate PyTorch model and make prediction
            import torch
            from torchvision import transforms
            from PIL import Image

            # Load ResNet50HealthClassifier model (load once and cache)
            if not hasattr(yield_quality, 'model'):
                import torch.nn as nn

                class ResNet50HealthClassifier(nn.Module):
                    """ResNet-50 model for binary health classification"""
                    def __init__(self, num_classes=1, pretrained=False, freeze_backbone=False):
                        super().__init__()
                        from torchvision import models
                        self.backbone = models.resnet50(pretrained=pretrained)
                        num_features = self.backbone.fc.in_features
                        self.backbone.fc = nn.Identity()
                        self.classifier = nn.Sequential(
                            nn.Dropout(p=0.5),
                            nn.Linear(num_features, 512),
                            nn.ReLU(inplace=True),
                            nn.BatchNorm1d(512),
                            nn.Dropout(p=0.3),
                            nn.Linear(512, 128),
                            nn.ReLU(inplace=True),
                            nn.BatchNorm1d(128),
                            nn.Linear(128, num_classes)
                        )
                        if freeze_backbone:
                            for param in self.backbone.parameters():
                                param.requires_grad = False

                    def forward(self, x):
                        x = self.backbone(x)
                        x = self.classifier(x)
                        return x

                    def get_health_score(self, x):
                        logits = self.forward(x)
                        return torch.sigmoid(logits)

                model = ResNet50HealthClassifier(num_classes=1, pretrained=False, freeze_backbone=True)
                model_path = 'models/4/model_latest.pth'  # Update path as needed
                model.load_state_dict(torch.load(model_path, map_location='cpu'))
                model.eval()
                yield_quality.model = model
            else:
                model = yield_quality.model

            # Image preprocessing
            preprocess = transforms.Compose([
                transforms.Resize((224, 224)),
                transforms.ToTensor(),
                transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
            ])

            # Process all images
            probabilities = []
            image_urls = []
            predicted_classes = []

            for file in valid_files:
                # Save uploaded file
                filename = f"{datetime.now().strftime('%Y%m%d_%H%M%S')}_{secure_filename(file.filename)}"
                filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                file.save(filepath)

                # Predict probability
                img = Image.open(filepath).convert('RGB')
                input_tensor = preprocess(img).unsqueeze(0)

                with torch.no_grad():
                    output = model(input_tensor)
                    if isinstance(output, tuple):
                        output = output[0]
                    probability = torch.sigmoid(output).item() if output.numel() == 1 else torch.softmax(output, dim=1).max().item()
                    if probability <= 0.1:
                        probability = probability * 10

                probabilities.append(probability)
                image_urls.append(url_for('static', filename=f'uploads/{filename}'))

                # Determine class
                if output.numel() == 1:
                    if probability < 0.1:
                        predicted_class = 'NULL OR ROTTEN'
                    elif probability < 0.4:
                        predicted_class = 'Grade_C'
                    elif probability < 0.9:
                        predicted_class = 'Grade_B'
                    else:
                        predicted_class = 'Grade_A'
                else:
                    predicted_idx = torch.softmax(output, dim=1).argmax().item()
                    class_names = ['Grade_A', 'Grade_B', 'Grade_C', 'NULL']
                    predicted_class = class_names[predicted_idx]

                predicted_classes.append(predicted_class)

            # Calculate mean probability
            mean_probability = sum(probabilities) / len(probabilities)

            # Determine overall class based on mean probability
            if mean_probability < 0.1:
                overall_class = 'NULL OR ROTTEN'
            elif mean_probability < 0.4:
                overall_class = 'Grade_C'
            elif mean_probability < 0.9:
                overall_class = 'Grade_B'
            else:
                overall_class = 'Grade_A'

            prediction = {
                'mean_probability': round(mean_probability, 4),
                'individual_probabilities': [round(p, 4) for p in probabilities],
                'predicted_class': overall_class,
                'individual_classes': predicted_classes,
                'image_urls': image_urls,
                'num_images': len(valid_files),
                'best_unit_price': best_unit_price,
                'upload_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }

            # Save to history
            history_data = {
                'component': 'yield_quality',
                'input': {'num_files': len(valid_files), 'best_unit_price': best_unit_price},
                'output': prediction,
                'timestamp': datetime.now(),
                'user_id': session.get('user_id')
            }
            db_handler.save_prediction(history_data)

            return render_template('yield_quality_scaling.html',
                                   prediction=prediction)

        except Exception as e:
            logger.error(f"Yield quality prediction error: {str(e)}")
            import traceback
            traceback.print_exc()
            return render_template('yield_quality_scaling.html',
                                   error=str(e))

    return render_template('yield_quality_scaling.html')

# End 0f Updated code of component 04

# Import Component 5
from component_5 import BusinessIdeaPredictor

# Initialize component 5 predictor
business_predictor = None
try:
    business_predictor = BusinessIdeaPredictor('models/5')
    logger.info("Component 5 initialized successfully")
except Exception as e:
    logger.error(f"Failed to initialize Component 5: {e}")


@app.route('/profitable-strategy', methods=['GET', 'POST'])
@login_required
def profitable_strategy():
    """Component 5: Business Idea Prediction"""
    if request.method == 'POST':
        try:
            # Get form data
            form_data = request.form.to_dict()

            # Convert numeric fields
            numeric_fields = ['monthly_income',
                              'available_budget', 'loan_amount', 'loan_rate', 'loan_period_months',
                              'predicted_price', 'distance_km', 'transport_cost', 'net_advantage',
                              'cultivation_profitability', 'cultivation_risk', 'optimal_month']

            for field in numeric_fields:
                if field in form_data and form_data[field]:
                    try:
                        form_data[field] = float(form_data[field])
                    except:
                        form_data[field] = 0.0

            # Get prediction
            if business_predictor:
                result = business_predictor.predict(form_data)
            else:
                result = {'success': False, 'error': 'Business predictor not initialized'}

            # Save to history if successful
            if result.get('success'):
                history_data = {
                    'component': 'profitable_strategy',
                    'input': form_data,
                    'output': result,
                    'timestamp': datetime.now(),
                    'user_id': session.get('user_id')
                }
                db_handler.save_prediction(history_data)

            return render_template('profitable_strategy.html', result=result)

        except Exception as e:
            logger.error(f"Profitable strategy error: {str(e)}")
            import traceback
            traceback.print_exc()
            return render_template('profitable_strategy.html',
                                   error=f"Prediction failed: {str(e)}")

    return render_template('profitable_strategy.html')


@app.route('/history')
@login_required
def history():
    """View prediction history"""
    from datetime import datetime, timedelta

    # Calculate date ranges
    now = datetime.now()
    thirty_days_ago = now - timedelta(days=30)

    # Get prediction history
    history_data = db_handler.get_user_history(session['user_id'])

    return render_template('history.html',
                           history=history_data,
                           now=now,
                           thirty_days_ago=thirty_days_ago)

@app.route('/about')
def about():
    """About page"""
    return render_template('about_us.html')

# ============ API ENDPOINTS ============

@app.route('/api/get-districts/<province>')
def get_districts(province):
    """API endpoint to get districts for a province"""
    districts = PROVINCE_DISTRICTS.get(province, {})
    return jsonify({'districts': list(districts.keys())})

@app.route('/api/get-ds-divisions/<province>/<district>')
def get_ds_divisions(province, district):
    """API endpoint to get DS Divisions for a district"""
    districts = PROVINCE_DISTRICTS.get(province, {})
    ds_divisions = districts.get(district, {})
    return jsonify({'ds_divisions': list(ds_divisions.keys())})

@app.route('/api/get-ds-coordinates/<province>/<district>/<ds_division>')
def get_ds_coordinates(province, district, ds_division):
    """API endpoint to get coordinates for a DS Division"""
    districts = PROVINCE_DISTRICTS.get(province, {})
    ds_divisions = districts.get(district, {})
    coords = ds_divisions.get(ds_division)

    if coords:
        return jsonify(coords)
    else:
        # Return default coordinates if not found
        return jsonify({'lat': 7.2906, 'lon': 80.6337})

@app.route('/api/get-items/<category>')
def get_items_by_category(category):
    """API endpoint to get items for a category"""
    category_data = ITEM_DATA.get(category, {})
    return jsonify(category_data)


@app.route('/api/business-predict', methods=['POST'])
@login_required
def api_business_predict():
    """API endpoint for business idea prediction"""
    if business_predictor is None:
        return jsonify({'success': False, 'error': 'Business predictor not initialized'}), 500

    try:
        data = request.get_json()
        result = business_predictor.predict(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"API business prediction error: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 400


@app.route('/api/cultivation-predict', methods=['POST'])
def api_cultivation_predict():
    """API endpoint for cultivation (Component 3) recommendations"""
    try:
        data = request.get_json()
        
        # Validate required fields
        if not data:
            return jsonify({'success': False, 'error': 'No data provided'}), 400
        
        # Call model loader component 3 prediction
        result = model_loader.predict_component3(data)
        
        # Add success flag
        result['success'] = True
        return jsonify(result)
    except Exception as e:
        logger.error(f"API cultivation prediction error: {str(e)}")
        return jsonify({
            'success': False, 
            'error': str(e),
            'recommendations': []
        }), 400


@app.route('/api/market-predict', methods=['POST'])
def api_market_predict():
    """API endpoint for market (Component 2) recommendations"""
    try:
        data = request.get_json()
        
        # Validate required fields
        if not data or not data.get('item'):
            return jsonify({'success': False, 'error': 'Item is required'}), 400
        
        if not data.get('latitude') or not data.get('longitude'):
            return jsonify({'success': False, 'error': 'Location (latitude, longitude) is required'}), 400
        
        # Call model loader component 2 prediction
        result = model_loader.predict_component2(data)
        
        # Add success flag
        result['success'] = True
        return jsonify(result)
    except Exception as e:
        logger.error(f"API market prediction error: {str(e)}")
        return jsonify({
            'success': False, 
            'error': str(e),
            'recommendations': []
        }), 400

@app.route('/api/get-market-coordinates/<market_name>')
def get_market_coordinates(market_name):
    """API endpoint to get coordinates for a market"""
    market_coords = MARKET_COORDINATES.get(market_name)
    if market_coords:
        return jsonify(market_coords)
    else:
        return jsonify({'error': 'Market not found'}), 404

def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in app.config['ALLOWED_EXTENSIONS']

# ============ ERROR HANDLERS ============

@app.errorhandler(404)
def page_not_found(e):
    """Handle 404 errors"""
    return render_template('404.html'), 404

@app.errorhandler(500)
def internal_server_error(e):
    """Handle 500 errors"""
    logger.error(f"Internal server error: {str(e)}")
    return render_template('500.html'), 500

# ============ DATABASE INITIALIZATION ============

def initialize_database():
    """Initialize database with sample data if needed"""
    try:
        # Check if admin user exists
        admin_user = db_handler.get_user_by_email('admin@agrisense.com')
        if not admin_user:
            # Create admin user
            admin_data = {
                'email': 'admin@agrisense.com',
                'username': 'admin',
                'password_hash': generate_password_hash('admin123'),
                'user_type': 'seller',
                'created_at': datetime.now(),
                'last_login': datetime.now(),
                'is_admin': True,
                'preferences': {}
            }
            db_handler.create_user(admin_data)
            logger.info("Admin user created successfully")

        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Database initialization failed: {str(e)}")


@app.route('/api/export-history/csv')
@login_required
def export_history_csv():
    """Export prediction history as CSV"""
    try:
        # Get user's prediction history
        history_data = db_handler.get_user_history(session['user_id'])

        if not history_data:
            return jsonify({'error': 'No prediction history found'}), 404

        # Create CSV content
        import csv
        import io

        output = io.StringIO()
        writer = csv.writer(output)

        # Write header
        writer.writerow(['ID', 'Component', 'Timestamp', 'Input', 'Output', 'Status'])

        # Write data rows
        for pred in history_data:
            writer.writerow([
                pred.get('_id', ''),
                pred.get('component', ''),
                pred.get('timestamp', ''),
                json.dumps(pred.get('input', {}), default=str),
                json.dumps(pred.get('output', {}), default=str),
                'Completed'
            ])

        csv_content = output.getvalue()
        output.close()

        # Create response
        from flask import make_response
        response = make_response(csv_content)
        response.headers['Content-Disposition'] = 'attachment; filename=agrisense_history.csv'
        response.headers['Content-Type'] = 'text/csv'
        return response

    except Exception as e:
        logger.error(f"Error exporting CSV: {str(e)}")
        return jsonify({'error': 'Failed to export data'}), 500


@app.route('/api/export-history/json')
@login_required
def export_history_json():
    """Export prediction history as JSON"""
    try:
        # Get user's prediction history
        history_data = db_handler.get_user_history(session['user_id'])

        if not history_data:
            return jsonify({'error': 'No prediction history found'}), 404

        # Prepare data for JSON export
        export_data = {
            'user_id': session['user_id'],
            'export_date': datetime.now().isoformat(),
            'total_predictions': len(history_data),
            'predictions': history_data
        }

        # Create response
        from flask import make_response
        response = make_response(json.dumps(export_data, default=str, indent=2))
        response.headers['Content-Disposition'] = 'attachment; filename=agrisense_history.json'
        response.headers['Content-Type'] = 'application/json'
        return response

    except Exception as e:
        logger.error(f"Error exporting JSON: {str(e)}")
        return jsonify({'error': 'Failed to export data'}), 500


@app.route('/api/export-history/pdf')
@login_required
def export_history_pdf():
    """Export prediction history as PDF report"""
    try:
        # Get user's prediction history
        history_data = db_handler.get_user_history(session['user_id'])

        if not history_data:
            return jsonify({'error': 'No prediction history found'}), 404

        # Get user info
        user_data = db_handler.get_user_by_id(session['user_id'])

        # Create PDF using reportlab
        try:
            from reportlab.lib.pagesizes import letter
            from reportlab.pdfgen import canvas
            from reportlab.lib import colors
            from reportlab.platypus import Table, TableStyle, Paragraph
            from reportlab.lib.styles import getSampleStyleSheet
            import io

            buffer = io.BytesIO()
            c = canvas.Canvas(buffer, pagesize=letter)
            width, height = letter

            # Title
            c.setFont("Helvetica-Bold", 16)
            c.drawString(50, height - 50, "AgriSense - Prediction History Report")

            # User info
            c.setFont("Helvetica", 10)
            c.drawString(50, height - 80, f"User: {user_data.get('username', 'N/A')}")
            c.drawString(50, height - 95, f"Email: {user_data.get('email', 'N/A')}")
            c.drawString(50, height - 110, f"Report Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            c.drawString(50, height - 125, f"Total Predictions: {len(history_data)}")

            # Summary statistics
            c.setFont("Helvetica-Bold", 12)
            c.drawString(50, height - 150, "Summary Statistics")
            c.setFont("Helvetica", 10)

            stats_y = height - 170
            components = {}
            for pred in history_data:
                comp = pred.get('component', 'unknown')
                components[comp] = components.get(comp, 0) + 1

            for comp, count in components.items():
                c.drawString(50, stats_y, f"{comp.replace('_', ' ').title()}: {count}")
                stats_y -= 15

            # Recent predictions table
            c.setFont("Helvetica-Bold", 12)
            c.drawString(50, stats_y - 30, "Recent Predictions")

            # Simple table data
            table_data = [['Date', 'Component', 'Item', 'Result']]
            for pred in history_data[:10]:  # Show last 10 predictions
                timestamp = pred.get('timestamp', '')
                if isinstance(timestamp, str):
                    date_str = timestamp[:10]
                else:
                    date_str = timestamp.strftime('%Y-%m-%d') if hasattr(timestamp, 'strftime') else str(timestamp)[:10]

                component = pred.get('component', '').replace('_', ' ').title()

                # Get item/result info
                item = 'N/A'
                result = 'N/A'

                if pred.get('component') == 'price_demand':
                    item = pred.get('input', {}).get('item_standard', 'N/A')
                    result = f"Rs. {pred.get('output', {}).get('predicted_price', 'N/A')}"
                elif pred.get('component') == 'market_ranking':
                    item = pred.get('input', {}).get('item', 'N/A')
                    result = pred.get('output', {}).get('best_market', 'N/A')
                elif pred.get('component') == 'cultivation_targeting':
                    item = pred.get('output', {}).get('best_crop', 'N/A')
                    result = f"{pred.get('output', {}).get('success_probability', 'N/A')}%"
                elif pred.get('component') == 'yield_quality':
                    item = 'Image Analysis'
                    result = f"{pred.get('output', {}).get('predicted_class', 'N/A')} - {pred.get('output', {}).get('grade', 'N/A')}"

                table_data.append([date_str, component, item, result])

            # Create simple table
            table_y = stats_y - 100

            # Draw table manually
            col_widths = [80, 100, 120, 150]
            row_height = 20

            for i, row in enumerate(table_data):
                y_pos = table_y - (i * row_height)

                # Header row
                if i == 0:
                    c.setFont("Helvetica-Bold", 10)
                else:
                    c.setFont("Helvetica", 9)

                x_pos = 50
                for j, cell in enumerate(row):
                    c.drawString(x_pos, y_pos, str(cell)[:30])  # Limit cell width
                    x_pos += col_widths[j]

            # Footer
            c.setFont("Helvetica-Oblique", 8)
            c.drawString(50, 50, "Generated by AgriSense - Intelligent Agricultural Decision Support System")

            c.showPage()
            c.save()

            buffer.seek(0)

            # Create response
            from flask import make_response
            response = make_response(buffer.getvalue())
            response.headers['Content-Disposition'] = 'attachment; filename=agrisense_report.pdf'
            response.headers['Content-Type'] = 'application/pdf'
            return response

        except ImportError:
            # If reportlab is not installed, provide a simplified text version
            import io

            buffer = io.BytesIO()
            content = f"""AgriSense - Prediction History Report
===============================

User: {user_data.get('username', 'N/A')}
Email: {user_data.get('email', 'N/A')}
Report Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
Total Predictions: {len(history_data)}

Summary Statistics:
{'-' * 20}
"""

            components = {}
            for pred in history_data:
                comp = pred.get('component', 'unknown')
                components[comp] = components.get(comp, 0) + 1

            for comp, count in components.items():
                content += f"{comp.replace('_', ' ').title()}: {count}\n"

            content += "\nRecent Predictions:\n"
            content += "-" * 20 + "\n"

            for pred in history_data[:10]:
                timestamp = pred.get('timestamp', '')
                if isinstance(timestamp, str):
                    date_str = timestamp[:10]
                else:
                    date_str = timestamp.strftime('%Y-%m-%d') if hasattr(timestamp, 'strftime') else str(timestamp)[:10]

                component = pred.get('component', '').replace('_', ' ').title()
                content += f"{date_str} | {component}\n"

            content += "\nGenerated by AgriSense"
            buffer.write(content.encode('utf-8'))
            buffer.seek(0)

            from flask import make_response
            response = make_response(buffer.getvalue())
            response.headers['Content-Disposition'] = 'attachment; filename=agrisense_report.txt'
            response.headers['Content-Type'] = 'text/plain'
            return response

    except Exception as e:
        logger.error(f"Error exporting PDF: {str(e)}")
        return jsonify({'error': 'Failed to generate PDF report'}), 500


@app.route('/api/prediction-details/<prediction_id>')
@login_required
def get_prediction_details(prediction_id):
    """Get detailed information for a specific prediction"""
    try:
        from bson import ObjectId
        prediction = db_handler.predictions.find_one({
            '_id': ObjectId(prediction_id),
            'user_id': ObjectId(session['user_id'])
        })

        if not prediction:
            return jsonify({'success': False, 'message': 'Prediction not found'}), 404

        # Convert ObjectId to string
        prediction['_id'] = str(prediction['_id'])
        if 'user_id' in prediction:
            prediction['user_id'] = str(prediction['user_id'])

        return jsonify({
            'success': True,
            'data': prediction
        })

    except Exception as e:
        logger.error(f"Error getting prediction details: {str(e)}")
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/delete-prediction/<prediction_id>', methods=['DELETE'])
@login_required
def delete_prediction(prediction_id):
    """Delete a specific prediction"""
    try:
        from bson import ObjectId

        # Delete from predictions collection
        result = db_handler.predictions.delete_one({
            '_id': ObjectId(prediction_id),
            'user_id': ObjectId(session['user_id'])
        })

        if result.deleted_count == 0:
            return jsonify({'success': False, 'message': 'Prediction not found or access denied'}), 404

        # Remove from user's history array
        db_handler.users.update_one(
            {'_id': ObjectId(session['user_id'])},
            {'$pull': {'history': prediction_id}}
        )

        return jsonify({
            'success': True,
            'message': 'Prediction deleted successfully'
        })

    except Exception as e:
        logger.error(f"Error deleting prediction: {str(e)}")
        return jsonify({'success': False, 'message': str(e)}), 500

if __name__ == '__main__':
    # Initialize database
    initialize_database()

    # Load models
    try:
        model_loader.load_all_models()
        logger.info("All models loaded successfully")
    except Exception as e:
        logger.error(f"Model loading failed: {str(e)}")

    # Run application
    app.run(host='0.0.0.0', port=5001, debug=True)
