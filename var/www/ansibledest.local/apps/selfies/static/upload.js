// Selfie Portal JavaScript
// Handles camera access, photo capture, and upload functionality

class SelfiePortal {
    constructor() {
        this.video = document.getElementById('video');
        this.canvas = document.getElementById('canvas');
        this.captureBtn = document.getElementById('captureBtn');
        this.switchCameraBtn = document.getElementById('switchCameraBtn');
        this.retakeBtn = document.getElementById('retakeBtn');
        this.uploadBtn = document.getElementById('uploadBtn');
        this.refreshBtn = document.getElementById('refreshBtn');
        this.captionInput = document.getElementById('captionInput');
        this.previewImage = document.getElementById('previewImage');
        this.uploadProgress = document.getElementById('uploadProgress');
        
        this.cameraSection = document.getElementById('cameraSection');
        this.previewSection = document.getElementById('previewSection');
        this.galleryGrid = document.getElementById('galleryGrid');
        
        this.stream = null;
        this.currentFacingMode = 'user'; // 'user' for front camera, 'environment' for back
        this.capturedImageData = null;
        this.cameraSupported = false;
        
        // Initialize asynchronously
        this.init().catch(error => {
            console.error('Failed to initialize SelfiePortal:', error);
        });
    }
    
    async init() {
        this.bindEvents();
        await this.checkCameraSupport();
        this.initCamera();
        this.initNavigation();
        this.autoRefresh();
    }
    
    async testCameraPermissions() {
        try {
            console.log('Testing camera permissions...');
            
            // Try to enumerate devices first
            if (navigator.mediaDevices && navigator.mediaDevices.enumerateDevices) {
                const devices = await navigator.mediaDevices.enumerateDevices();
                const videoDevices = devices.filter(device => device.kind === 'videoinput');
                console.log('Available video devices:', videoDevices.length);
                
                if (videoDevices.length === 0) {
                    console.log('No video devices found');
                    return false;
                }
            }
            
            // Try to get user media with minimal constraints
            const stream = await navigator.mediaDevices.getUserMedia({ video: true });
            console.log('Camera permission test successful');
            
            // Stop the test stream
            stream.getTracks().forEach(track => track.stop());
            return true;
            
        } catch (error) {
            console.error('Camera permission test failed:', error);
            return false;
        }
    }
    
    async checkCameraSupport() {
        // Debug information
        console.log('=== Camera Support Check ===');
        console.log('Protocol:', location.protocol);
        console.log('Hostname:', location.hostname);
        console.log('Host:', location.host);
        console.log('User Agent:', navigator.userAgent);
        
        // Detailed mediaDevices debugging
        console.log('navigator.mediaDevices exists:', !!navigator.mediaDevices);
        if (navigator.mediaDevices) {
            console.log('navigator.mediaDevices.getUserMedia exists:', !!navigator.mediaDevices.getUserMedia);
            console.log('navigator.mediaDevices.enumerateDevices exists:', !!navigator.mediaDevices.enumerateDevices);
        }
        
        // Check for legacy getUserMedia support
        console.log('Legacy navigator.getUserMedia exists:', !!(navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia));
        
        console.log('getUserMedia supported:', !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia));
        
        // Check if getUserMedia is supported
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
            console.log('getUserMedia not supported');
            
            // Check if it's a Firefox privacy issue
            const isFirefox = navigator.userAgent.includes('Firefox');
            if (isFirefox) {
                console.log('Firefox detected - checking for privacy settings issues');
                console.log('Firefox version:', navigator.userAgent.match(/Firefox\/(\d+)/)?.[1] || 'unknown');
                
                // Provide specific Firefox guidance
                this.showToast('Camera access blocked. In Firefox, go to about:config and set media.navigator.enabled to true, or check privacy settings.', 'error');
            } else {
                this.showToast('Camera not supported in this browser. Use file upload instead.', 'error');
            }
            
