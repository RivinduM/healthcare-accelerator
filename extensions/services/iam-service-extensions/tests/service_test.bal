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
import ballerina/test;

final http:Client iamClient = check new ("http://localhost:9093");

// ─── Helper: build a minimal pre-issue-access-token payload ──────────────────

function buildPayload(string[] scopes, string grantType, string sessionKey, string? userId) returns json {
    map<json> sessionMap = {"sessionDataKeyConsent": sessionKey};
    map<json> event = {
        "request": {
            "grantType": grantType,
            "clientId": "test-client",
            "scopes": scopes
        },
        "tenant": {"id": "1", "name": "carbon.super"},
        "accessToken": {
            "tokenType": "JWT",
            "claims": [],
            "scopes": scopes
        },
        "session": sessionMap
    };
    if userId is string {
        event["user"] = {"id": userId};
    }
    return {
        "actionType": "PRE_ISSUE_ACCESS_TOKEN",
        "event": event
    };
}

// ─── Test: scope approval from OpenFGC ───────────────────────────────────────

@test:Config {}
function testScopeApprovalFromOpenFGC() returns error? {
    // mockApprovedScopes = ["patient/Patient.read", "patient/Observation.read", "openid"]
    // requesting patient/Patient.read → should be in final token
    json payload = buildPayload(
        ["patient/Patient.read", "patient/Observation.read", "openid"],
        "authorization_code",
        "consent-key-001",
        ()
    );

    http:Response response = check iamClient->post("/pre-issue-access-token", payload);
    test:assertEquals(response.statusCode, 200);

    json body = check response.getJsonPayload();
    map<json> bodyMap = check body.ensureType();
    test:assertEquals(bodyMap["actionStatus"], "SUCCESS");

    // Operations should contain add scope entries for the approved scopes
    json[] ops = check (bodyMap["operations"] ?: []).ensureType();
    boolean hasAddScope = false;
    foreach json op in ops {
        map<json> opMap = check op.ensureType();
        if opMap["op"] == "add" && opMap["path"].toString().includes("/accessToken/scopes/") {
            hasAddScope = true;
        }
    }
    test:assertTrue(hasAddScope);
}

// ─── Test: patient claim injected from OH_patient/ in approved scopes ─────────

@test:Config {}
function testPatientClaimInjection() returns error? {
    // Add OH_patient/ to mockApprovedScopes for this test
    mockApprovedScopes = ["patient/Patient.read", "openid", "OH_patient/patient-456"];

    json payload = buildPayload(
        ["patient/Patient.read", "openid"],
        "authorization_code",
        "consent-key-002",
        ()
    );

    http:Response response = check iamClient->post("/pre-issue-access-token", payload);
    test:assertEquals(response.statusCode, 200);

    json body = check response.getJsonPayload();
    map<json> bodyMap = check body.ensureType();
    test:assertEquals(bodyMap["actionStatus"], "SUCCESS");

    json[] ops = check (bodyMap["operations"] ?: []).ensureType();
    boolean hasPatientClaim = false;
    foreach json op in ops {
        map<json> opMap = check op.ensureType();
        if opMap["op"] == "add" && opMap["path"].toString() == "/accessToken/claims/-" {
            json val = opMap["value"] ?: {};
            if val is map<json> && val["name"] == "patient" && val["value"] == "patient-456" {
                hasPatientClaim = true;
            }
        }
    }
    test:assertTrue(hasPatientClaim);

    // Reset
    mockApprovedScopes = ["patient/Patient.read", "patient/Observation.read", "openid"];
}

// ─── Test: system/* blocked for non-client_credentials ────────────────────────

@test:Config {}
function testSystemScopeGrantTypeEnforcement() returns error? {
    mockApprovedScopes = ["system/Patient.read", "openid"];

    json payload = buildPayload(
        ["system/Patient.read", "openid"],
        "authorization_code",  // NOT client_credentials
        "consent-key-003",
        ()
    );

    http:Response response = check iamClient->post("/pre-issue-access-token", payload);
    test:assertEquals(response.statusCode, 200);

    json body = check response.getJsonPayload();
    map<json> bodyMap = check body.ensureType();
    test:assertEquals(bodyMap["actionStatus"], "SUCCESS");

    // system/Patient.read should NOT be added (blocked for authorization_code)
    json[] ops = check (bodyMap["operations"] ?: []).ensureType();
    foreach json op in ops {
        map<json> opMap = check op.ensureType();
        if opMap["op"] == "add" {
            string opVal = opMap["value"].toString();
            test:assertFalse(opVal.startsWith("system/"), string `system/ scope should not be in token: ${opVal}`);
        }
    }

    // Reset
    mockApprovedScopes = ["patient/Patient.read", "patient/Observation.read", "openid"];
}

// ─── Test: no consent found → SUCCESS with no scope operations ───────────────

@test:Config {}
function testNoConsentFound() returns error? {
    mockConsentId = "";  // Simulate no consent in OpenFGC

    json payload = buildPayload(
        ["patient/Patient.read"],
        "authorization_code",
        "unknown-key",
        ()
    );

    http:Response response = check iamClient->post("/pre-issue-access-token", payload);
    test:assertEquals(response.statusCode, 200);

    json body = check response.getJsonPayload();
    map<json> bodyMap = check body.ensureType();
    test:assertEquals(bodyMap["actionStatus"], "SUCCESS");

    // When no consent found, operations should be empty (pass-through)
    json[] ops = check (bodyMap["operations"] ?: []).ensureType();
    test:assertEquals(ops.length(), 0);

    // Reset
    mockConsentId = "test-consent-id";
}

// ─── Test: alwaysAllowedScopes (openid) passes through regardless ─────────────

@test:Config {}
function testAlwaysAllowedScopes() returns error? {
    // approved scopes don't include openid — but alwaysAllowedScopes does
    mockApprovedScopes = ["patient/Patient.read"];

    json payload = buildPayload(
        ["patient/Patient.read", "openid"],
        "authorization_code",
        "consent-key-005",
        ()
    );

    http:Response response = check iamClient->post("/pre-issue-access-token", payload);
    test:assertEquals(response.statusCode, 200);

    json body = check response.getJsonPayload();
    map<json> bodyMap = check body.ensureType();
    test:assertEquals(bodyMap["actionStatus"], "SUCCESS");

    json[] ops = check (bodyMap["operations"] ?: []).ensureType();
    boolean hasOpenid = false;
    foreach json op in ops {
        map<json> opMap = check op.ensureType();
        if opMap["op"] == "add" && opMap["value"] == "openid" {
            hasOpenid = true;
        }
    }
    test:assertTrue(hasOpenid);

    // Reset
    mockApprovedScopes = ["patient/Patient.read", "patient/Observation.read", "openid"];
}
