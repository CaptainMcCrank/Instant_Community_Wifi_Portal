#!/bin/bash

echo "=== Complete Template Fix ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
    fi
}

echo "1. Backing up current template..."
if sudo cp /var/www/thepub.local/apps/selfies/templates/index.html /var/www/thepub.local/apps/selfies/templates/index.html.backup.$(date +%Y%m%d_%H%M%S); then
    print_status 0 "Template backup created"
else
    print_status 1 "Failed to create backup"
    exit 1
fi

echo ""
echo "2. Creating corrected template..."
sudo tee /var/www/thepub.local/apps/selfies/templates/index.html > /dev/null <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Selfie Portal - Community WiFi</title>
    <link rel="stylesheet" href="/selfies/static/style.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
</head>
<body>
    <div class="container">
        <!-- Header -->
        <header class="header">
            <div class="header-content">
                <h1><i class="fas fa-camera"></i> Selfie Portal</h1>
                <p>Share your moment with the community</p>
            </div>
        </header>

        <!-- Camera Section -->
        <section class="camera-section" id="cameraSection">
            <div class="camera-container">
                <video id="video" autoplay playsinline muted></video>
                <canvas id="canvas" style="display: none;"></canvas>
                <div class="camera-overlay">
                    <div class="camera-frame">
                        <div class="corner top-left"></div>
                        <div class="corner top-right"></div>
                        <div class="corner bottom-left"></div>
                        <div class="corner bottom-right"></div>
                    </div>
                </div>
                <div class="camera-controls">
                    <button id="captureBtn" class="btn btn-primary btn-large">
                        <i class="fas fa-camera"></i> Take Selfie
                    </button>
                    <button id="switchCameraBtn" class="btn btn-secondary">
                        <i class="fas fa-sync-alt"></i> Switch Camera
                    </button>
                </div>
            </div>
        </section>

        <!-- Preview Section -->
        <section class="preview-section" id="previewSection" style="display: none;">
            <div class="preview-container">
                <img id="previewImage" alt="Selfie Preview">
                <div class="preview-controls">
                    <div class="caption-input">
                        <input type="text" id="captionInput" placeholder="Add a caption (optional)" maxlength="100">
                    </div>
                    <div class="preview-buttons">
                        <button id="retakeBtn" class="btn btn-secondary">
                            <i class="fas fa-redo"></i> Retake
                        </button>
                        <button id="uploadBtn" class="btn btn-primary">
                            <i class="fas fa-upload"></i> Upload
                        </button>
                    </div>
                </div>
            </div>
        </section>

        <!-- Upload Progress -->
        <div class="upload-progress" id="uploadProgress" style="display: none;">
            <div class="progress-bar">
                <div class="progress-fill"></div>
            </div>
            <p>Uploading your selfie...</p>
        </div>

        <!-- Gallery Section -->
        <section class="gallery-section">
            <div class="section-header">
                <h2><i class="fas fa-images"></i> Recent Selfies</h2>
                <button id="refreshBtn" class="btn btn-secondary btn-small">
                    <i class="fas fa-sync-alt"></i> Refresh
                </button>
            </div>
            
            <div class="gallery-grid" id="galleryGrid">
                {% for selfie in selfies %}
                <div class="selfie-card" data-id="{{ selfie.id }}">
                    <div class="selfie-image">
                        <img src="{{ url_for('uploaded_file', filename=selfie.filename) }}" 
                             alt="Selfie" loading="lazy">
                        <div class="selfie-overlay">
                            <a href="{{ url_for('view_selfie', selfie_id=selfie.id) }}" class="view-btn">
                                <i class="fas fa-eye"></i>
                            </a>
                        </div>
                    </div>
                    <div class="selfie-info">
                        {% if selfie.caption %}
                        <p class="caption">{{ selfie.caption }}</p>
                        {% endif %}
                        <p class="timestamp">{{ selfie.timestamp[:16].replace('T', ' ') }}</p>
                    </div>
                </div>
                {% endfor %}
            </div>
            
            {% if not selfies %}
            <div class="empty-state">
                <i class="fas fa-camera"></i>
                <h3>No selfies yet!</h3>
                <p>Be the first to share a selfie with the community.</p>
            </div>
            {% endif %}
        </section>

        <!-- Navigation -->
        <nav class="bottom-nav">
            <a href="#" class="nav-item active" data-section="camera">
                <i class="fas fa-camera"></i>
                <span>Camera</span>
            </a>
            <a href="#" class="nav-item" data-section="gallery">
                <i class="fas fa-images"></i>
                <span>Gallery</span>
            </a>
            <a href="/" class="nav-item">
                <i class="fas fa-home"></i>
                <span>Home</span>
            </a>
        </nav>
    </div>

    <!-- Toast Notifications -->
    <div id="toast" class="toast"></div>

    <script src="/selfies/static/upload.js"></script>
</body>
</html>
EOF

if [ $? -eq 0 ]; then
    print_status 0 "Template rewritten successfully"
else
    print_status 1 "Failed to rewrite template"
    exit 1
fi

echo ""
echo "3. Setting correct permissions..."
sudo chown www-data:www-data /var/www/thepub.local/apps/selfies/templates/index.html
sudo chmod 644 /var/www/thepub.local/apps/selfies/templates/index.html

echo ""
echo "4. Verifying template content..."
echo "   JavaScript references in template:"
grep -n "upload.js" /var/www/thepub.local/apps/selfies/templates/index.html

echo ""
echo "5. Testing the updated page..."
if curl -s http://localhost/selfies/ | grep -c "upload.js" | grep -q "1"; then
    print_status 0 "Page now has only one JavaScript reference"
else
    print_status 1 "Page still has multiple JavaScript references"
    echo "   Found $(curl -s http://localhost/selfies/ | grep -c "upload.js") references"
fi

echo ""
echo "6. Verifying the correct path is used..."
if curl -s http://localhost/selfies/ | grep -q "/selfies/static/upload.js"; then
    print_status 0 "Correct JavaScript path is used"
else
    print_status 1 "Wrong JavaScript path is still used"
fi

echo ""
echo "7. Testing static file access..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost/selfies/static/upload.js | grep -q "200"; then
    print_status 0 "JavaScript file is accessible"
else
    print_status 1 "JavaScript file is not accessible"
fi

echo ""
echo "=== Fix Complete ==="
echo "The template has been completely rewritten with the correct content."
echo ""
echo "Now test your browser:"
echo "1. Clear cache (Ctrl+F5)"
echo "2. Visit: http://10.42.0.1/selfies/"
echo "3. Check console for 'Camera support detected' message"
echo ""
echo "The page should now load only:"
echo "  /selfies/static/upload.js" 