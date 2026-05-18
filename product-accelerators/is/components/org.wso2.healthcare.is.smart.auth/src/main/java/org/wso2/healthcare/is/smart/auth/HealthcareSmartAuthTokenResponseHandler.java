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

package org.wso2.healthcare.is.smart.auth;

import org.wso2.healthcare.is.smart.auth.common.Constants;
import org.wso2.healthcare.is.smart.auth.util.UserClaimResolver;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.wso2.carbon.identity.application.authentication.framework.exception.AuthenticationFailedException;
import org.wso2.carbon.identity.application.authentication.framework.model.AuthenticatedUser;
import org.wso2.carbon.identity.oauth2.IdentityOAuth2Exception;
import org.wso2.carbon.identity.oauth2.token.OAuthTokenReqMessageContext;
import org.wso2.carbon.identity.oauth2.token.handlers.response.AccessTokenResponseHandler;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Implementation of the access token response modifications required by
 * <a href="https://hl7.org/fhir/smart-app-launch/">SMART on FHIR spec</a>.
 */
public class HealthcareSmartAuthTokenResponseHandler implements AccessTokenResponseHandler {

    private static final Log LOG = LogFactory.getLog(HealthcareSmartAuthTokenResponseHandler.class);

    @Override
    public Map<String, Object> getAdditionalTokenResponseAttributes(
            OAuthTokenReqMessageContext oAuthTokenReqMessageContext) throws IdentityOAuth2Exception {

        List<String> launchScopes = new ArrayList<>();
        String[] requestedScopes = oAuthTokenReqMessageContext.getScope();
        for (String scope : requestedScopes) {
            if (scope.startsWith(Constants.LAUNCH_SCOPE_PREFIX)) {
                launchScopes.add(scope);
            }
        }
        if (launchScopes.size() == 0) {
            return null;
        }
        Map<String, Object> attributes = new HashMap<>();
        AuthenticatedUser authorizedUser = oAuthTokenReqMessageContext.getAuthorizedUser();
        try {
            UserClaimResolver claimResolver = new UserClaimResolver();
            if (launchScopes.contains(Constants.PATIENT_LAUNCH_SCOPE)) {
                // gets the patient id claim's value
                String patientId = claimResolver.getUserClaimValue(Constants.DEFAULT_PATIENT_ID_CLAIM_URI,
                        authorizedUser);
                attributes.put(Constants.PATIENT_ATTRIBUTE, patientId);
            } else if (launchScopes.contains(Constants.PRACTITIONER_LAUNCH_SCOPE)) {
                // gets the practitioner id claim's value
                String practitionerId = claimResolver.getUserClaimValue(Constants.DEFAULT_PRACTITIONER_ID_CLAIM_URI,
                        authorizedUser);
                attributes.put(Constants.PRACTITIONER_ATTRIBUTE, practitionerId);
            }
            else if (launchScopes.contains(Constants.ENCOUNTER_LAUNCH_SCOPE)) {
                // gets the encounter id claim's value;
                // this value need to be resolved from EHR; for now, we are adding it as a user claim
                String practitionerId = claimResolver.getUserClaimValue(Constants.DEFAULT_ENCOUNTER_ID_CLAIM_URI,
                        authorizedUser);
                attributes.put(Constants.ENCOUNTER_ATTRIBUTE, practitionerId);
            }
        } catch (AuthenticationFailedException e) {
            LOG.error("Unable to add patient context to the token response: Error occurred while retrieving claim " +
                    "configurations from Open Healthcare environment.", e);
        }
        return attributes;
    }
}
