import logging
import os

# Ensure the log directory exists
LOG_DIR = os.path.join(os.path.dirname(__file__), '../../frontend/app')
LOG_PATH = os.path.abspath(os.path.join(LOG_DIR, 'wishful_backend.log'))
os.makedirs(LOG_DIR, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(name)s %(message)s',
    handlers=[
        logging.FileHandler(LOG_PATH),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger('wishful_backend')
