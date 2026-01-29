#!/usr/bin/env python3
"""
Background update of usage limits cache via Anthropic API (Windows version)

Credentials are retrieved from:
1. Windows Credential Manager (service: "Claude Code-credentials") - requires 'keyring' package
2. File: ~/.claude/.credentials.json (fallback for older versions or Linux/WSL)
3. Environment variable: CLAUDE_CODE_OAUTH_TOKEN
"""

import json
import os
import sys
from pathlib import Path
import urllib.request
import urllib.error


def get_token_from_credential_manager() -> str:
    """
    Get OAuth token from Windows Credential Manager.
    Claude Code uses node-keytar which stores credentials as:
    - Service: "Claude Code-credentials"
    - Account: (varies, often email or user identifier)

    Returns empty string if keyring not available or credentials not found.
    """
    try:
        import keyring
    except ImportError:
        return ''

    service = "Claude Code-credentials"

    try:
        # Try to find all credentials for the service
        # keyring.get_credential returns a Credential object with username and password
        cred = keyring.get_credential(service, None)
        if cred and cred.password:
            # Password contains JSON with OAuth tokens
            try:
                data = json.loads(cred.password)
                # Structure: {"claudeAiOauth": {"accessToken": "..."}}
                if 'claudeAiOauth' in data:
                    return data['claudeAiOauth'].get('accessToken', '')
                # Direct accessToken
                if 'accessToken' in data:
                    return data['accessToken']
            except json.JSONDecodeError:
                # Password might be the token directly
                if cred.password.startswith('sk-ant-'):
                    return cred.password
    except Exception:
        pass

    return ''


def get_token_from_file() -> str:
    """
    Get OAuth token from credentials file.
    Locations checked:
    - ~/.claude/.credentials.json (Linux/WSL style)
    - ~/.claude/credentials.json (alternative)
    """
    possible_paths = [
        Path.home() / '.claude' / '.credentials.json',
        Path.home() / '.claude' / 'credentials.json',
    ]

    for cred_path in possible_paths:
        if not cred_path.exists():
            continue
        try:
            with open(cred_path, 'r', encoding='utf-8') as f:
                creds = json.load(f)

            # Structure 1: {"claudeAiOauth": {"accessToken": "..."}}
            if 'claudeAiOauth' in creds:
                token = creds['claudeAiOauth'].get('accessToken')
                if token:
                    return token

            # Structure 2: {"accessToken": "..."}
            if 'accessToken' in creds:
                return creds['accessToken']

            # Structure 3: {"oauth": {"access_token": "..."}}
            if 'oauth' in creds:
                token = creds['oauth'].get('access_token')
                if token:
                    return token

        except (json.JSONDecodeError, IOError):
            continue

    return ''


def get_token_from_env() -> str:
    """Get OAuth token from environment variable."""
    return os.environ.get('CLAUDE_CODE_OAUTH_TOKEN', '')


def get_oauth_token() -> str:
    """
    Get OAuth token trying multiple sources in order:
    1. Windows Credential Manager (primary on Windows)
    2. Credentials file (fallback, used on Linux/WSL)
    3. Environment variable
    """
    # Try Credential Manager first (Windows native)
    token = get_token_from_credential_manager()
    if token:
        return token

    # Try file-based credentials (Linux/WSL or older versions)
    token = get_token_from_file()
    if token:
        return token

    # Try environment variable
    token = get_token_from_env()
    if token:
        return token

    return ''


def fetch_usage(token: str) -> dict:
    """Fetch usage data from Anthropic API."""
    url = 'https://api.anthropic.com/api/oauth/usage'
    headers = {
        'Authorization': f'Bearer {token}',
        'anthropic-beta': 'oauth-2025-04-20'
    }

    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=5) as response:
            return json.loads(response.read().decode('utf-8'))
    except (urllib.error.URLError, json.JSONDecodeError, TimeoutError):
        return {}


def main():
    cache_path = Path.home() / '.claude' / 'usage_cache'

    # Ensure directory exists
    cache_path.parent.mkdir(parents=True, exist_ok=True)

    # Get token
    token = get_oauth_token()
    if not token:
        sys.exit(1)

    # Fetch usage
    response = fetch_usage(token)
    if not response:
        sys.exit(1)

    # Parse response
    five_hour = response.get('five_hour', {})
    seven_day = response.get('seven_day', {})

    h5_util = five_hour.get('utilization', 0)
    d7_util = seven_day.get('utilization', 0)
    h5_reset = five_hour.get('resets_at', '')
    d7_reset = seven_day.get('resets_at', '')

    # Round to integers
    try:
        h5_util = round(float(h5_util))
    except (ValueError, TypeError):
        h5_util = 0

    try:
        d7_util = round(float(d7_util))
    except (ValueError, TypeError):
        d7_util = 0

    # Write cache
    cache_path.write_text(f'{h5_util} {d7_util} {h5_reset} {d7_reset}')


if __name__ == '__main__':
    main()
