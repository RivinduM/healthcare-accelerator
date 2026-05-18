# WSO2 Healthcare Identity Server Accelerator

Provides healthcare-specific identity and access management capabilities for WSO2 Identity Server, enabling SMART on FHIR authorization flows.

## Components

### org.wso2.healthcare.is.smart.auth

SMART on FHIR token response handler. Registered as an OSGi service that IS invokes after token issuance to inject launch context into the response.

**Classes**:

| Class | Package | Role |
|---|---|---|
| `HealthcareSmartAuthTokenResponseHandler` | `org.wso2.healthcare.is.smart.auth` | Implements `AccessTokenResponseHandler`; adds `patient`, `practitioner`, or `encounter` to token responses |
| `UserClaimResolver` | `org.wso2.healthcare.is.smart.auth.util` | Resolves user claim values from the user store for an `AuthenticatedUser` |
| `Constants` | `org.wso2.healthcare.is.smart.auth.common` | Scope strings, claim URIs, attribute keys, and error codes |
| `HealthcareSmartServiceComponent` | `org.wso2.healthcare.is.smart.auth.internal` | OSGi `@Component`; registers `HealthcareSmartAuthTokenResponseHandler` as an `AccessTokenResponseHandler` service |
| `HealthcareSmartServiceDataHolder` | `org.wso2.healthcare.is.smart.auth.internal` | Singleton holding the `RealmService` OSGi reference |

**Supported launch scopes**:

| Scope | Token response parameter | Claim URI |
|---|---|---|
| `launch/patient` | `patient` | `http://wso2.org/claims/patient` |
| `launch/practitioner` | `practitioner` | `http://wso2.org/claims/practitioner` |
| `launch/encounter` | `encounter` | `http://wso2.org/claims/encounter` |

---

### org.wso2.healthcare.is.tokenmgt

Custom OAuth2 authorization code grant handler. Enforces the SMART on FHIR rule that refresh tokens are only issued when the `offline_access` scope is explicitly requested.

**Classes**:

| Class | Package | Role |
|---|---|---|
| `HealthcareAuthorizationCodeGrantHandler` | `org.wso2.healthcare.is.tokenmgt.handlers` | Extends `AuthorizationCodeGrantHandler`; removes refresh token from response when `offline_access` scope is absent |

---

## WSO2 Identity Sever Class Dependencies Matrix

### org.wso2.healthcare.is.smart.auth

| Healthcare Class | IS / Carbon Class | Method / Usage |
|---|---|---|
| `HealthcareSmartAuthTokenResponseHandler` | `AccessTokenResponseHandler` | `implements` — `Map<String, Object> getAdditionalTokenResponseAttributes(OAuthTokenReqMessageContext)` |
| `HealthcareSmartAuthTokenResponseHandler` | `OAuthTokenReqMessageContext` | `getScope()`, `getAuthorizedUser()` |
| `HealthcareSmartServiceComponent` | `RealmService` | OSGi mandatory reference — `setRealmService(RealmService)` / `unsetRealmService(RealmService)` |
| `HealthcareSmartServiceComponent` | `OAuth2Service` | OSGi mandatory reference — `setOAuth2Service(OAuth2Service)` / `unsetOAuth2Service(OAuth2Service)` |
| `HealthcareSmartServiceComponent` | `AccessTokenResponseHandler` | `BundleContext.registerService(AccessTokenResponseHandler.class.getName(), ...)` |
| `UserClaimResolver` | `AuthenticatedUser` | `getTenantDomain()`, `getUserStoreDomain()`, `toFullQualifiedUsername()` |
| `UserClaimResolver` | `AuthenticationFailedException` | thrown on user store / realm access failures |
| `UserClaimResolver` | `IdentityTenantUtil` | `getTenantId(String tenantDomain)` |
| `UserClaimResolver` | `UserRealm` | `getUserStoreManager()` |
| `UserClaimResolver` | `UserStoreManager` | `getUserClaimValues(String username, String[] claimURIs, String profileName)` |
| `UserClaimResolver` | `AbstractUserStoreManager` | `getSecondaryUserStoreManager(String userStoreDomain)` |
| `UserClaimResolver` | `MultitenantUtils` | `getTenantAwareUsername(String username)` |
| `HealthcareSmartServiceDataHolder` | `RealmService` | `getTenantUserRealm(int tenantId)` |

### org.wso2.healthcare.is.tokenmgt

| Healthcare Class | IS / Carbon Class | Method / Usage |
|---|---|---|
| `HealthcareAuthorizationCodeGrantHandler` | `AuthorizationCodeGrantHandler` | `extends` — `OAuth2AccessTokenRespDTO issue(OAuthTokenReqMessageContext)` |
| `HealthcareAuthorizationCodeGrantHandler` | `OAuth2AccessTokenRespDTO` | `getRefreshToken()`, `setRefreshToken(String)` |
| `HealthcareAuthorizationCodeGrantHandler` | `OAuthTokenReqMessageContext` | `getScope()` |
| `HealthcareAuthorizationCodeGrantHandler` | `IdentityOAuth2Exception` | thrown by overridden `issue(...)` |

---

## Building

```bash
# All IS components
cd product-accelerators/is
mvn clean install

# Single component
cd product-accelerators/is/components/org.wso2.healthcare.is.smart.auth
mvn clean install
```

## Deployment

See [distribution/is-accelerator/README.md](../../distribution/is-accelerator/README.md) for installation instructions using `merge.sh`.

## License

Copyright (c) 2026, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.

Licensed under the Apache License, Version 2.0.
