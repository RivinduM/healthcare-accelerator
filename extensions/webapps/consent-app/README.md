# consent-app

React 19 + TypeScript consent UI. Works with `consent-app-bff` and supports both SMART scope and purpose+element consent flows.

## Tech stack

- React 19, TypeScript, Vite
- `@wso2/oxygen-ui` component library
- react-router-dom v7
- No StrictMode (prevents double-invoke of the IDP OauthConsentKey session)

## Pages

| Component | Flow | Description |
|-----------|------|-------------|
| `ScopeConsentPage` | scope | SMART scope checkboxes, select-all/clear-all, mandatory claims, hidden `OH_launch/*` scopes |
| `PurposeConsentPage` | purpose | Purpose + element hierarchy, mandatory purposes, pre-population from prior consent |
| `PatientPickerPage` | scope | Shown to practitioners before scope consent; patient selected here is passed to `ScopeConsentPage` |

On load, `App.tsx` calls `GET /get-consent-data`. If the BFF returns `flow = "redirect"`, the browser is redirected immediately via `window.location.replace`. If `flow = "scope"` and `scopes` is empty, the browser auto-approves silently (no consent page shown).

## Setup

Requires **Node.js 22.8.0**.

```bash
npm install
npm run dev     # dev server at http://localhost:5175
npm run build   # production build
```

### Runtime configuration

Configuration is loaded at runtime from `public/config.js`, which sets values on `window.config`. Edit this file before running or deploying:

```js
window.config = {
    CONSENT_BFF_URL: "",           // BFF base URL; leave empty to use relative path
    IDP_AUTHORIZE_URL: ""          // IDP authorize URL for the final form POST
};
```

| Key | Description |
|-----|-------------|
| `CONSENT_BFF_URL` | BFF base URL. Leave blank to use relative paths (proxied to `http://localhost:9092` in dev) |
| `IDP_AUTHORIZE_URL` | IDP URL for the final form POST after consent is stored. WSO2 IS: `https://localhost:9443/oauth2/authorize`. Asgardeo: `https://api.asgardeo.io/t/<tenant>/oauth2/authorize` |

For deployment (e.g. Choreo Static Site), mount a customised `config.js` at the web root.

## Consent submission flow

**Scope flow (Approve):**
1. `POST /submit-consent` with `approvedScopes` + `hiddenScopes`
2. On success → form POST to `IDP_AUTHORIZE_URL` with `consent=approve`, `scope=<scopes>`, `user_claims_consent=true`, and `consent_<id>=approved` for each mandatory claim

**Purpose flow (Allow):**
1. `POST /submit-consent` with `consentedPurposes`
2. On success → form POST to `IDP_AUTHORIZE_URL` with `consent=approve`, `scope=<all requested scopes>`, `user_claims_consent=true`, and `consent_<id>=approved` for each mandatory claim

**Deny (both flows):** form POST directly to `IDP_AUTHORIZE_URL` with `consent=deny` — no BFF call.
