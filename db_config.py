"""
MongoDB Configuration and Operations for AgriSense
"""

import os
import logging
import json
from datetime import datetime, timedelta
from bson import ObjectId, json_util
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure

# Configure logging
logger = logging.getLogger(__name__)

class MongoDBHandler:
    def __init__(self, db_name='AgriSense'):
        """Initialize MongoDB connection"""
        try:
            # MongoDB connection string
            mongodb_uri = os.getenv('MONGODB_URI', 'mongodb://localhost:27017/')
            database_name = os.getenv('MONGODB_DB', db_name)

            # Initialize client
            self.client = MongoClient(mongodb_uri)
            self.db = self.client[database_name]

            # Initialize collections
            self.users = self.db.users
            self.predictions = self.db.predictions
            self.market_data = self.db.market_data
            self.cultivation_history = self.db.cultivation_history
            self.image_predictions = self.db.image_predictions
            self.system_logs = self.db.system_logs
            self.models = self.db.models

            # Test connection
            self.client.admin.command('ping')
            logger.info(f"MongoDB connection established successfully to database: {database_name}")

        except ConnectionFailure as e:
            logger.error(f"Failed to connect to MongoDB: {str(e)}")
            raise

    def initialize_database(self):
        """Create collections and indexes if they don't exist"""
        try:
            collections = [
                'users',
                'predictions',
                'market_data',
                'cultivation_history',
                'image_predictions',
                'system_logs',
                'models'
            ]

            created_collections = []
            for collection_name in collections:
                if collection_name not in self.db.list_collection_names():
                    self.db.create_collection(collection_name)
                    created_collections.append(collection_name)
                    logger.info(f"Created collection: {collection_name}")

            # Create indexes for better performance
            indexes_config = [
                # Users collection
                (self.users, [('email', 1)], {'unique': True}),
                (self.users, [('username', 1)], {'unique': True}),

                # Predictions collection
                (self.predictions, [('timestamp', -1)], {}),
                (self.predictions, [('user_id', 1)], {}),
                (self.predictions, [('user_id', 1), ('timestamp', -1)], {}),
                (self.predictions, [('component', 1)], {}),

                # Market data collection
                (self.market_data, [('market', 1), ('item', 1)], {}),
                (self.market_data, [('market', 1), ('item', 1), ('date', -1)], {}),

                # Cultivation history
                (self.cultivation_history, [('user_id', 1)], {}),
                (self.cultivation_history, [('crop', 1)], {}),

                # Image predictions
                (self.image_predictions, [('user_id', 1)], {}),
                (self.image_predictions, [('timestamp', -1)], {}),

                # System logs
                (self.system_logs, [('timestamp', -1)], {}),
                (self.system_logs, [('event_type', 1)], {}),

                # Models
                (self.models, [('type', 1), ('created_at', -1)], {}),
            ]

            for collection, keys, options in indexes_config:
                try:
                    collection.create_index(keys, **options)
                except Exception as e:
                    logger.warning(f"Could not create index on {collection.name}: {str(e)}")

            logger.info("Database initialized successfully")
            return {
                'created_collections': created_collections,
                'total_collections': len(self.db.list_collection_names())
            }

        except Exception as e:
            logger.error(f"Error initializing database: {str(e)}")
            return {'error': str(e)}

    # ============ USER MANAGEMENT METHODS ============

    def create_user(self, user_data):
        """Create a new user in the database"""
        try:
            # Ensure email is lowercase
            if 'email' in user_data:
                user_data['email'] = user_data['email'].lower()

            # Set creation timestamp
            if 'created_at' not in user_data:
                user_data['created_at'] = datetime.now()

            if 'last_login' not in user_data:
                user_data['last_login'] = datetime.now()

            # Initialize history array
            if 'history' not in user_data:
                user_data['history'] = []

            # Insert user
            result = self.users.insert_one(user_data)
            user_id = str(result.inserted_id)

            logger.info(f"User created successfully: {user_id}")
            return user_id
        except Exception as e:
            logger.error(f"Error creating user: {str(e)}")
            return None

    def get_user_by_email(self, email):
        """Get user by email"""
        try:
            if not email:
                return None
            return self.users.find_one({'email': email.lower()})
        except Exception as e:
            logger.error(f"Error getting user by email: {str(e)}")
            return None

    def get_user_by_username(self, username):
        """Get user by username"""
        try:
            if not username:
                return None
            return self.users.find_one({'username': username})
        except Exception as e:
            logger.error(f"Error getting user by username: {str(e)}")
            return None

    def get_user_by_id(self, user_id):
        """Get user by ID"""
        try:
            if not user_id:
                return None
            return self.users.find_one({'_id': ObjectId(user_id)})
        except Exception as e:
            logger.error(f"Error getting user by ID: {str(e)}")
            return None

    def update_user_login(self, user_id):
        """Update user's last login timestamp"""
        try:
            if not user_id:
                return False
            self.users.update_one(
                {'_id': ObjectId(user_id)},
                {'$set': {'last_login': datetime.now()}}
            )
            return True
        except Exception as e:
            logger.error(f"Error updating user login: {str(e)}")
            return False

    def update_user_profile(self, user_id, **kwargs):
        """Update user profile information"""
        try:
            if not user_id or not kwargs:
                return False

            update_data = {}
            if 'username' in kwargs:
                update_data['username'] = kwargs['username']
            if 'user_type' in kwargs:
                update_data['user_type'] = kwargs['user_type']
            if 'preferences' in kwargs:
                update_data['preferences'] = kwargs['preferences']
            if 'profile_photo' in kwargs:
                update_data['profile_photo'] = kwargs['profile_photo']
            if 'profile_photo_data' in kwargs:
                update_data['profile_photo_data'] = kwargs['profile_photo_data']
            if 'profile_photo_type' in kwargs:
                update_data['profile_photo_type'] = kwargs['profile_photo_type']

            if update_data:
                self.users.update_one(
                    {'_id': ObjectId(user_id)},
                    {'$set': update_data}
                )
                logger.info(f"User profile updated: {user_id}")
                return True
            return False
        except Exception as e:
            logger.error(f"Error updating user profile: {str(e)}")
            return False

    # ============ PREDICTION HISTORY METHODS ============

    def save_prediction(self, prediction_data):
        """Save prediction to history"""
        try:
            # Ensure user_id is ObjectId if it exists
            if 'user_id' in prediction_data and prediction_data['user_id']:
                if isinstance(prediction_data['user_id'], str) and prediction_data['user_id'] != 'anonymous':
                    try:
                        prediction_data['user_id'] = ObjectId(prediction_data['user_id'])
                    except:
                        pass
                elif prediction_data['user_id'] == 'anonymous':
                    # Handle anonymous predictions
                    prediction_data['user_id'] = None

            # Ensure timestamp is datetime
            if 'timestamp' not in prediction_data:
                prediction_data['timestamp'] = datetime.now()

            # Insert prediction
            result = self.predictions.insert_one(prediction_data)
            prediction_id = str(result.inserted_id)

            # Also add reference to user's history if user_id exists
            if 'user_id' in prediction_data and prediction_data['user_id']:
                self.users.update_one(
                    {'_id': ObjectId(prediction_data['user_id'])},
                    {'$push': {'history': prediction_id}}
                )

            logger.info(f"Prediction saved: {prediction_id}")
            return prediction_id

        except Exception as e:
            logger.error(f"Error saving prediction: {str(e)}")
            return None

    def get_user_history(self, user_id, limit=50):
        """Get prediction history for a user"""
        try:
            if not user_id or user_id == 'anonymous':
                return []

            # Convert user_id to ObjectId
            user_oid = ObjectId(user_id)

            # Get all predictions for this user
            predictions = list(self.predictions.find(
                {'user_id': user_oid}
            ).sort('timestamp', -1).limit(limit))

            # Convert ObjectId to string for JSON serialization
            for pred in predictions:
                pred['_id'] = str(pred['_id'])
                if 'user_id' in pred:
                    pred['user_id'] = str(pred['user_id'])

            return predictions
        except Exception as e:
            logger.error(f"Error getting user history: {str(e)}")
            return []

    def get_all_predictions(self, limit=100):
        """Get all predictions (admin function)"""
        try:
            predictions = list(self.predictions.find().sort('timestamp', -1).limit(limit))

            # Convert ObjectId to string
            for pred in predictions:
                pred['_id'] = str(pred['_id'])
                if 'user_id' in pred and pred['user_id']:
                    pred['user_id'] = str(pred['user_id'])

            return predictions
        except Exception as e:
            logger.error(f"Error getting all predictions: {str(e)}")
            return []

    # ============ MARKET DATA METHODS ============

    def save_market_data(self, market_data):
        """Save market data entry"""
        try:
            # Ensure date is datetime
            if 'date' in market_data and isinstance(market_data['date'], str):
                try:
                    market_data['date'] = datetime.fromisoformat(market_data['date'].replace('Z', '+00:00'))
                except:
                    market_data['date'] = datetime.now()
            elif 'date' not in market_data:
                market_data['date'] = datetime.now()

            result = self.market_data.insert_one(market_data)
            market_data_id = str(result.inserted_id)

            logger.info(f"Market data saved: {market_data_id}")
            return market_data_id
        except Exception as e:
            logger.error(f"Error saving market data: {str(e)}")
            return None

    def get_market_data(self, market=None, item=None, start_date=None, end_date=None, limit=100):
        """Get market data with optional filters"""
        try:
            query = {}
            if market:
                query['market'] = market
            if item:
                query['item'] = item
            if start_date and end_date:
                if isinstance(start_date, str):
                    start_date = datetime.fromisoformat(start_date)
                if isinstance(end_date, str):
                    end_date = datetime.fromisoformat(end_date)
                query['date'] = {'$gte': start_date, '$lte': end_date}

            data = list(self.market_data.find(query).sort('date', -1).limit(limit))

            # Convert ObjectId to string
            for entry in data:
                entry['_id'] = str(entry['_id'])

            return data
        except Exception as e:
            logger.error(f"Error getting market data: {str(e)}")
            return []

    def get_latest_market_price(self, market, item):
        """Get latest price for a specific item in a market"""
        try:
            data = self.market_data.find_one(
                {'market': market, 'item': item},
                sort=[('date', -1)]
            )
            return data.get('price') if data else None
        except Exception as e:
            logger.error(f"Error getting latest market price: {str(e)}")
            return None

    # ============ CULTIVATION DATA METHODS ============

    def save_cultivation_plan(self, plan_data):
        """Save cultivation plan"""
        try:
            # Ensure timestamp
            if 'timestamp' not in plan_data:
                plan_data['timestamp'] = datetime.now()

            result = self.cultivation_history.insert_one(plan_data)
            plan_id = str(result.inserted_id)

            logger.info(f"Cultivation plan saved: {plan_id}")
            return plan_id
        except Exception as e:
            logger.error(f"Error saving cultivation plan: {str(e)}")
            return None

    def get_cultivation_data(self, user_id=None, crop=None, limit=100):
        """Get cultivation data with optional filters"""
        try:
            query = {}
            if user_id:
                query['user_id'] = ObjectId(user_id)
            if crop:
                query['crop'] = crop

            data = list(self.cultivation_history.find(query).sort('timestamp', -1).limit(limit))

            # Convert ObjectId to string
            for entry in data:
                entry['_id'] = str(entry['_id'])
                if 'user_id' in entry:
                    entry['user_id'] = str(entry['user_id'])

            return data
        except Exception as e:
            logger.error(f"Error getting cultivation data: {str(e)}")
            return []

    # ============ IMAGE PREDICTION METHODS ============

    def save_image_prediction(self, image_data):
        """Save image prediction results"""
        try:
            # Ensure timestamp
            if 'timestamp' not in image_data:
                image_data['timestamp'] = datetime.now()

            result = self.image_predictions.insert_one(image_data)
            image_id = str(result.inserted_id)

            logger.info(f"Image prediction saved: {image_id}")
            return image_id
        except Exception as e:
            logger.error(f"Error saving image prediction: {str(e)}")
            return None

    def get_image_predictions(self, user_id=None, limit=50):
        """Get image prediction history"""
        try:
            query = {}
            if user_id:
                query['user_id'] = ObjectId(user_id)

            data = list(self.image_predictions.find(query).sort('timestamp', -1).limit(limit))

            # Convert ObjectId to string
            for entry in data:
                entry['_id'] = str(entry['_id'])
                if 'user_id' in entry:
                    entry['user_id'] = str(entry['user_id'])

            return data
        except Exception as e:
            logger.error(f"Error getting image predictions: {str(e)}")
            return []

    # ============ SYSTEM LOGGING METHODS ============

    def log_system_event(self, event_type, message, user_id=None, metadata=None):
        """Log system events"""
        log_entry = {
            'event_type': event_type,
            'message': message,
            'user_id': user_id,
            'metadata': metadata or {},
            'timestamp': datetime.now()
        }

        try:
            self.system_logs.insert_one(log_entry)
            logger.info(f"System event logged: {event_type} - {message}")
        except Exception as e:
            logger.error(f"Error logging event: {e}")

    def get_system_logs(self, event_type=None, user_id=None, limit=100):
        """Get system logs with filters"""
        try:
            query = {}
            if event_type:
                query['event_type'] = event_type
            if user_id:
                query['user_id'] = user_id

            logs = list(self.system_logs.find(query).sort('timestamp', -1).limit(limit))

            # Convert ObjectId to string
            for log in logs:
                log['_id'] = str(log['_id'])

            return logs
        except Exception as e:
            logger.error(f"Error getting system logs: {str(e)}")
            return []

    # ============ MODEL MANAGEMENT METHODS ============

    def save_model_metadata(self, model_data):
        """Save model metadata"""
        try:
            # Ensure timestamp
            if 'created_at' not in model_data:
                model_data['created_at'] = datetime.now()

            result = self.models.insert_one(model_data)
            model_id = str(result.inserted_id)

            logger.info(f"Model metadata saved: {model_id}")
            return model_id
        except Exception as e:
            logger.error(f"Error saving model metadata: {str(e)}")
            return None

    def get_latest_model(self, model_type):
        """Get latest model metadata by type"""
        try:
            model = self.models.find_one(
                {'type': model_type},
                sort=[('created_at', -1)]
            )

            if model:
                model['_id'] = str(model['_id'])

            return model
        except Exception as e:
            logger.error(f"Error getting latest model: {str(e)}")
            return None

    def get_all_models(self):
        """Get all model metadata"""
        try:
            models = list(self.models.find().sort('created_at', -1))

            for model in models:
                model['_id'] = str(model['_id'])

            return models
        except Exception as e:
            logger.error(f"Error getting all models: {str(e)}")
            return []

    # ============ STATISTICS METHODS ============

    def get_user_statistics(self, user_id):
        """Get statistics for a user"""
        try:
            if not user_id:
                return {'total_predictions': 0, 'by_component': {}}

            user_oid = ObjectId(user_id)

            # Count predictions by component
            pipeline = [
                {'$match': {'user_id': user_oid}},
                {'$group': {
                    '_id': '$component',
                    'count': {'$sum': 1},
                    'last_used': {'$max': '$timestamp'}
                }}
            ]

            stats = list(self.predictions.aggregate(pipeline))

            # Format results
            formatted_stats = {}
            for stat in stats:
                component = stat['_id']
                formatted_stats[component] = {
                    'count': stat['count'],
                    'last_used': stat['last_used']
                }

            # Get total prediction count
            total_count = self.predictions.count_documents({'user_id': user_oid})

            return {
                'total_predictions': total_count,
                'by_component': formatted_stats
            }
        except Exception as e:
            logger.error(f"Error getting user statistics: {str(e)}")
            return {'total_predictions': 0, 'by_component': {}}

    def get_system_statistics(self):
        """Get overall system statistics"""
        try:
            total_users = self.users.count_documents({})
            total_predictions = self.predictions.count_documents({})
            total_market_data = self.market_data.count_documents({})

            # Get predictions by component
            pipeline = [
                {'$group': {
                    '_id': '$component',
                    'count': {'$sum': 1}
                }}
            ]

            component_stats = list(self.predictions.aggregate(pipeline))

            return {
                'total_users': total_users,
                'total_predictions': total_predictions,
                'total_market_data': total_market_data,
                'component_stats': component_stats
            }
        except Exception as e:
            logger.error(f"Error getting system statistics: {str(e)}")
            return {
                'total_users': 0,
                'total_predictions': 0,
                'total_market_data': 0,
                'component_stats': []
            }

    # ============ UTILITY METHODS ============

    def get_collection_stats(self):
        """Get statistics for all collections"""
        stats = {}
        for collection_name in self.db.list_collection_names():
            collection = self.db[collection_name]
            stats[collection_name] = {
                'count': collection.count_documents({}),
                'indexes': list(collection.index_information().keys())
            }
        return stats

    def cleanup_old_predictions(self, days_old=90):
        """Clean up predictions older than specified days"""
        try:
            cutoff_date = datetime.now() - timedelta(days=days_old)
            result = self.predictions.delete_many(
                {'timestamp': {'$lt': cutoff_date}}
            )

            logger.info(f"Cleaned up {result.deleted_count} old predictions")
            return result.deleted_count
        except Exception as e:
            logger.error(f"Error cleaning up old predictions: {str(e)}")
            return 0

    def backup_database(self, backup_path='backups/'):
        """Create a database backup"""
        try:
            os.makedirs(backup_path, exist_ok=True)
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')

            # Backup each collection
            collections_to_backup = [
                'users', 'predictions', 'market_data', 'cultivation_history',
                'image_predictions', 'system_logs', 'models'
            ]

            for collection_name in collections_to_backup:
                if collection_name in self.db.list_collection_names():
                    collection = self.db[collection_name]
                    data = list(collection.find({}))

                    # Convert ObjectId to string
                    for item in data:
                        item['_id'] = str(item['_id'])

                    # Save to JSON file
                    backup_file = os.path.join(backup_path, f'{collection_name}_{timestamp}.json')
                    with open(backup_file, 'w') as f:
                        json.dump(data, f, default=str, indent=2)

            logger.info(f"Database backup created: {backup_path}")
            return True
        except Exception as e:
            logger.error(f"Error creating database backup: {str(e)}")
            return False

    def ping(self):
        """Check if database connection is alive"""
        try:
            self.client.admin.command('ping')
            return True
        except Exception as e:
            logger.error(f"Database ping failed: {str(e)}")
            return False

    def close_connection(self):
        """Close database connection"""
        try:
            self.client.close()
            logger.info("MongoDB connection closed")
        except Exception as e:
            logger.error(f"Error closing connection: {str(e)}")

# Global database handler instance
db_handler = MongoDBHandler()

# Ensure database is initialized when module is imported
if __name__ == "__main__":
    try:
        result = db_handler.initialize_database()
        logger.info(f"Database initialized successfully: {result}")

        # Print collection statistics
        stats = db_handler.get_collection_stats()
        logger.info(f"Collection statistics: {json.dumps(stats, indent=2)}")

    except Exception as e:
        logger.error(f"Failed to initialize database: {str(e)}")