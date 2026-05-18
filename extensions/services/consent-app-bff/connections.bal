// Copyright (c) 2026, WSO2 LLC. (https://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;
import ballerina/oauth2;
import ballerina/url;

function buildIdpClientConfig() returns http:ClientConfiguration {
    http:ClientConfiguration config = {};
    if consentContextApiTrustStorePath != "" && consentContextApiTrustStorePassword != "" {
        config.secureSocket = {
            cert: {path: consentContextApiTrustStorePath, password: consentContextApiTrustStorePassword}
        };
    }
    return config;
}

// Plain HTTP clients — auth headers are set manually so 401s can be intercepted.
final http:Client idpClient = check new (idpBaseUrl, buildIdpClientConfig());
final http:Client openfgcClient = check new (openfgcBaseUrl);

// In-memory cache of consent purposes fetched from OpenFGC at startup.
// Keyed by purpose name. Populated by fetchAndCachePurposes() in init().
isolated map<CachedPurpose> purposeCache = {};

// Fetches all configured purpose definitions from OpenFGC and stores them in
// purposeCache. Called once at module init — fails hard if any purpose is missing.
function fetchAndCachePurposes() returns error? {
    // Collect all distinct purpose names: scope purpose + all purpose-flow purposes
    string[] namesToFetch = [scopeConsent.purposeName];
    foreach PurposeConsentConfig p in purposeConsent {
        boolean alreadyAdded = false;
        foreach string n in namesToFetch {
            if n == p.purposeName {
                alreadyAdded = true;
                break;
            }
        }
        if !alreadyAdded {
            namesToFetch.push(p.purposeName);
        }
    }

    map<string|string[]> headers = {"org-id": orgId, "TPP-client-id": tppClientId};

    foreach string name in namesToFetch {
        string encodedName = check url:encode(name, "UTF-8");
        string path = string `/consent-purposes?name=${encodedName}&clientIds=${tppClientId}`;
        log:printDebug("[OpenFGC] Fetching consent purpose at startup", purposeName = name);

        http:Response resp = check openfgcClient->get(path, headers);
        if resp.statusCode != http:STATUS_OK {
            string|error body = resp.getTextPayload();
            string bodyStr = body is string ? body : "";
            return error(string `Failed to fetch consent purpose '${name}': HTTP ${resp.statusCode}: ${bodyStr}`);
        }

        json purposesJson = check resp.getJsonPayload();
        OpenFGCConsentPurposesResponse purposesResp = check purposesJson.cloneWithType();

        if purposesResp.data.length() == 0 {
            return error(string `Consent purpose '${name}' not found in OpenFGC`);
        }

        OpenFGCConsentPurpose fetched = purposesResp.data[0];
        string[] elementNames = [];
        boolean anyMandatory = false;
        foreach OpenFGCPurposeElement e in fetched.elements {
            elementNames.push(e.name);
            if e.isMandatory {
                anyMandatory = true;
            }
        }

        CachedPurpose cached = {
            name: fetched.name,
            description: fetched.description,
            elementNames: elementNames.cloneReadOnly(),
            anyMandatory: anyMandatory
        };
        lock {
            purposeCache[name] = cached;
        }
        log:printDebug("[OpenFGC] Consent purpose cached", purposeName = name, elementCount = elementNames.length());
    }
}

// Resolves EHR launch context from the configured URL.
// Returns () if ehrContextResolveUrl is not configured or context not found.
isolated function resolveLaunchContext(string launchId) returns EhrLaunchContext?|error {
    if ehrContextResolveUrl == "" {
        return ();
    }
    http:ClientConfiguration ehrClientConfig = {};
    if consentContextApiTrustStorePath != "" && consentContextApiTrustStorePassword != "" {
        ehrClientConfig.secureSocket = {
            cert: {path: consentContextApiTrustStorePath, password: consentContextApiTrustStorePassword}
        };
    }
    http:Client ehrClient = check new (ehrContextResolveUrl, ehrClientConfig);
    http:Response response = check ehrClient->get(string `/launch/${launchId}`);
    if response.statusCode != 200 {
        string|error body = response.getTextPayload();
        string bodyStr = body is string ? body : "";
        return error(string `EHR context resolve returned ${response.statusCode}: ${bodyStr}`);
    }
    json payload = check response.getJsonPayload();
    EhrLaunchContext|error ctx = payload.cloneWithType();
    if ctx is error {
        return error(string `Failed to parse EHR launch context: ${ctx.message()}`);
    }
    return ctx;
}

// Returns a fresh bearer token from the identity provider using client credentials.
// A new ClientOAuth2Provider is created per call to avoid an eager token fetch at
// module init, which would fail in tests before mock listeners are up.
isolated function getIdpToken() returns string|error {
    string tokenUrl = idpTokenEndpoint == "" ? string `${idpBaseUrl}/oauth2/token` : idpTokenEndpoint;
    oauth2:ClientCredentialsGrantConfig grantConfig = {
        tokenUrl: tokenUrl,
        clientId: clientId,
        clientSecret: clientSecret,
        scopes: ["internal_user_mgt_view", "internal_user_mgt_list"]
    };
    if consentContextApiTrustStorePath != "" && consentContextApiTrustStorePassword != "" {
        grantConfig.clientConfig = {
            secureSocket: {
                cert: {
                    path: consentContextApiTrustStorePath,
                    password: consentContextApiTrustStorePassword
                }
            }
        };
    }
    oauth2:ClientOAuth2Provider provider = new (grantConfig);
    return check provider.generateToken();
}
