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
// Set to true to store launch contexts in memory instead of the H2 database.
configurable boolean inMemoryStore = false;

// ── In-memory store ───────────────────────────────────────────────────────────

isolated map<LaunchContextRecord> launchContextCache = {};

isolated function cachePut(string launchId, LaunchContextRecord launchCtx) {
    lock {
        launchContextCache[launchId] = launchCtx.clone();
    }
}

isolated function cacheGet(string launchId) returns LaunchContextRecord? {
    lock {
        return launchContextCache[launchId].clone();
    }
}

// ── Database client (only used when inMemoryStore = false) ────────────────────

jdbc:Client|error dbClientResult = inMemoryStore ? error("db disabled") : new (dbUrl, dbUser, dbPassword);

function init() returns error? {
    if inMemoryStore {
        log:printInfo("SMART launch context service running in in-memory mode");
        return;
    }
    if dbClientResult is error {
        return error("Failed to initialise database client: " + (<error>dbClientResult).message());
    }
    if dbClientResult is jdbc:Client {
        log:printInfo("SMART launch context service connected to database", url = dbUrl);
        jdbc:Client db = check dbClientResult;
        _ = check db->execute(`
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
            returns LaunchContextSaveResponse|http:InternalServerError|error {
        string launchId = uuid:createType4AsString();
        time:Utc expiry = time:utcAddSeconds(time:utcNow(), <decimal>expirySeconds);
        string expiryStr = time:utcToString(expiry);

        if inMemoryStore {
            cachePut(launchId, {
                launchId: launchId,
                aud: payload.aud,
                patientId: payload.patientId,
                encounterId: payload.encounterId,
                expiry: expiryStr
            });
            log:printDebug("Saved launch context in memory", launchId = launchId);
            return {launchId};
        }

        if dbClientResult is error {
            return <http:InternalServerError>{body: "Database not available"};
        }
        jdbc:Client db = check dbClientResult;
        sql:ExecutionResult|sql:Error result = db->execute(`
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
            returns LaunchContextResponse|EmptyResponse|http:InternalServerError|error {

        LaunchContextRecord? context = ();

        if inMemoryStore {
            context = cacheGet(launchId);
            if context is () {
                return <EmptyResponse>{};
            }
        } else {
            if dbClientResult is error {
                return <http:InternalServerError>{body: "Database not available"};
            }
            jdbc:Client db = check dbClientResult;
            LaunchContextRecord|sql:Error dbContext = db->queryRow(`
                SELECT LAUNCH_ID    AS launchId,
                       AUD          AS aud,
                       PATIENT_ID   AS patientId,
                       ENCOUNTER_ID AS encounterId,
                       EXPIRY       AS expiry
                FROM   LAUNCH_CONTEXT
                WHERE  LAUNCH_ID = ${launchId}
            `);

            if dbContext is sql:NoRowsError {
                return <EmptyResponse>{};
            }
            if dbContext is sql:Error {
                log:printError("Failed to retrieve launch context", dbContext);
                return <http:InternalServerError>{body: "Failed to retrieve launch context"};
            }
            context = dbContext;
        }

        LaunchContextRecord ctx = <LaunchContextRecord>context;
        time:Utc|error expiryUtc = time:utcFromString(ctx.expiry);
        if expiryUtc is error || time:utcDiffSeconds(time:utcNow(), expiryUtc) > 0d {
            return <EmptyResponse>{};
        }

        return {
            launchId: ctx.launchId,
            aud: ctx.aud,
            expiry: ctx.expiry,
            patientId: ctx.patientId ?: (),
            encounterId: ctx.encounterId ?: ()
        };
    }

}
