# consent-app-bff

Ballerina Backend-for-Frontend for the consent application. Runs on port **9092**, exposes a REST API, and works with both WSO2 IS and Asgardeo.

## Architecture

```
consent-app (UI)
      │
      ▼
consent-app-bff  :9092
      │
      ├── IDP (WSO2 IS / Asgardeo)  — OauthConsentKey + SCIM
      └── OpenFGC  — consent store
```

### Files

| File | Purpose |
|------|---------|
| `config.bal` | All configurables |
| `connections.bal` | IDP + OpenFGC HTTP clients, token management |
| `types.bal` | All record types |
| `service.bal` | HTTP listener, service endpoints |
| `tests/` | Mock OpenFGC listener, IDP mocked at function level, service tests |

## API

### `GET /get-consent-data?sessionDataKeyConsent=&spId=`

Resolves the consent flow and returns all data the UI needs in one call.

**Responses:**

```json
// flow = "scope"
{
  "flow": "scope",
  "sessionDataKeyConsent": "...",
  "spId": "...",
  "user": { "id": "...", "displayName": "...", "email": "..." },
  "isPractitioner": false,
  "patients": [],
  "scopes": ["patient/Observation.read"],
  "hiddenScopes": ["OH_launch/abc"],
  "mandatoryClaims": "0_email",
  "previouslyApprovedScopes": [],
  "consentToken": "<jwt>"
}

// flow = "purpose"
{
  "flow": "purpose",
  "sessionDataKeyConsent": "...",
  "spId": "...",
  "appName": "MyApp",
  "user": { ... },
  "purposes": [{ "purposeName": "All Health Data Access", "mandatory": false, "elements": ["Patient", "Observation"] }],
  "scopes": ["openid", "fhirUser"],
  "mandatoryClaims": "",
  "consentToken": "<jwt>"
}

// flow = "redirect" (consentFlow = "auto", spId not in either list)
{
  "flow": "redirect",
  "redirectUrl": "https://<idp>/oauth2_consent.do?sessionDataKeyConsent=...&spId=..."
}
```

### `POST /submit-consent`

Validates the JWT consent token and stores the decision in OpenFGC. The UI form-POSTs directly to the IDP after this call succeeds.

```json
// scope flow
{
  "consentToken": "<jwt>",
  "sessionDataKeyConsent": "...",
  "spId": "...",
  "approved": true,
  "approvedScopes": ["patient/Observation.read"],
  "hiddenScopes": ["OH_launch/abc"]
}

// purpose flow
{
  "consentToken": "<jwt>",
  "sessionDataKeyConsent": "...",
  "spId": "...",
  "approved": true,
  "consentedPurposes": [{ "purposeName": "All Health Data Access", "consentedElements": ["Patient"] }],
  "existingConsentId": "<id-if-updating>"
}
```

## Consent flows

| `consentFlow` | Behaviour |
|---------------|-----------|
| `scope` | All apps use SMART scope selection |
| `purpose` | All apps use purpose + element selection |
| `auto` | Resolved by `spId`: `scopeConsentedApps` → scope, `purposeConsentedApps` → purpose, otherwise redirect to `defaultIdpConsentPage` |

When `consentFlow = "auto"`, flow is determined **before** any IDP call, so the IDP session is never corrupted by a server-side OauthConsentKey call for the redirect path.

When `scopes = []` (no visible scopes in the scope flow), the UI auto-approves silently without calling submit-consent.

## Setup

```bash
cp Config.toml.example Config.toml
# Edit Config.toml with your values
bal run
```

### Required config

| Key | Description |
|-----|-------------|
| `corsAllowedOrigin` | UI origin, e.g. `http://localhost:5175` |
| `idpBaseUrl` | WSO2 IS (`https://localhost:9443`) or Asgardeo (`https://api.asgardeo.io/t/<tenant>`) |
| `clientId` / `clientSecret` | OAuth2 client credentials; `clientSecret` is also the HS256 JWT signing secret |
| `openfgcBaseUrl` / `orgId` / `tppClientId` / `consentType` | OpenFGC connection |

See `Config.toml.example` for the full template including `consentFlow`, purpose definitions, and `auto` mode settings.

## Tests

```bash
bal test
```

Tests use in-process mock IDP and OpenFGC listeners defined in `tests/`.
