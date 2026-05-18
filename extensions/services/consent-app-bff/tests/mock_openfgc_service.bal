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

// In-process mock OpenFGC consent service used during bal test.
// Handles the minimal set of endpoints called by consent-app-bff.

listener http:Listener mockOpenfgcListener = new (9196);

boolean mockHasExistingConsent = false;

service / on mockOpenfgcListener {

    // GET /consents?userIds=...&clientIds=...  — consent search
    resource function get consents(string? userIds, string? clientIds, string? consentStatuses, int? 'limit)
            returns http:Response {
        http:Response response = new;

        if mockHasExistingConsent {
            json responseBody = {
                "data": [{
                    "id": "existing-consent-id",
                    "authorizations": [{
                        "type": "scope-authorization",
                        "status": "APPROVED",
                        "resources": {
                            "spId": "test-sp",
                            "application": "TestApp",
                            "scopes": ["patient/Observation.read"]
                        }
                    }]
                }]
            };
            response.statusCode = 200;
            response.setJsonPayload(responseBody);
        } else {
            response.statusCode = 200;
            response.setJsonPayload({"data": []});
        }

        return response;
    }

    // POST /consents — create new consent
    resource function post consents(@http:Payload json payload) returns http:Response {
        log:printInfo("Mock OpenFGC: consent created", payload = payload.toString());
        http:Response response = new;
        response.statusCode = 201;
        response.setJsonPayload({"id": "new-consent-id", "status": "CREATED"});
        return response;
    }

    // PUT /consents/{id} — update existing consent
    resource function put consents/[string consentId](@http:Payload json payload) returns http:Response {
        log:printInfo("Mock OpenFGC: consent updated", consentId = consentId);
        http:Response response = new;
        response.statusCode = 200;
        response.setJsonPayload({"id": consentId, "status": "ACTIVE"});
        return response;
    }

    // GET /consents/attributes?key=sessionDataKeyConsent&value=... — attribute lookup
    resource function get consents/attributes(string? key, string? value) returns http:Response {
        http:Response response = new;
        response.statusCode = 200;
        response.setJsonPayload({"consentIds": ["found-consent-id"], "count": 1});
        return response;
    }

    // GET /consents/{id} — get consent by ID
    resource function get consents/[string consentId]() returns http:Response {
        http:Response response = new;
        response.statusCode = 200;
        response.setJsonPayload({
            "id": consentId,
            "authorizations": [{
                "type": "scope-authorization",
                "status": "APPROVED",
                "resources": {
                    "spId": "test-sp",
                    "application": "TestApp",
                    "scopes": ["patient/Observation.read", "patient/Patient.read"]
                }
            }]
        });
        return response;
    }
}
