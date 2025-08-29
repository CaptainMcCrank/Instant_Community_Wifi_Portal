#!/usr/bin/env python3
"""
Selfie Portal Flask Application
A mobile-friendly selfie sharing portal for the Instant Community WiFi Portal
"""

import os
import json
import uuid
import time
import logging
from datetime import datetime, timedelta
from flask import Flask, render_template, request, jsonify, send_from_directory, redirect, url_for
from werkzeug.utils import secure_filename
from werkzeug.exceptions import RequestEntityTooLarge
import hashlib

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
app.logger.setLevel(logging.INFO)

# Configuration
app.config['MAX_CONTENT_LENGTH'] = 10 * 1024 * 1024  # 10MB max file size
app.config['UPLOAD_FOLDER'] = 'data/uploads'
app.config['ALLOWED_EXTENSIONS'] = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
app.config['INDEX_FILE'] = 'data/index.json'
app.config['MAX_SELFIES'] = 100  # Maximum number of selfies to keep
app.config['CLEANUP_DAYS'] = 30  # Days to keep selfies
app.config['STATIC_FOLDER'] = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'static')

# Ensure directories exist
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
os.makedirs('data', exist_ok=True)

def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in app.config['ALLOWED_EXTENSIONS']

def load_index():
    """Load the selfie index from JSON file"""
    try:
        if os.path.exists(app.config['INDEX_FILE']):
            with open(app.config['INDEX_FILE'], 'r') as f:
                return json.load(f)
    except (json.JSONDecodeError, IOError):
        pass
    return []

def save_index(index_data):
    """Save the selfie index to JSON file"""
    try:
        with open(app.config['INDEX_FILE'], 'w') as f:
            json.dump(index_data, f, indent=2)
    except IOError as e:
        print(f"Error saving index: {e}")

def cleanup_old_selfies():
    """Remove selfies older than CLEANUP_DAYS"""
    cutoff_date = datetime.now() - timedelta(days=app.config['CLEANUP_DAYS'])
    index_data = load_index()
    updated_index = []
    
    for selfie in index_data:
        try:
            selfie_date = datetime.fromisoformat(selfie['timestamp'])
            if selfie_date > cutoff_date:
                updated_index.append(selfie)
            else:
                # Remove old file
                file_path = os.path.join(app.config['UPLOAD_FOLDER'], selfie['filename'])
                if os.path.exists(file_path):
                    os.remove(file_path)
        except (ValueError, KeyError):
            continue
    
    if len(updated_index) != len(index_data):
        save_index(updated_index)

def get_client_ip():
    """Get client IP address"""
    if request.headers.get('X-Forwarded-For'):
        return request.headers.get('X-Forwarded-For').split(',')[0]
    return request.remote_addr

@app.route('/')
@app.route('/selfies/')
@app.route('/selfies')
def index():
    """Main selfie portal page"""
    cleanup_old_selfies()
    index_data = load_index()
    # Sort by timestamp, newest first
    index_data.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
    return render_template('index.html', selfies=index_data[:20])  # Show last 20

@app.route('/upload', methods=['POST'])
@app.route('/selfies/upload', methods=['POST'])
def upload_selfie():
    """Handle selfie upload"""
    try:
        # Check if file was uploaded
        if 'selfie' not in request.files:
            return jsonify({'error': 'No file uploaded'}), 400
        
        file = request.files['selfie']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        if not allowed_file(file.filename):
            return jsonify({'error': 'Invalid file type'}), 400
        
        # Generate unique filename
        timestamp = datetime.now().isoformat()
        file_ext = file.filename.rsplit('.', 1)[1].lower()
        unique_id = str(uuid.uuid4())[:8]
        filename = f"selfie_{timestamp[:10]}_{unique_id}.{file_ext}"
        
        # Save file
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(file_path)
        
        # Get file size
        file_size = os.path.getsize(file_path)
        
        # Create metadata
        selfie_data = {
            'id': unique_id,
            'filename': filename,
            'timestamp': timestamp,
            'caption': request.form.get('caption', ''),
            'ip_address': get_client_ip(),
            'file_size': file_size
        }
        
        # Update index
        index_data = load_index()
        index_data.append(selfie_data)
        
        # Keep only the most recent MAX_SELFIES
        if len(index_data) > app.config['MAX_SELFIES']:
            index_data = index_data[-app.config['MAX_SELFIES']:]
        
        save_index(index_data)
        
        return jsonify({
            'success': True,
            'id': unique_id,
            'filename': filename,
            'timestamp': timestamp
        })
        
    except RequestEntityTooLarge:
        return jsonify({'error': 'File too large'}), 413
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/view/<selfie_id>')
@app.route('/selfies/view/<selfie_id>')
def view_selfie(selfie_id):
    """View individual selfie"""
    index_data = load_index()
    selfie = next((s for s in index_data if s.get('id') == selfie_id), None)
    
    if not selfie:
        return redirect(url_for('index'))
    
    return render_template('view.html', selfie=selfie)

@app.route('/data/uploads/<filename>')
@app.route('/selfies/data/uploads/<filename>')
def uploaded_file(filename):
    """Serve uploaded files"""
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

@app.route('/static/<filename>')
@app.route('/selfies/static/<filename>')
def static_file(filename):
    """Serve static files (CSS, JS)"""
    try:
        # Check if file exists
        file_path = os.path.join(app.config['STATIC_FOLDER'], filename)
        if not os.path.exists(file_path):
            app.logger.error(f"Static file not found: {file_path}")
            return "File not found", 404
        
        # Check if it's a file (not directory)
        if not os.path.isfile(file_path):
            app.logger.error(f"Static file is not a file: {file_path}")
            return "Not a file", 400
            
        return send_from_directory(app.config['STATIC_FOLDER'], filename)
    except Exception as e:
        app.logger.error(f"Error serving static file {filename}: {str(e)}")
        return f"Error serving file: {str(e)}", 500

@app.route('/api/selfies')
@app.route('/selfies/api/selfies')
def api_selfies():
    """API endpoint to get recent selfies"""
    cleanup_old_selfies()
    index_data = load_index()
    index_data.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
    return jsonify(index_data[:20])

@app.route('/delete/<selfie_id>', methods=['POST'])
@app.route('/selfies/delete/<selfie_id>', methods=['POST'])
def delete_selfie(selfie_id):
    """Delete a selfie (admin function)"""
    index_data = load_index()
    selfie = next((s for s in index_data if s.get('id') == selfie_id), None)
    
    if not selfie:
        return jsonify({'error': 'Selfie not found'}), 404
    
    # Remove file
    file_path = os.path.join(app.config['UPLOAD_FOLDER'], selfie['filename'])
    if os.path.exists(file_path):
        os.remove(file_path)
    
    # Remove from index
    index_data = [s for s in index_data if s.get('id') != selfie_id]
    save_index(index_data)
    
    return jsonify({'success': True})

@app.route('/health')
@app.route('/selfies/health')
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})

if __name__ == '__main__':
    # Use threaded=True for better handling of multiple requests
    app.run(host='0.0.0.0', port=5001, debug=False, threaded=True) 