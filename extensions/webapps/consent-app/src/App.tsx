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

import { useEffect, useRef, useState } from 'react';
import { Routes, Route, Navigate, useSearchParams } from 'react-router-dom';
import { Box, CircularProgress, Typography } from '@wso2/oxygen-ui';
import { getConsentData } from './api';
import ScopeConsentPage from './ScopeConsentPage';
import PurposeConsentPage from './PurposeConsentPage';
import PatientPickerPage from './PatientPickerPage';
import type { ConsentData, ConsentPatient, ScopeConsentData, PurposeConsentData, RedirectConsentData } from './types';

const IDP_AUTHORIZE_URL = window.config?.IDP_AUTHORIZE_URL || '';

function AutoApproveScopePage({ sessionDataKeyConsent }: { sessionDataKeyConsent: string }) {
  const submitted = useRef(false);
  useEffect(() => {
    if (submitted.current) return;
    submitted.current = true;
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = IDP_AUTHORIZE_URL;
    const add = (name: string, value: string) => {
      const el = document.createElement('input');
      el.type = 'hidden';
      el.name = name;
      el.value = value;
      form.appendChild(el);
    };
    add('sessionDataKeyConsent', sessionDataKeyConsent);
    add('consent', 'approve');
    add('hasApprovedAlways', 'false');
    add('user_claims_consent', 'true');
    document.body.appendChild(form);
    form.submit();
  }, [sessionDataKeyConsent]);

  return (
    <Box sx={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <CircularProgress size={36} />
    </Box>
  );
}

function ConsentRoute() {
  const [searchParams] = useSearchParams();
  const sessionDataKeyConsent = searchParams.get('sessionDataKeyConsent') ?? '';
  const spId = searchParams.get('spId') ?? '';

  const [data, setData] = useState<ConsentData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedPatient, setSelectedPatient] = useState<ConsentPatient | null>(null);

  useEffect(() => {
    if (!sessionDataKeyConsent) {
      setError('Missing sessionDataKeyConsent parameter.');
      setLoading(false);
      return;
    }
    getConsentData(sessionDataKeyConsent, spId)
      .then((d) => {
        if (d.flow === 'redirect') {
          window.location.replace((d as RedirectConsentData).redirectUrl);
          return;
        }
        setData(d);
      })
      .catch((err: unknown) => {
        console.error('Failed to load consent data', err);
        setError('Failed to load consent data. Please try again.');
      })
      .finally(() => setLoading(false));
  }, [sessionDataKeyConsent, spId]);

  if (loading) {
    return (
      <Box sx={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <CircularProgress size={36} />
      </Box>
    );
  }

  if (error || !data) {
    return (
      <Box sx={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', p: 3 }}>
        <Typography sx={{ fontSize: '3rem', mb: 2, lineHeight: 1 }}>😔</Typography>
        <Typography variant="h5" sx={{ fontWeight: 700, mb: 1 }}>
          Oops, something went wrong.
        </Typography>
        <Typography variant="body2" color="text.secondary">
          {error ?? 'Please try again later or contact support.'}
        </Typography>
      </Box>
    );
  }

  if (data.flow === 'scope') {
    const scopeData = data as ScopeConsentData;
    if (scopeData.scopes.length === 0) {
      return <AutoApproveScopePage sessionDataKeyConsent={sessionDataKeyConsent} />;
    }
    if (scopeData.isPractitioner && !selectedPatient && (scopeData.patients?.length ?? 0) > 0) {
      return (
        <PatientPickerPage
          patients={scopeData.patients ?? []}
          user={scopeData.user}
          onProceed={setSelectedPatient}
          onCancel={() => {
            // Deny: form POST directly to IDP with consent=deny
            const authorizeUrl = IDP_AUTHORIZE_URL;
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = authorizeUrl;
            const field = document.createElement('input');
            field.type = 'hidden';
            field.name = 'sessionDataKeyConsent';
            field.value = sessionDataKeyConsent;
            form.appendChild(field);
            const consentField = document.createElement('input');
            consentField.type = 'hidden';
            consentField.name = 'consent';
            consentField.value = 'deny';
            form.appendChild(consentField);
            document.body.appendChild(form);
            form.submit();
          }}
        />
      );
    }
    return <ScopeConsentPage data={scopeData} selectedPatient={selectedPatient} />;
  }

  return <PurposeConsentPage data={data as PurposeConsentData} />;
}

function RedirectToConsentPage() {
  const [searchParams] = useSearchParams();
  return <Navigate to={`/home?${searchParams.toString()}`} replace />;
}

export default function App() {
  return (
    <Routes>
      <Route path="/home" element={<ConsentRoute />} />
      <Route path="*" element={<RedirectToConsentPage />} />
    </Routes>
  );
}
