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

package org.wso2.healthcare.is.smart.auth.internal;

import org.wso2.healthcare.is.smart.auth.HealthcareSmartAuthTokenResponseHandler;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.osgi.framework.BundleContext;
import org.osgi.service.component.ComponentContext;
import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Deactivate;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.osgi.service.component.annotations.ReferencePolicy;
import org.wso2.carbon.identity.oauth2.OAuth2Service;
import org.wso2.carbon.identity.oauth2.token.handlers.response.AccessTokenResponseHandler;
import org.wso2.carbon.user.core.service.RealmService;

/**
 * Healthcare SMART on FHIR Auth component.
 */
@Component(
        name = "org.wso2.healthcare.is.smart.auth.HealthcareSmartServiceComponent",
        immediate = true)
public class HealthcareSmartServiceComponent {

    private static final Log LOG = LogFactory.getLog(HealthcareSmartServiceComponent.class);

    @Activate
    protected void activate(ComponentContext componentContext) {

        try {
            BundleContext bundleContext = componentContext.getBundleContext();
            bundleContext.registerService(AccessTokenResponseHandler.class.getName(),
                    new HealthcareSmartAuthTokenResponseHandler(), null);
            if (LOG.isDebugEnabled()) {
                LOG.debug("Healthcare SMART Auth service component activated.");
            }
        } catch (Throwable e) {
            LOG.error("Error occurred while activating Healthcare SMART Auth service component.", e);
        }
    }

    @Deactivate
    protected void deactivate(ComponentContext context) {

        if (LOG.isDebugEnabled()) {
            LOG.debug("Healthcare SMART Auth service component deactivated.");
        }
    }

    @Reference(
            name = "RealmService",
            service = org.wso2.carbon.user.core.service.RealmService.class,
            cardinality = ReferenceCardinality.MANDATORY,
            policy = ReferencePolicy.DYNAMIC,
            unbind = "unsetRealmService")
    protected void setRealmService(RealmService realmService) {

        HealthcareSmartServiceDataHolder.setRealmService(realmService);
    }

    protected void unsetRealmService(RealmService realmService) {

        HealthcareSmartServiceDataHolder.setRealmService(null);
    }

    @Reference(
            name = "OAuth2Service",
            service = OAuth2Service.class,
            cardinality = ReferenceCardinality.MANDATORY,
            policy = ReferencePolicy.DYNAMIC,
            unbind = "unsetOAuth2Service")
    protected void setOAuth2Service(OAuth2Service oauth2Service) {
        //waiting the component activation once the OAuth2Service is available.
        if (LOG.isDebugEnabled()) {
            LOG.debug("Setting OAuthService reference.");
        }
    }

    protected void unsetOAuth2Service(OAuth2Service oauth2Service) {
        if (LOG.isDebugEnabled()) {
            LOG.debug("Unsetting OAuthService reference.");
        }
    }
}
