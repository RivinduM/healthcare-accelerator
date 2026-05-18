// Copyright (c) 2026, WSO2 LLC. (https://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License. You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import ballerina/http;

listener http:Listener mockOpenfgcListener = new (9296);

// Set to a non-empty string to simulate a consent being found for attribute lookup
string mockConsentId = "test-consent-id";

// Scopes returned by GET /consents/{id}
string[] mockApprovedScopes = ["patient/Patient.read", "patient/Observation.read", "openid"];

service / on mockOpenfgcListener {

    // GET /consents/attributes?key=sessionDataKeyConsent&value=...
    resource function get consents/attributes(string? key, string? value) returns http:Response {
        http:Response response = new;
        if mockConsentId == "" {
            response.statusCode = 200;
            response.setJsonPayload({"consentIds": [], "count": 0});
        } else {
            response.statusCode = 200;
            response.setJsonPayload({"consentIds": [mockConsentId], "count": 1});
        }
        return response;
    }

    // GET /consents/{id}
    resource function get consents/[string consentId]() returns http:Response {
        http:Response response = new;
        json[] scopesJson = [];
        foreach string s in mockApprovedScopes {
            scopesJson.push(s);
        }
        response.statusCode = 200;
        response.setJsonPayload({
            "id": consentId,
            "authorizations": [{
                "type": "scope-authorization",
                "status": "APPROVED",
                "resources": {
                    "spId": "test-sp",
                    "application": "TestApp",
                    "scopes": scopesJson
                }
            }]
        });
        return response;
    }
}
