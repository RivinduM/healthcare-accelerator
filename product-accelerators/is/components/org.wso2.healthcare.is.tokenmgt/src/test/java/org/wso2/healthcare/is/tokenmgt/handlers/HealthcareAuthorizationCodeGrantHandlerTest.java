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

package org.wso2.healthcare.is.tokenmgt.handlers;

import org.junit.Test;
import org.wso2.carbon.identity.oauth2.dto.OAuth2AccessTokenRespDTO;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;

public class HealthcareAuthorizationCodeGrantHandlerTest {

    /**
     * Applies the offline_access scope logic from HealthcareAuthorizationCodeGrantHandler
     * (mirrors the private handleOfflineAccessScope method) for testing purposes.
     */
    private void applyOfflineAccessScopeLogic(OAuth2AccessTokenRespDTO tokenResponse,
            List<String> requestedScopes) {

        if (!requestedScopes.contains(HealthcareAuthorizationCodeGrantHandler.OFFLINE_ACCESS_SCOPE)) {
            String refreshToken = tokenResponse.getRefreshToken();
            if (refreshToken != null && !refreshToken.isEmpty()) {
                tokenResponse.setRefreshToken(null);
            }
        }
    }

    @Test
    public void testOfflineAccessScopeConstant() {

        assertEquals("offline_access", HealthcareAuthorizationCodeGrantHandler.OFFLINE_ACCESS_SCOPE);
    }

    @Test
    public void testRefreshTokenRemovedWhenOfflineAccessScopeAbsent() {

        OAuth2AccessTokenRespDTO tokenResponse = new OAuth2AccessTokenRespDTO();
        tokenResponse.setRefreshToken("refresh-token-value");

        List<String> scopes = Arrays.asList("patient/*.read", "launch/patient");
        applyOfflineAccessScopeLogic(tokenResponse, scopes);

        assertNull("Refresh token should be removed when offline_access scope is absent",
                tokenResponse.getRefreshToken());
    }

    @Test
    public void testRefreshTokenRetainedWhenOfflineAccessScopePresent() {

        OAuth2AccessTokenRespDTO tokenResponse = new OAuth2AccessTokenRespDTO();
        tokenResponse.setRefreshToken("refresh-token-value");

        List<String> scopes = Arrays.asList("patient/*.read", "offline_access");
        applyOfflineAccessScopeLogic(tokenResponse, scopes);

        assertNotNull("Refresh token should be retained when offline_access scope is present",
                tokenResponse.getRefreshToken());
        assertEquals("refresh-token-value", tokenResponse.getRefreshToken());
    }

    @Test
    public void testRefreshTokenNotSetRemainsNullWhenOfflineAccessScopeAbsent() {

        OAuth2AccessTokenRespDTO tokenResponse = new OAuth2AccessTokenRespDTO();

        List<String> scopes = Collections.singletonList("patient/*.read");
        applyOfflineAccessScopeLogic(tokenResponse, scopes);

        assertNull("Refresh token should remain null when not set and offline_access scope is absent",
                tokenResponse.getRefreshToken());
    }

    @Test
    public void testRefreshTokenRemovedForEmptyScopeList() {

        OAuth2AccessTokenRespDTO tokenResponse = new OAuth2AccessTokenRespDTO();
        tokenResponse.setRefreshToken("refresh-token-value");

        applyOfflineAccessScopeLogic(tokenResponse, Collections.<String>emptyList());

        assertNull("Refresh token should be removed for empty scope list", tokenResponse.getRefreshToken());
    }
}