            this.cameraSupported = false;
            return;
        }
        
        // Enhanced local network detection
        const isLocalNetwork = this.isLocalNetwork();
        console.log('Is local network:', isLocalNetwork);
        
        // Check protocol and network requirements
        if (location.protocol !== 'https:' && !isLocalNetwork) {
            console.log('HTTPS or local network required for camera access');
            this.cameraSupported = false;
            this.showToast('HTTPS or local network required for camera access. Please use https:// or connect to local network.', 'error');
            return;
        }
        
        // Test camera permissions
        const permissionsOk = await this.testCameraPermissions();
        if (!permissionsOk) {
            console.log('Camera permissions test failed');
            this.cameraSupported = false;
            this.showToast('Camera permissions denied. Please allow camera access and refresh the page.', 'error');
            return;
        }
        
        // iOS Safari specific checks
        const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
        const isSafari = /Safari/.test(navigator.userAgent) && !/Chrome/.test(navigator.userAgent);
        
        if (isIOS && isSafari) {
            console.log('iOS Safari detected - additional checks may be needed');
            // iOS Safari sometimes needs explicit user interaction for camera access
            // We'll let the camera initialization handle this
        }
        
        this.cameraSupported = true;
        console.log('Camera support detected - proceeding with camera initialization');
    }
    
    isLocalNetwork() {
        const hostname = location.hostname;
        
        // Check for localhost variations
        if (hostname === 'localhost' || hostname === '127.0.0.1') {
            return true;
        }
        
        // Check for .local domains
        if (hostname.endsWith('.local')) {
            return true;
        }
        
        // Check for private IP ranges
        const privateRanges = [
            /^10\./,           // 10.0.0.0/8
            /^172\.(1[6-9]|2[0-9]|3[0-1])\./, // 172.16.0.0/12
            /^192\.168\./      // 192.168.0.0/16
        ];
        
        for (const range of privateRanges) {
            if (range.test(hostname)) {
                return true;
            }
        }
        
        // Additional check for IP addresses that might be local
        // This handles cases where the hostname is an IP address
        if (/^\d+\.\d+\.\d+\.\d+$/.test(hostname)) {
            const parts = hostname.split('.').map(Number);
            if (parts[0] === 10 || 
                (parts[0] === 172 && parts[1] >= 16 && parts[1] <= 31) ||
                (parts[0] === 192 && parts[1] === 168)) {
                return true;
            }
        }
        
        return false;
    }
    
    bindEvents() {
        // Camera controls
        this.captureBtn?.addEventListener('click', () => this.capturePhoto());
        this.switchCameraBtn?.addEventListener('click', () => this.switchCamera());
        this.retakeBtn?.addEventListener('click', () => this.retakePhoto());
        this.uploadBtn?.addEventListener('click', () => this.uploadPhoto());
        this.refreshBtn?.addEventListener('click', () => this.refreshGallery());
        
        // Navigation
        document.querySelectorAll('.nav-item[data-section]').forEach(item => {
            item.addEventListener('click', (e) => {
                e.preventDefault();
                this.switchSection(item.dataset.section);
            });
        });
    }
    
    async initCamera() {
        if (!this.cameraSupported) {
            console.log('Camera not supported - disabling features');
            this.disableCameraFeatures();
            return;
        }
        
        try {
            console.log('=== Camera Initialization ===');
            console.log('Current facing mode:', this.currentFacingMode);
            
            // iOS Safari specific constraints
            const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
            const isSafari = /Safari/.test(navigator.userAgent) && !/Chrome/.test(navigator.userAgent);
            
            let constraints = {
                video: {
                    facingMode: this.currentFacingMode,
                    width: { ideal: 1280 },
                    height: { ideal: 720 }
                }
            };
            
            // iOS Safari sometimes needs different constraints
            if (isIOS && isSafari) {
                console.log('iOS Safari detected - using iOS-specific constraints');
                constraints = {
                    video: {
                        facingMode: this.currentFacingMode,
                        width: { min: 640, ideal: 1280, max: 1920 },
                        height: { min: 480, ideal: 720, max: 1080 }
                    }
                };
            }
            
            console.log('Requesting camera with constraints:', constraints);
            
            this.stream = await navigator.mediaDevices.getUserMedia(constraints);
            console.log('Camera stream obtained:', this.stream);
            
            this.video.srcObject = this.stream;
            
            // Wait for video to be ready
            this.video.onloadedmetadata = () => {
                console.log('Camera ready - video metadata loaded');
                console.log('Video dimensions:', this.video.videoWidth, 'x', this.video.videoHeight);
                this.showToast('Camera ready!', 'success');
            };
            
            this.video.onerror = (error) => {
                console.error('Video error:', error);
                this.showToast('Camera error occurred', 'error');
            };
            
            // Additional iOS Safari handling
            if (isIOS && isSafari) {
                console.log('iOS Safari: Waiting for user interaction before enabling camera');
                // iOS Safari might need a user interaction to fully enable the camera
                this.video.oncanplay = () => {
                    console.log('iOS Safari: Video can play - camera should be working');
                };
            }
            
        } catch (error) {
            console.error('=== Camera Access Error ===');
            console.error('Error name:', error.name);
            console.error('Error message:', error.message);
            console.error('Error stack:', error.stack);
            
            // Provide specific error messages with more detail
            let errorMessage = 'Camera access failed';
            
            if (error.name === 'NotAllowedError') {
                errorMessage = 'Camera access denied. Please allow camera permissions in your browser settings and refresh the page.';
                console.log('User denied camera permission');
            } else if (error.name === 'NotFoundError') {
                errorMessage = 'No camera found on this device. Please check if your device has a camera.';
                console.log('No camera hardware found');
            } else if (error.name === 'NotSupportedError') {
                errorMessage = 'Camera not supported on this device or browser. Try using a different browser.';
                console.log('Camera not supported by browser/device');
            } else if (error.name === 'NotReadableError') {
                errorMessage = 'Camera is in use by another application. Please close other apps using the camera and try again.';
                console.log('Camera is busy with another application');
            } else if (error.name === 'OverconstrainedError') {
                errorMessage = 'Camera constraints not supported. Trying with different settings...';
                console.log('Camera constraints not supported - trying fallback');
                // Try with simpler constraints
                try {
                    const fallbackConstraints = { video: true };
                    console.log('Trying fallback constraints:', fallbackConstraints);
                    this.stream = await navigator.mediaDevices.getUserMedia(fallbackConstraints);
                    this.video.srcObject = this.stream;
                    this.showToast('Camera initialized with fallback settings!', 'success');
                    return;
                } catch (fallbackError) {
                    console.error('Fallback camera initialization failed:', fallbackError);
                    errorMessage = 'Camera initialization failed. Please try refreshing the page.';
                }
            } else {
                errorMessage = `Camera error: ${error.message}. Please try refreshing the page.`;
                console.log('Unknown camera error');
            }
            
            this.showToast(errorMessage, 'error');
            this.disableCameraFeatures();
        }
    }
    
    async switchCamera() {
        if (!this.cameraSupported) {
            this.showToast('Camera switching not supported', 'error');
            return;
        }
        
        if (this.stream) {
            this.stream.getTracks().forEach(track => track.stop());
        }
        
        this.currentFacingMode = this.currentFacingMode === 'user' ? 'environment' : 'user';
        
        try {
            console.log('Switching camera to:', this.currentFacingMode);
            const constraints = {
                video: {
                    facingMode: this.currentFacingMode,
                    width: { ideal: 1280 },
                    height: { ideal: 720 }
                }
            };
            
            this.stream = await navigator.mediaDevices.getUserMedia(constraints);
            this.video.srcObject = this.stream;
            
            this.showToast('Camera switched!', 'info');
        } catch (error) {
            console.error('Camera switch error:', error);
            this.showToast('Failed to switch camera', 'error');
        }
    }
    
    capturePhoto() {
        if (!this.video.srcObject) {
            this.showToast('Camera not available', 'error');
            return;
        }
        
        if (this.video.videoWidth === 0 || this.video.videoHeight === 0) {
            this.showToast('Camera not ready yet. Please wait...', 'error');
            return;
        }
        
        try {
            const context = this.canvas.getContext('2d');
            this.canvas.width = this.video.videoWidth;
            this.canvas.height = this.video.videoHeight;
            
            // Draw the video frame to canvas
            context.drawImage(this.video, 0, 0, this.canvas.width, this.canvas.height);
            
            // Convert to blob
            this.canvas.toBlob((blob) => {
                this.capturedImageData = blob;
                this.previewImage.src = URL.createObjectURL(blob);
                this.showPreview();
                console.log('Photo captured successfully');
            }, 'image/jpeg', 0.8);
        } catch (error) {
            console.error('Photo capture error:', error);
            this.showToast('Failed to capture photo', 'error');
        }
    }
    
    showPreview() {
        this.cameraSection.style.display = 'none';
        this.previewSection.style.display = 'block';
        
        // Update navigation
        document.querySelectorAll('.nav-item').forEach(item => item.classList.remove('active'));
    }
    
    retakePhoto() {
        this.previewSection.style.display = 'none';
        this.cameraSection.style.display = 'flex';
        this.captionInput.value = '';
        this.capturedImageData = null;
        
        // Update navigation
        document.querySelector('.nav-item[data-section="camera"]').classList.add('active');
    }
    
    async uploadPhoto() {
        if (!this.capturedImageData) {
            this.showToast('No photo to upload', 'error');
            return;
        }
        
        this.showUploadProgress();
        
        const formData = new FormData();
        formData.append('selfie', this.capturedImageData, 'selfie.jpg');
        formData.append('caption', this.captionInput.value);
        
        try {
            const response = await fetch('/selfies/upload', {
                method: 'POST',
                body: formData
            });
            
            const result = await response.json();
            
            if (result.success) {
                this.showToast('Selfie uploaded successfully!', 'success');
                this.refreshGallery();
                this.retakePhoto();
            } else {
                this.showToast(result.error || 'Upload failed', 'error');
            }
        } catch (error) {
            console.error('Upload error:', error);
            this.showToast('Upload failed. Please try again.', 'error');
        } finally {
            this.hideUploadProgress();
        }
    }
    
    showUploadProgress() {
        this.uploadProgress.style.display = 'block';
    }
    
    hideUploadProgress() {
        this.uploadProgress.style.display = 'none';
    }
    
    async refreshGallery() {
        try {
            const response = await fetch('/selfies/api/selfies');
            const selfies = await response.json();
            this.updateGallery(selfies);
        } catch (error) {
            console.error('Gallery refresh error:', error);
            this.showToast('Failed to refresh gallery', 'error');
        }
    }
    
    updateGallery(selfies) {
        if (!this.galleryGrid) return;
        
        this.galleryGrid.innerHTML = '';
        
        if (selfies.length === 0) {
            this.galleryGrid.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-camera"></i>
                    <h3>No selfies yet!</h3>
                    <p>Be the first to share a selfie with the community.</p>
                </div>
            `;
            return;
        }
        
        selfies.forEach(selfie => {
            const card = this.createSelfieCard(selfie);
            this.galleryGrid.appendChild(card);
        });
    }
    
    createSelfieCard(selfie) {
        const card = document.createElement('div');
        card.className = 'selfie-card';
        card.dataset.id = selfie.id;
        
        const timestamp = new Date(selfie.timestamp).toLocaleString();
        
        card.innerHTML = `
            <div class="selfie-image">
                <img src="/selfies/data/uploads/${selfie.filename}" alt="Selfie" loading="lazy">
                <div class="selfie-overlay">
                    <a href="/selfies/view/${selfie.id}" class="view-btn">
                        <i class="fas fa-eye"></i>
                    </a>
                </div>
            </div>
            <div class="selfie-info">
                ${selfie.caption ? `<p class="caption">${selfie.caption}</p>` : ''}
                <p class="timestamp">${timestamp}</p>
            </div>
        `;
        
        return card;
    }
    
    switchSection(section) {
        // Update navigation
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
        });
        document.querySelector(`.nav-item[data-section="${section}"]`).classList.add('active');
        
        // Show/hide sections
        if (section === 'camera') {
            this.cameraSection.style.display = 'flex';
            this.previewSection.style.display = 'none';
        } else if (section === 'gallery') {
            this.cameraSection.style.display = 'none';
            this.previewSection.style.display = 'none';
            this.refreshGallery();
        }
    }
    
    initNavigation() {
        // Set initial active state
        const currentSection = window.location.hash.slice(1) || 'camera';
        this.switchSection(currentSection);
    }
    
    autoRefresh() {
        // Auto-refresh gallery every 30 seconds
        setInterval(() => {
            if (document.querySelector('.nav-item[data-section="gallery"]').classList.contains('active')) {
                this.refreshGallery();
            }
        }, 30000);
    }
    
    disableCameraFeatures() {
        if (this.captureBtn) {
            this.captureBtn.disabled = true;
            this.captureBtn.innerHTML = '<i class="fas fa-image"></i> Choose Photo';
            this.captureBtn.onclick = () => this.setupFileInput();
        }
        if (this.switchCameraBtn) {
            this.switchCameraBtn.disabled = true;
            this.switchCameraBtn.textContent = 'Switch Unavailable';
        }
    }
    
    setupFileInput() {
        const fileInput = document.createElement('input');
        fileInput.type = 'file';
        fileInput.accept = 'image/*';
        fileInput.capture = 'user';
        fileInput.style.display = 'none';
        
        fileInput.addEventListener('change', (e) => {
            const file = e.target.files[0];
            if (file) {
                const reader = new FileReader();
                reader.onload = (e) => {
                    this.capturedImageData = file;
                    this.previewImage.src = e.target.result;
                    this.showPreview();
                };
                reader.readAsDataURL(file);
            }
        });
        
        document.body.appendChild(fileInput);
        fileInput.click();
        document.body.removeChild(fileInput);
    }
    
    showToast(message, type = 'info') {
        const toast = document.getElementById('toast');
        if (!toast) return;
        
        toast.textContent = message;
        toast.className = `toast toast-${type}`;
        toast.style.display = 'block';
        
        setTimeout(() => {
            toast.style.display = 'none';
        }, 5000); // Show for 5 seconds for error messages
    }
}

// Initialize the portal when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new SelfiePortal();
});

// Handle page visibility changes to pause/resume camera
document.addEventListener('visibilitychange', () => {
    const video = document.getElementById('video');
    if (video && video.srcObject) {
        const tracks = video.srcObject.getTracks();
        tracks.forEach(track => {
            if (document.hidden) {
                track.enabled = false;
            } else {
                track.enabled = true;
            }
        });
    }
});

// Handle orientation changes
window.addEventListener('orientationchange', () => {
    setTimeout(() => {
        // Recalculate layout after orientation change
        window.dispatchEvent(new Event('resize'));
    }, 100);
});

// Prevent zoom on double tap (mobile)
let lastTouchEnd = 0;
document.addEventListener('touchend', (event) => {
    const now = (new Date()).getTime();
    if (now - lastTouchEnd <= 300) {
        event.preventDefault();
    }
    lastTouchEnd = now;
}, false);

// Add touch feedback for buttons
document.addEventListener('touchstart', (e) => {
    if (e.target.classList.contains('btn')) {
        e.target.style.transform = 'scale(0.95)';
    }
});

document.addEventListener('touchend', (e) => {
    if (e.target.classList.contains('btn')) {
        e.target.style.transform = '';
    }
});

// Debug information
console.log('Selfie Portal loaded');
console.log('Protocol:', location.protocol);
console.log('Hostname:', location.hostname);
console.log('getUserMedia supported:', !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia)); 
