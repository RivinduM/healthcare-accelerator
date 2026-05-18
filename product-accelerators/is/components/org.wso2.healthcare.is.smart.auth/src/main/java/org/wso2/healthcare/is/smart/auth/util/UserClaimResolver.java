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

package org.wso2.healthcare.is.smart.auth.util;

import org.wso2.healthcare.is.smart.auth.common.Constants;
import org.wso2.healthcare.is.smart.auth.internal.HealthcareSmartServiceDataHolder;
import org.apache.commons.lang.StringUtils;
import org.wso2.carbon.identity.application.authentication.framework.exception.AuthenticationFailedException;
import org.wso2.carbon.identity.application.authentication.framework.model.AuthenticatedUser;
import org.wso2.carbon.identity.core.util.IdentityTenantUtil;
import org.wso2.carbon.user.api.UserRealm;
import org.wso2.carbon.user.api.UserStoreException;
import org.wso2.carbon.user.api.UserStoreManager;
import org.wso2.carbon.user.core.common.AbstractUserStoreManager;
import org.wso2.carbon.utils.multitenancy.MultitenantUtils;

import java.util.Map;

import static org.wso2.carbon.user.core.UserCoreConstants.PRIMARY_DEFAULT_DOMAIN_NAME;

/**
 * Holds utility functions to access user claim values from the user store for the user.
 */
public class UserClaimResolver {

    /**
     * Returns user claims value for the given claim uri for the authenticated user.
     *
     * @param claimUri          Claim URI.
     * @param authenticatedUser Authenticate user.
     * @return Extracted claim value for the claim uri
     * @throws AuthenticationFailedException When error occurs for accessing {@link UserStoreManager}.
     */
    public String getUserClaimValue(String claimUri, AuthenticatedUser authenticatedUser)
            throws AuthenticationFailedException {

        UserStoreManager userStoreManager = getUserStoreManager(authenticatedUser);
        try {
            Map<String, String> claimValues =
                    userStoreManager.getUserClaimValues(MultitenantUtils.getTenantAwareUsername(
                            authenticatedUser.toFullQualifiedUsername()), new String[]{claimUri}, null);
            return claimValues.get(claimUri);
        } catch (UserStoreException e) {
            throw new AuthenticationFailedException(
                    Constants.ErrorMessages.ERROR_CODE_ERROR_GETTING_HEALTHCARE_CLAIM.getCode(),
                    String.format(Constants.ErrorMessages.ERROR_CODE_ERROR_GETTING_HEALTHCARE_CLAIM.getMessage(),
                            claimUri), e);
        }
    }

    /**
     * Used to get the user store manager instance for the authenticated user.
     *
     * @param authenticatedUser Authenticated user.
     * @return UserStoreManager instance.
     * @throws AuthenticationFailedException When retrieving UserStoreManager instance.
     */
    private UserStoreManager getUserStoreManager(AuthenticatedUser authenticatedUser)
            throws AuthenticationFailedException {

        UserRealm userRealm = getTenantUserRealm(authenticatedUser.getTenantDomain());
        String username = MultitenantUtils.getTenantAwareUsername(authenticatedUser.toFullQualifiedUsername());
        String userStoreDomain = authenticatedUser.getUserStoreDomain();
        try {
            UserStoreManager userStoreManager = userRealm.getUserStoreManager();
            if (userStoreManager == null) {
                throw new AuthenticationFailedException(
                        Constants.ErrorMessages.ERROR_CODE_ERROR_GETTING_USER_STORE_MANAGER.getCode(),
                        String.format(Constants.ErrorMessages.ERROR_CODE_ERROR_GETTING_USER_STORE_MANAGER.getMessage(),
                                username));
            }
            if (StringUtils.isBlank(userStoreDomain) || PRIMARY_DEFAULT_DOMAIN_NAME.equals(userStoreDomain)) {
                return userStoreManager;
            }
            return ((AbstractUserStoreManager) userStoreManager).getSecondaryUserStoreManager(userStoreDomain);
        } catch (UserStoreException e) {
            throw new AuthenticationFailedException(
                    Constants.ErrorMessages.ERROR_CODE_ERROR_GETTING_USER_STORE_MANAGER.getCode(),
                    String.format(Constants.ErrorMessages.ERROR_CODE_ERROR_GETTING_USER_STORE_MANAGER.getMessage(),
                            username), e);
        }
    }

    private UserRealm getTenantUserRealm(String tenantDomain) throws AuthenticationFailedException {

        int tenantId = IdentityTenantUtil.getTenantId(tenantDomain);
        UserRealm userRealm;
        try {
            userRealm = (HealthcareSmartServiceDataHolder.getRealmService()).getTenantUserRealm(tenantId);
        } catch (UserStoreException e) {
            throw new AuthenticationFailedException(
                    Constants.ErrorMessages.ERROR_CODE_ERROR_GETTING_USER_REALM.getCode(),
                    String.format(Constants.ErrorMessages.ERROR_CODE_ERROR_GETTING_USER_REALM.getMessage(),
                            tenantDomain), e);
        }
        if (userRealm == null) {
            throw new AuthenticationFailedException(
                    Constants.ErrorMessages.ERROR_CODE_ERROR_GETTING_USER_REALM.getCode(),
                    String.format(Constants.ErrorMessages.ERROR_CODE_ERROR_GETTING_USER_REALM.getMessage(),
                            tenantDomain));
        }
        return userRealm;
    }
}
