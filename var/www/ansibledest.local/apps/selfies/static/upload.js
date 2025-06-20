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
        
        this.init();
    }
    
    init() {
        this.bindEvents();
        this.initCamera();
        this.initNavigation();
        this.autoRefresh();
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
        try {
            const constraints = {
                video: {
                    facingMode: this.currentFacingMode,
                    width: { ideal: 1280 },
                    height: { ideal: 720 }
                }
            };
            
            this.stream = await navigator.mediaDevices.getUserMedia(constraints);
            this.video.srcObject = this.stream;
            
            this.showToast('Camera ready!', 'success');
        } catch (error) {
            console.error('Camera access error:', error);
            this.showToast('Camera access denied. Please allow camera permissions.', 'error');
            this.disableCameraFeatures();
        }
    }
    
    async switchCamera() {
        if (this.stream) {
            this.stream.getTracks().forEach(track => track.stop());
        }
        
        this.currentFacingMode = this.currentFacingMode === 'user' ? 'environment' : 'user';
        
        try {
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
        }, 'image/jpeg', 0.8);
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
            const response = await fetch('/upload', {
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
            const response = await fetch('/api/selfies');
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
                <img src="/data/uploads/${selfie.filename}" alt="Selfie" loading="lazy">
                <div class="selfie-overlay">
                    <a href="/view/${selfie.id}" class="view-btn">
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
        this.captureBtn.disabled = true;
        this.switchCameraBtn.disabled = true;
        this.captureBtn.textContent = 'Camera Unavailable';
        this.switchCameraBtn.textContent = 'Switch Unavailable';
    }
    
    showToast(message, type = 'info') {
        const toast = document.getElementById('toast');
        if (!toast) return;
        
        toast.textContent = message;
        toast.className = `toast toast-${type}`;
        toast.style.display = 'block';
        
        setTimeout(() => {
            toast.style.display = 'none';
        }, 3000);
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

// Handle file input fallback for devices without camera
function setupFileInput() {
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
                const img = document.getElementById('previewImage');
                img.src = e.target.result;
                document.getElementById('previewSection').style.display = 'block';
                document.getElementById('cameraSection').style.display = 'none';
            };
            reader.readAsDataURL(file);
        }
    });
    
    document.body.appendChild(fileInput);
    
    // Add fallback button if camera is not available
    const captureBtn = document.getElementById('captureBtn');
    if (captureBtn && !navigator.mediaDevices) {
        captureBtn.onclick = () => fileInput.click();
        captureBtn.innerHTML = '<i class="fas fa-image"></i> Choose Photo';
    }
}

// Initialize file input fallback
setupFileInput(); 