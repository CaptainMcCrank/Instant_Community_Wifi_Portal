# Selfie Portal

A mobile-friendly selfie sharing portal for the Instant Community WiFi Portal. Built with Flask and designed for local community interaction.

## Features

### 📸 Camera Integration
- **HTML5 Camera Access**: Direct camera access using `getUserMedia()` API
- **Front/Back Camera Switch**: Toggle between front and back cameras
- **Real-time Preview**: Live camera feed with capture frame overlay
- **Photo Capture**: High-quality image capture with canvas processing
- **Fallback Support**: File input fallback for devices without camera access

### 🎨 Mobile-First Design
- **Responsive Layout**: Optimized for mobile devices and tablets
- **Touch-Friendly Interface**: Large buttons and intuitive gestures
- **Progressive Web App**: Works offline and provides app-like experience
- **Dark Mode Support**: Automatic dark mode detection and styling
- **Orientation Handling**: Responsive to device orientation changes

### 📱 User Experience
- **Intuitive Navigation**: Bottom navigation with camera, gallery, and home sections
- **Photo Preview**: Review captured photos before uploading
- **Caption Support**: Add optional captions to selfies
- **Upload Progress**: Visual feedback during upload process
- **Toast Notifications**: User-friendly status messages

### 🖼️ Gallery Features
- **Grid Layout**: Responsive grid display of recent selfies
- **Auto-refresh**: Automatic gallery updates every 30 seconds
- **Individual View**: Full-screen view of individual selfies
- **Download Support**: Download selfies to device
- **Share Functionality**: Native sharing or link copying
- **Delete Option**: Remove selfies (admin function)

### 🔧 Technical Features
- **File-based Storage**: Simple JSON metadata with file storage
- **Automatic Cleanup**: Removes selfies older than 30 days
- **File Validation**: Supports JPEG, PNG, GIF, and WebP formats
- **Size Limits**: 10MB maximum file size
- **Rate Limiting**: Basic protection against spam
- **Security**: Input validation and sanitization

## Installation

The selfie portal is automatically installed as part of the Instant Community WiFi Portal Ansible playbook.

### Manual Installation

1. **Install Dependencies**:
   ```bash
   sudo apt update
   sudo apt install python3 python3-pip python3-venv python3-dev libjpeg-dev zlib1g-dev
   ```

2. **Create Virtual Environment**:
   ```bash
   cd /var/www/ansibledest.local/apps/selfies
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Set Permissions**:
   ```bash
   sudo chown -R www-data:www-data /var/www/ansibledest.local/apps/selfies
   sudo chmod -R 755 /var/www/ansibledest.local/apps/selfies
   ```

4. **Start the Service**:
   ```bash
   sudo systemctl enable selfie-portal
   sudo systemctl start selfie-portal
   ```

## Configuration

### Environment Variables

The application can be configured using environment variables:

- `MAX_CONTENT_LENGTH`: Maximum file size (default: 10MB)
- `MAX_SELFIES`: Maximum number of selfies to keep (default: 100)
- `CLEANUP_DAYS`: Days to keep selfies before cleanup (default: 30)

### Nginx Configuration

The portal is accessible at `/selfies` on your community WiFi domain. The nginx configuration handles:

- Proxy forwarding to Flask application
- Static file serving for uploaded images
- Large file upload support
- Caching headers for performance

## Usage

### For Users

1. **Connect to WiFi**: Join the "JoinMe" WiFi network
2. **Access Portal**: Navigate to the selfie portal link
3. **Take Selfie**: Use the camera interface to capture a photo
4. **Add Caption**: Optionally add a caption to your selfie
5. **Upload**: Share your selfie with the community
6. **Browse Gallery**: View recent selfies from other users

### For Administrators

- **Monitor Usage**: Check `/var/www/ansibledest.local/apps/selfies/data/index.json` for metadata
- **Manage Storage**: Monitor `/var/www/ansibledest.local/apps/selfies/data/uploads/` for image files
- **Service Management**: Use `systemctl` commands to manage the service
- **Logs**: Check system logs for application status

## File Structure

```
/var/www/ansibledest.local/apps/selfies/
├── app.py                 # Flask application
├── requirements.txt       # Python dependencies
├── README.md             # This file
├── data/                 # Data storage
│   ├── uploads/          # Image files
│   └── index.json        # Metadata index
├── static/               # Static assets
│   ├── style.css         # Stylesheet
│   └── upload.js         # JavaScript
├── templates/            # HTML templates
│   ├── index.html        # Main portal page
│   └── view.html         # Individual selfie view
└── venv/                 # Python virtual environment
```

## API Endpoints

- `GET /`: Main portal page
- `POST /upload`: Upload a selfie
- `GET /view/<id>`: View individual selfie
- `GET /api/selfies`: Get recent selfies (JSON)
- `POST /delete/<id>`: Delete a selfie
- `GET /data/uploads/<filename>`: Serve uploaded files

## Security Considerations

- **File Validation**: Only image files are accepted
- **Size Limits**: Prevents large file uploads
- **Input Sanitization**: Captions are sanitized
- **Access Control**: No authentication required (community feature)
- **Automatic Cleanup**: Prevents storage bloat

## Troubleshooting

### Common Issues

1. **Camera Not Working**:
   - Ensure HTTPS is enabled (required for camera access)
   - Check browser permissions
   - Try refreshing the page

2. **Upload Failures**:
   - Check file size (max 10MB)
   - Verify file format (JPEG, PNG, GIF, WebP)
   - Check disk space

3. **Service Not Starting**:
   - Check Python virtual environment
   - Verify file permissions
   - Check system logs: `journalctl -u selfie-portal`

### Logs

- **Application Logs**: Check Flask application output
- **System Logs**: `journalctl -u selfie-portal`
- **Nginx Logs**: `/var/log/nginx/access.log` and `/var/log/nginx/error.log`

## Development

### Local Development

1. **Clone Repository**: Copy files to development environment
2. **Install Dependencies**: `pip install -r requirements.txt`
3. **Run Development Server**: `python app.py`
4. **Access**: Navigate to `http://localhost:5001`

### Customization

- **Styling**: Modify `static/style.css` for visual changes
- **Functionality**: Edit `static/upload.js` for JavaScript features
- **Backend**: Modify `app.py` for server-side changes
- **Templates**: Update HTML files in `templates/` directory

## License

This project is part of the Instant Community WiFi Portal and follows the same licensing terms.

## Contributing

Contributions are welcome! Please ensure:

- Code follows existing style guidelines
- Features are mobile-friendly
- Security considerations are addressed
- Documentation is updated

## Support

For issues and questions:

1. Check the troubleshooting section
2. Review system logs
3. Verify configuration settings
4. Test with different browsers/devices

---

**Note**: This selfie portal is designed for local community use within the Instant Community WiFi Portal ecosystem. It promotes local interaction and community building through shared visual content. 