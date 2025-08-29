#!/usr/bin/env python3
"""
Quick test script for network tier detection logic
"""

def test_network_tier_logic():
    """Test the network tier classification logic"""
    
    test_cases = [
        # Full private cases
        ('10.10.42.5', 'full_private'),
        ('10.10.42.1', 'full_private'),
        ('127.0.0.1', 'full_private'),
        ('127.0.1.1', 'full_private'),
        ('localhost', 'full_private'),
        ('::1', 'full_private'),
        
        # Semi-public cases
        ('192.168.6.1', 'semi_public'),
        ('192.168.6.100', 'semi_public'),
        
        # External cases
        ('192.168.1.1', 'external'),
        ('8.8.8.8', 'external'),
        ('172.16.1.1', 'external'),
        ('203.0.113.1', 'external'),
    ]
    
    def classify_ip(client_ip):
        """Replicate the logic from app.py"""
        if (client_ip.startswith('10.10.42.') or 
            client_ip.startswith('127.') or
            client_ip == '::1' or
            client_ip == 'localhost'):
            return 'full_private'
        elif client_ip.startswith('192.168.6.'):
            return 'semi_public'
        else:
            return 'external'
    
    print("Testing network tier classification logic:")
    print("=" * 50)
    
    all_passed = True
    for ip, expected in test_cases:
        result = classify_ip(ip)
        status = "✓ PASS" if result == expected else "✗ FAIL"
        print(f"{ip:<15} → {result:<12} {status}")
        if result != expected:
            all_passed = False
            print(f"  Expected: {expected}, Got: {result}")
    
    print("=" * 50)
    print(f"Overall result: {'✓ ALL TESTS PASSED' if all_passed else '✗ SOME TESTS FAILED'}")
    return all_passed

if __name__ == '__main__':
    test_network_tier_logic()