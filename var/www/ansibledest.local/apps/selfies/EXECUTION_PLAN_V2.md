# Selfie Portal v2 Execution Plan
**Date: August 21, 2025**
**Project: Three-Tier Network Access Architecture Implementation**

## Project Overview
Transform the current Selfie Portal into a three-tier access system:
- **Full Private** (10.10.42.x, 127.0.0.x): Complete functionality (current experience)
- **Semi-Public** (192.168.6.x): Read-only gallery + sanitized health endpoint
- **External** (Internet via Cloudflare): Read-only gallery with Griffin Creek Trestle branding

## Phase 1: Preparation & Backup ⏳
**Status: Pending**

### 1.1 Backup Current Application
- [ ] Create backup of current application directory
- [ ] Document existing nginx configuration
- [ ] Test baseline functionality
- [ ] Document current route structure

### 1.2 Environment Verification
- [ ] Verify Python virtual environment status
- [ ] Check current dependencies
- [ ] Establish development testing approach

## Phase 2: Core Application Changes ⏳
**Status: Pending**

### 2.1 Network Tier Detection Implementation
- [ ] Enhance `get_client_ip()` function for better header handling
- [ ] Create `get_network_tier()` function with three tiers
- [ ] Add IP range validation logic
- [ ] Add logging for tier detection debugging

### 2.2 Route Handler Development
- [ ] Create `/gallery` route for public access
- [ ] Create `/api/public/selfies` endpoint
- [ ] Implement `/status` sanitized health endpoint
- [ ] Add tier checking to existing routes
- [ ] Implement graceful fallback for tier mismatches

### 2.3 Content Curation Logic
- [ ] Implement selfie filtering for public gallery
- [ ] Add metadata sanitization (remove sensitive data)
- [ ] Create curated subset selection algorithm
- [ ] Limit public gallery content appropriately

## Phase 3: User Interface Development ⏳
**Status: Pending**

### 3.1 Public Templates Creation
- [ ] Create `public_gallery.html` template
- [ ] Design Griffin Creek Trestle-themed narrative
- [ ] Remove upload/delete UI elements from public view
- [ ] Add community project context messaging
- [ ] Ensure mobile-responsive design

### 3.2 Static Assets Updates
- [ ] Modify CSS for public gallery styling
- [ ] Remove interactive JavaScript for public users
- [ ] Add Griffin Creek Trestle branding elements
- [ ] Optimize assets for public consumption

## Phase 4: Infrastructure Configuration ⏳
**Status: Pending**

### 4.1 Nginx Configuration Updates
- [ ] Configure three-tier access rules
- [ ] Set up location blocks: `/selfies`, `/gallery`, `/status`, `/health`
- [ ] Implement IP-based access controls
- [ ] Configure Cloudflare tunnel routing integration

### 4.2 Service Integration
- [ ] Update systemd service configuration if needed
- [ ] Ensure proper file permissions for new endpoints
- [ ] Configure log rotation for new access patterns

## Phase 5: Testing & Validation ⏳
**Status: Pending**

### 5.1 Local AP Testing (10.10.42.x)
- [ ] Test full functionality: camera, upload, delete
- [ ] Verify private health endpoint access
- [ ] Confirm original user experience unchanged
- [ ] Test edge cases and error handling

### 5.2 Semi-Public Testing (192.168.6.x)
- [ ] Test read-only gallery access
- [ ] Verify sanitized health endpoint functionality
- [ ] Confirm upload/delete operations blocked
- [ ] Test network boundary conditions

### 5.3 External Testing (Cloudflare Tunnel)
- [ ] Test public gallery via internet access
- [ ] Verify upload/delete operations blocked
- [ ] Confirm health endpoint access denied
- [ ] Test mobile responsiveness from external networks

## Phase 6: Deployment & Monitoring ⏳
**Status: Pending**

### 6.1 Production Deployment
- [ ] Deploy to Raspberry Pi in staged manner
- [ ] Monitor service startup and stability
- [ ] Verify all network tiers function correctly
- [ ] Update any dependent configurations

### 6.2 Post-Deployment Validation
- [ ] Test end-to-end functionality from each network tier
- [ ] Monitor logs for errors or access violations
- [ ] Validate Cloudflare tunnel routing
- [ ] Document issues and resolutions
- [ ] Update operational documentation

## Technical Specifications

### Network Tier Definitions
```python
# Full Private: 10.10.42.x, 127.0.0.x, ::1
# Semi-Public: 192.168.6.x  
# External: All other IPs (via Cloudflare)
```

### New Endpoints
- `GET /gallery` - Public read-only gallery
- `GET /status` - Sanitized health (semi-public + private)
- `GET /api/public/selfies` - Curated selfie API

### Nginx Access Control
```nginx
# Private: allow 10.10.42.0/24, 127.0.0.1
# Semi-Public: + allow 192.168.6.0/24
# External: proxy via Cloudflare tunnel
```

## Risk Mitigation Strategy
1. **Backup Strategy**: Complete application backup before any changes
2. **Incremental Implementation**: Test each phase before proceeding
3. **Rollback Plan**: Keep previous version ready for quick restoration
4. **Testing Protocol**: Comprehensive testing from each network tier
5. **Monitoring**: Enhanced logging during transition period

## Success Criteria
- [x] Local AP users retain full current functionality
- [x] Semi-public users can access gallery and health status
- [x] External users see Griffin Creek Trestle branded read-only gallery
- [x] No unauthorized access to upload/delete functions
- [x] All network tiers respond appropriately to their access level
- [x] Performance maintained across all access patterns

## Timeline Estimate
- **Phase 1-2**: 2-3 hours (core development)
- **Phase 3**: 1-2 hours (UI/templates)
- **Phase 4**: 1 hour (infrastructure)
- **Phase 5**: 1-2 hours (testing)
- **Phase 6**: 30 minutes (deployment)

**Total Estimated Time: 5-8 hours**

---
**Implementation Start Date: August 21, 2025**
**Lead Developer: Claude Code Assistant**
**Project: Griffin Creek Trestle Selfie Portal v2**