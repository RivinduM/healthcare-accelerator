# WSO2 Healthcare IS - Token Management Component

This component provides a custom OAuth2 authorization code grant handler for WSO2 Identity Server to support SMART on FHIR authorization flows.

## Overview

This module provides IS 7.2.0 compatible OAuth2 grant handling for SMART on FHIR. It works alongside the `org.wso2.healthcare.is.smart.auth` component, which handles launch context injection into token responses.

## Components

### HealthcareAuthorizationCodeGrantHandler

Extends the default IS authorization code grant handler to enforce SMART on FHIR refresh token behavior.

**Features:**
- Handles `offline_access` scope to control refresh token issuance
- Removes refresh token from response if `offline_access` scope is not requested
- Compatible with WSO2 IS 7.2.0

> **Note:** Launch context injection (`patient`, `practitioner`, `encounter` parameters in token responses) is handled by `HealthcareSmartAuthTokenResponseHandler` in the `org.wso2.healthcare.is.smart.auth` component, not by this grant handler.

## Configuration

### Register the Grant Handler

Add the following to WSO2 IS `deployment.toml`:

```toml
[oauth.grant_type.authorization_code]
grant_handler = "org.wso2.healthcare.is.tokenmgt.handlers.HealthcareAuthorizationCodeGrantHandler"
```

### Configure Allowed Scopes

Ensure SMART on FHIR scopes are allowed in `deployment.toml`:

```toml
[oauth]
authorize_all_scopes = true
allowed_scopes = ["^(patient|user|system)/.*", "^OH_.*", "fhirUser", "launch", "launch/patient", "launch/encounter", "offline_access"]
```

## SMART on FHIR Scope Support

### offline_access

When `offline_access` is **not** present in the requested scopes, the refresh token is stripped from the response even if the authorization code grant would normally issue one.

**With `offline_access`:**
```json
{
  "access_token": "...",
  "refresh_token": "...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "launch/patient patient/*.read offline_access"
}
```

**Without `offline_access`:**
```json
{
  "access_token": "...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "launch/patient patient/*.read"
}
```

## Dependencies

- `org.wso2.healthcare.is.smart.auth` — launch context injection into token responses
- WSO2 IS 7.2.0 OAuth2 components
- Carbon identity framework

## Building

```bash
mvn clean install
```

## Deployment

1. Build the component
2. Copy the JAR to `<IS_HOME>/repository/components/dropins/`
3. Configure as described above
4. Restart WSO2 IS

## License

Copyright (c) 2026, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.

Licensed under the Apache License, Version 2.0.
