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
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package org.wso2.healthcare.is.tokenmgt.handlers;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.wso2.carbon.identity.oauth2.IdentityOAuth2Exception;
import org.wso2.carbon.identity.oauth2.dto.OAuth2AccessTokenRespDTO;
import org.wso2.carbon.identity.oauth2.token.OAuthTokenReqMessageContext;
import org.wso2.carbon.identity.oauth2.token.handlers.grant.AuthorizationCodeGrantHandler;

import java.util.Arrays;
import java.util.List;

/**
 * Custom grant handler for authorization code grant type to set the patient id in token call response according to the
 * SMART on FHIR specification -
 * http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#requesting-context-with-scopes
 * <p>
 * Need to add the following configuration in the WSO2 IS deployment.toml
 * <p>
 * [oauth.grant_type.authorization_code]
 * grant_handler = "org.wso2.healthcare.is.tokenmgt.handlers.HealthcareAuthorizationCodeGrantHandler"
 */
public class HealthcareAuthorizationCodeGrantHandler extends AuthorizationCodeGrantHandler {

    /**
     * As per the SMART on FHIR specification, the offline_access scope is required to obtain a refresh token.
     * http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#scopes-for-requesting-context-data
     * <p>
     * If this scope is not present in the requested scopes, the refresh token should be removed from the token response.
     */
    public static final String OFFLINE_ACCESS_SCOPE = "offline_access";

    private static final Log LOG = LogFactory.getLog(HealthcareAuthorizationCodeGrantHandler.class);

    @Override
    public OAuth2AccessTokenRespDTO issue(OAuthTokenReqMessageContext tokReqMsgCtx)
            throws IdentityOAuth2Exception {

        OAuth2AccessTokenRespDTO oAuth2AccessTokenRespDTO = super.issue(tokReqMsgCtx);

        List<String> requestedScopes = Arrays.asList(tokReqMsgCtx.getScope());

        // Handle offline_access scope: remove refresh token if offline_access scope is not present
        handleOfflineAccessScope(oAuth2AccessTokenRespDTO, requestedScopes);

        return oAuth2AccessTokenRespDTO;
    }

    /**
     * Handle offline_access scope according to SMART on FHIR specification.
     * If offline_access scope is not present in the requested scopes, remove the refresh token from the response.
     *
     * @param tokenResponse The OAuth2 access token response
     * @param requestedScopes List of requested scopes
     */
    private void handleOfflineAccessScope(OAuth2AccessTokenRespDTO tokenResponse, List<String> requestedScopes) {
        if (!requestedScopes.contains(OFFLINE_ACCESS_SCOPE)) {
            // Remove refresh token if offline_access scope is not present
            if (StringUtils.isNotBlank(tokenResponse.getRefreshToken())) {
                if (LOG.isDebugEnabled()) {
                    LOG.debug("offline_access scope not requested. Removing refresh token from the token response.");
                }
                tokenResponse.setRefreshToken(null);
            }
        } else {
            if (LOG.isDebugEnabled()) {
                LOG.debug("offline_access scope is present. Refresh token will be included in the token response.");
            }
        }
    }
}
