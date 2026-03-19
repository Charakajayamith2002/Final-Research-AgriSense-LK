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
CORS(app)

# Configuration
app.config['UPLOAD_FOLDER'] = 'static/uploads'
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size
app.config['ALLOWED_EXTENSIONS'] = {'png', 'jpg', 'jpeg', 'bmp', 'gif', 'tiff', 'webp'}

# Ensure upload directories exist
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
os.makedirs('static/history', exist_ok=True)

# Initialize components
db_handler = MongoDBHandler()
model_loader = ModelLoader()

# Authentication and Authorization Decorator
def login_required(f):
    """Decorator to require login for protected routes"""
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash('Please login to access this page', 'warning')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    decorated_function.__name__ = f.__name__
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

# Market coordinates for Component 2
MARKET_COORDINATES = {
    'Pettah': {'lat': 6.9341, 'lon': 79.9861},
    'Dambulla': {'lat': 7.8643, 'lon': 80.6501},
    'Narahenpita': {'lat': 6.9300, 'lon': 79.9681},
    'Marandagahamula': {'lat': 7.2903, 'lon': 80.5327},
    'Peliyagoda': {'lat': 6.9682, 'lon': 79.9815},
    'Negombo': {'lat': 7.2085, 'lon': 79.9743}
}

# Item data based on categories
ITEM_DATA = {
    'Vegetables': {
        'local': ['Beans', 'Carrot', 'Cabbage', 'Tomato', 'Brinjal', 'Pumpkin', 'Snake gourd', 'Green Chilli', 'Lime'],
        'markets': {
            'Wholesale': ['Pettah', 'Dambulla'],
            'Retail': ['Pettah', 'Dambulla', 'Narahenpita']
        }
    },
    'Fruits': {
        'local': ['Banana - Sour', 'Papaw', 'Pineapple'],
        'imported': ['Apple', 'Orange'],
        'markets': {
            'Wholesale': ['Pettah', 'Marandagahamula'],
            'Retail': ['Pettah', 'Dambulla', 'Narahenpita']
        }
    },
    'Rice': {
        'local': ['Samba', 'Nadu', 'Kekulu (White)', 'Kekulu (Red)'],
        'imported': ['Ponni Samba', 'Nadu', 'Kekulu (White)'],
        'markets': {
            'Wholesale': ['Pettah', 'Marandagahamula'],
            'Retail': ['Pettah', 'Dambulla', 'Narahenpita']
        }
    },
    'Other': {
        'local': ['Big Onion', 'Potato', 'Coconut', 'Coconut oil', 'Sugar -White', 'Egg - White'],
        'imported': ['Red Onion', 'Big Onion', 'Potato', 'Dried Chilli', 'Red Dhal', 'Katta', 'Sprat'],
        'markets': {
            'Wholesale': ['Pettah', 'Dambulla'],
            'Retail': ['Pettah', 'Dambulla', 'Narahenpita']
        }
    },
    'Fish': {
        'local': ['Kelawalla', 'Thalapath', 'Balaya', 'Paraw', 'Salaya', 'Hurulla', 'Linna'],
        'markets': {
            'Wholesale': ['Peliyagoda', 'Negombo'],
            'Retail': ['Pettah', 'Negombo', 'Narahenpita']
        }
    }
}

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
                'cultivation_cost': cultivation_cost
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

@app.route('/yield-quality', methods=['GET', 'POST'])
@login_required
def yield_quality():
    """Component 4: Yield Quality Scaling with Multi-Task Model (Class + Grade)"""
    if request.method == 'POST':
        try:
            # Check if file was uploaded
            if 'image' not in request.files:
                return render_template('yield_quality_scaling.html',
                                       error='No image file uploaded')

            file = request.files['image']

            if file.filename == '':
                return render_template('yield_quality_scaling.html',
                                       error='No image selected')

            if file and allowed_file(file.filename):
                # Save uploaded file
                filename = f"{datetime.now().strftime('%Y%m%d_%H%M%S')}_{secure_filename(file.filename)}"
                filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                file.save(filepath)

                # Get prediction from multi-task model (class + grade)
                try:
                    prediction = model_loader.predict_component4(filepath)
                except Exception as model_error:
                    print(f"Model prediction error: {model_error}")
                    # Fallback to intelligent prediction
                    prediction = model_loader._create_intelligent_multitask_prediction(filepath)

                # Add image URL for display
                prediction['image_url'] = url_for('static', filename=f'uploads/{filename}')
                prediction['upload_time'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

                # Format the display result for the template
                # The template expects both old and new fields for compatibility
                if 'grade' in prediction:
                    # This is the new multi-task model output
                    prediction['predicted_class'] = prediction.get('predicted_class', 'Unknown')
                    prediction['quality'] = 'Quality' if prediction.get('grade') == 'Grade_A' else 'Low'
                    prediction['confidence'] = prediction.get('class_confidence', 0.5)

                    # Ensure top_3_predictions is in the format template expects
                    if 'top_3_predictions' not in prediction and 'top_3_classes' in prediction:
                        prediction['top_3_predictions'] = prediction['top_3_classes']

                    # Create display text
                    prediction['display_text'] = f"{prediction['predicted_class']} - {prediction.get('grade', 'Unknown')}"
                else:
                    # This is the old model output - ensure compatibility
                    prediction['grade'] = 'Grade_A' if prediction.get('quality') == 'Quality' else 'Grade_B'
                    prediction['class_confidence'] = prediction.get('confidence', 0.5)
                    prediction['grade_confidence'] = 0.85  # Default for backward compatibility
                    prediction['all_class_probabilities'] = prediction.get('all_predictions', {})
                    prediction['all_grade_probabilities'] = {'Grade_A': 0.85, 'Grade_B': 0.15}  # Default

                # Save to history
                history_data = {
                    'component': 'yield_quality',
                    'input': {'filename': filename},
                    'output': prediction,
                    'timestamp': datetime.now(),
                    'user_id': session.get('user_id')
                }
                db_handler.save_prediction(history_data)

                return render_template('yield_quality_scaling.html',
                                       prediction=prediction,
                                       image_url=prediction['image_url'])

        except Exception as e:
            logger.error(f"Yield quality prediction error: {str(e)}")
            import traceback
            traceback.print_exc()
            return render_template('yield_quality_scaling.html',
                                   error=str(e))

    return render_template('yield_quality_scaling.html')


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
            numeric_fields = ['monthly_income', 'family_members', 'children_under_16',
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