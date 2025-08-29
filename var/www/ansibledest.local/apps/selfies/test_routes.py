#!/usr/bin/env python3
"""
Test script to validate Selfie Portal v2 routes
"""

import sys
import json
from app import app

def test_routes():
    """Test all the new routes and access controls"""
    
    with app.test_client() as client:
        print("Testing Selfie Portal v2 Routes")
        print("=" * 50)
        
        # Test cases with different simulated IPs
        test_cases = [
            {
                'name': 'Full Private User (10.10.42.5)',
                'ip': '10.10.42.5',
                'expected_tier': 'full_private'
            },
            {
                'name': 'Semi-Public User (192.168.6.100)',
                'ip': '192.168.6.100',
                'expected_tier': 'semi_public'
            },
            {
                'name': 'External User (8.8.8.8)',
                'ip': '8.8.8.8',
                'expected_tier': 'external'
            }
        ]
        
        for test_case in test_cases:
            print(f"\n--- {test_case['name']} ---")
            
            # Simulate the IP by setting headers
            headers = {'X-Real-IP': test_case['ip']}
            
            # Test /status endpoint
            print("Testing /status endpoint:")
            resp = client.get('/status', headers=headers)
            if resp.status_code == 200:
                data = resp.get_json()
                print(f"  ✓ Status: {resp.status_code}, Tier: {data.get('network_tier')}")
            else:
                print(f"  ✗ Status: {resp.status_code}")
            
            # Test /health endpoint
            print("Testing /health endpoint:")
            resp = client.get('/health', headers=headers)
            if test_case['expected_tier'] == 'full_private':
                if resp.status_code == 200:
                    print(f"  ✓ Health accessible (expected for private)")
                else:
                    print(f"  ✗ Health blocked (unexpected for private): {resp.status_code}")
            else:
                if resp.status_code == 403:
                    print(f"  ✓ Health blocked (expected for non-private)")
                else:
                    print(f"  ✗ Health accessible (unexpected for non-private): {resp.status_code}")
            
            # Test /gallery endpoint
            print("Testing /gallery endpoint:")
            resp = client.get('/gallery', headers=headers)
            if resp.status_code == 200:
                print(f"  ✓ Gallery accessible: {resp.status_code}")
            elif resp.status_code == 302 and test_case['expected_tier'] == 'full_private':
                print(f"  ✓ Private user redirected to main app: {resp.status_code}")
            else:
                print(f"  ✗ Gallery issue: {resp.status_code}")
            
            # Test /api/public/selfies endpoint
            print("Testing /api/public/selfies endpoint:")
            resp = client.get('/api/public/selfies', headers=headers)
            if test_case['expected_tier'] in ['semi_public', 'external']:
                if resp.status_code == 200:
                    data = resp.get_json()
                    print(f"  ✓ Public API accessible, returned {len(data)} selfies")
                else:
                    print(f"  ✗ Public API issue: {resp.status_code}")
            else:
                if resp.status_code == 403:
                    print(f"  ✓ Public API blocked for private user (expected)")
                else:
                    print(f"  ✗ Public API should be blocked for private user: {resp.status_code}")
        
        print("\n" + "=" * 50)
        print("Route testing completed!")

if __name__ == '__main__':
    test_routes()