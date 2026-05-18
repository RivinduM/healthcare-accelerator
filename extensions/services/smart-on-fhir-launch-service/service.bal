// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerina/uuid;
import ballerinax/java.jdbc;

configurable string dbUrl = "jdbc:h2:./data/launch_context;AUTO_SERVER=TRUE";
configurable string dbUser = "sa";
configurable string dbPassword = "";
configurable int port = 9092;
configurable int expirySeconds = 300;

final jdbc:Client dbClient = check new (dbUrl, dbUser, dbPassword);

function init() returns error? {
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS LAUNCH_CONTEXT (
            LAUNCH_ID    VARCHAR(36)  PRIMARY KEY,
            AUD          VARCHAR(500) NOT NULL,
            PATIENT_ID   VARCHAR(255) NOT NULL,
            ENCOUNTER_ID VARCHAR(255),
            EXPIRY       VARCHAR(50)  NOT NULL
        )
    `);
    log:printInfo("SMART launch context database initialized");
}

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowHeaders: ["Content-Type", "Authorization"],
        allowMethods: ["GET", "POST", "OPTIONS"]
    }
}
service / on new http:Listener(port) {

    # Save a new SMART launch context and return the generated launch ID.
    resource function post launch(@http:Payload LaunchContextRequest payload)
            returns LaunchContextSaveResponse|http:InternalServerError {
        string launchId = uuid:createType4AsString();
        time:Utc expiry = time:utcAddSeconds(time:utcNow(), <decimal>expirySeconds);
        string expiryStr = time:utcToString(expiry);

        sql:ExecutionResult|sql:Error result = dbClient->execute(`
            INSERT INTO LAUNCH_CONTEXT (LAUNCH_ID, AUD, PATIENT_ID, ENCOUNTER_ID, EXPIRY)
            VALUES (${launchId}, ${payload.aud}, ${payload.patientId},
                    ${payload.encounterId}, ${expiryStr})
        `);

        if result is sql:Error {
            log:printError("Failed to save launch context", result);
            return <http:InternalServerError>{body: "Failed to save launch context"};
        }

        return {launchId};
    }

    # Retrieve a SMART launch context by launch ID.
    resource function get launch/[string launchId]()
            returns LaunchContextResponse|EmptyResponse|http:InternalServerError {
        LaunchContextRecord|sql:Error context = dbClient->queryRow(`
            SELECT LAUNCH_ID    AS launchId,
                   AUD          AS aud,
                   PATIENT_ID   AS patientId,
                   ENCOUNTER_ID AS encounterId,
                   EXPIRY       AS expiry
            FROM   LAUNCH_CONTEXT
            WHERE  LAUNCH_ID = ${launchId}
        `);

        if context is sql:NoRowsError {
            return <EmptyResponse>{};
        }
        if context is sql:Error {
            log:printError("Failed to retrieve launch context", context);
            return <http:InternalServerError>{body: "Failed to retrieve launch context"};
        }

        time:Utc|error expiryUtc = time:utcFromString(context.expiry);
        if expiryUtc is error || time:utcDiffSeconds(time:utcNow(), expiryUtc) > 0d {
            return <EmptyResponse>{};
        }

        LaunchContextResponse response = {
            launchId: context.launchId,
            aud: context.aud,
            expiry: context.expiry,
            patientId: context.patientId ?: (),
            encounterId: context.encounterId ?: ()
        };

        return response;
    }

}
