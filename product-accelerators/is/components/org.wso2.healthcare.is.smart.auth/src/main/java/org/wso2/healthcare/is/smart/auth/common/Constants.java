/*
 * Copyright (c) 2026, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.wso2.healthcare.is.smart.auth.common;

/**
 * Holds constants used in the component.
 */
public class Constants {

    public static final String HEALTHCARE_SMART_AUTH_COMPONENT = "SMART";

    public static final String LAUNCH_SCOPE_PREFIX = "launch/";
    public static final String PATIENT_LAUNCH_SCOPE = "launch/patient";
    public static final String PRACTITIONER_LAUNCH_SCOPE = "launch/practitioner";
    public static final String ENCOUNTER_LAUNCH_SCOPE = "launch/practitioner";
    public static final String DEFAULT_PATIENT_ID_CLAIM_URI = "http://wso2.org/claims/patient";
    public static final String DEFAULT_PRACTITIONER_ID_CLAIM_URI = "http://wso2.org/claims/practitioner";
    public static final String DEFAULT_ENCOUNTER_ID_CLAIM_URI = "http://wso2.org/claims/practitioner";
    public static final String PATIENT_ATTRIBUTE = "patient";
    public static final String PRACTITIONER_ATTRIBUTE = "practitioner";
    public static final String ENCOUNTER_ATTRIBUTE = "encounter";

    /**
     * Error message codes to be used for the healthcare SMART component.
     */
    public enum ErrorMessages {
        ERROR_CODE_ERROR_GETTING_USER_STORE_MANAGER("95001",
                "Error occurred while getting the user store manager for the user: %s"),
        ERROR_CODE_ERROR_GETTING_USER_REALM("95002",
                "Error occurred while getting the user realm for tenant: %s"),
        ERROR_CODE_ERROR_GETTING_HEALTHCARE_CLAIM("95003",
                "Error occurred while getting the healthcare claim: %s");

        private final String code;
        private final String message;

        ErrorMessages(String code, String message) {

            this.code = code;
            this.message = message;
        }

        public String getCode() {

            return HEALTHCARE_SMART_AUTH_COMPONENT + "-" + code;
        }

        public String getMessage() {

            return message;
        }
    }
}
