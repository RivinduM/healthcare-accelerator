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

listener http:Listener mockScimListener = new (9297);

boolean mockUserIsPatient = true;

service / on mockScimListener {

    // POST /oauth2/token — returns a dummy bearer token for client credentials requests
    resource function post oauth2/token() returns http:Response {
        http:Response response = new;
        response.statusCode = 200;
        response.setJsonPayload({
            "access_token": "mock-scim-token",
            "token_type": "Bearer",
            "expires_in": 3600
        });
        return response;
    }

    // GET /scim2/Users/{userId}
    resource function get scim2/Users/[string userId]() returns http:Response {
        http:Response response = new;
        response.statusCode = 200;

        if mockUserIsPatient {
            response.setJsonPayload({
                "id": userId,
                "userName": "patient-user",
                "groups": [{"display": "patient", "value": "patient-group-id"}],
                "urn:scim:schemas:extension:custom:User": {
                    "fhirUser": "Patient/patient-123"
                }
            });
        } else {
            response.setJsonPayload({
                "id": userId,
                "userName": "regular-user",
                "groups": [],
                "urn:scim:schemas:extension:custom:User": {
                    "fhirUser": ""
                }
            });
        }
        return response;
    }
}
