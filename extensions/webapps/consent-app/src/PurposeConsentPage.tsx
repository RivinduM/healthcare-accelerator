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

import { useState, useEffect, useRef } from 'react';
import { Box, Button, Checkbox, CircularProgress, FormControlLabel, Paper, Typography } from '@wso2/oxygen-ui';
import Alert from '@mui/material/Alert';
import Snackbar from '@mui/material/Snackbar';
import { submitConsent } from './api';
import type { PurposeConsentData, ConsentPurpose } from './types';

const IDP_AUTHORIZE_URL = window.config?.IDP_AUTHORIZE_URL || '';

function parseMandatoryClaims(raw: string): Array<{ id: string }> {
  if (!raw) return [];
  return raw.split(',').map((c) => {
    const idx = c.indexOf('_');
    return { id: idx >= 0 ? c.slice(0, idx) : c };
  });
}

function submitIdpForm(
  sessionDataKeyConsent: string,
  approved: boolean,
  options?: { scopes?: string[]; claims?: Array<{ id: string }> },
) {
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
  add('consent', approved ? 'approve' : 'deny');
  add('hasApprovedAlways', 'false');
  if (approved) {
    add('user_claims_consent', 'true');
    for (const claim of options?.claims ?? []) {
      add(`consent_${claim.id}`, 'approved');
    }
    if (options?.scopes && options.scopes.length > 0) add('scope', options.scopes.join(' '));
  }

  document.body.appendChild(form);
  form.submit();
}

// Sentinel key for purposes with no elements (purpose-level checked state)
const PURPOSE_KEY = '__purpose__';

interface Props {
  data: PurposeConsentData;
}

export default function PurposeConsentPage({ data }: Props) {
  const { sessionDataKeyConsent, spId, appName, user, purposes, existingConsentId, previouslyConsentedPurposeNames, previouslyConsentedElements, consentToken } = data;

  // purposeName → elementName → boolean (or PURPOSE_KEY for element-less purposes)
  const [checked, setChecked] = useState<Record<string, Record<string, boolean>>>({});
  const initialApplied = useRef(false);

  useEffect(() => {
    if (initialApplied.current || purposes.length === 0) return;
    initialApplied.current = true;

    const init: Record<string, Record<string, boolean>> = {};
    for (const p of purposes) {
      if (p.mandatory) continue;
      const prevElems = previouslyConsentedElements?.[p.purposeName];
      const wasPrevConsented = previouslyConsentedPurposeNames?.includes(p.purposeName);
      if (p.elements.length === 0) {
        init[p.purposeName] = { [PURPOSE_KEY]: wasPrevConsented ?? false };
      } else if (prevElems) {
        init[p.purposeName] = Object.fromEntries(p.elements.map((el) => [el, prevElems.includes(el)]));
      } else if (wasPrevConsented) {
        init[p.purposeName] = Object.fromEntries(p.elements.map((el) => [el, true]));
      }
    }
    setChecked(init);
  }, [purposes, previouslyConsentedPurposeNames, previouslyConsentedElements]);

  const isElementChecked = (purposeName: string, el: string) => checked[purposeName]?.[el] ?? false;

  const isPurposeFullyChecked = (p: ConsentPurpose) => {
    if (p.mandatory) return true;
    if (p.elements.length === 0) return checked[p.purposeName]?.[PURPOSE_KEY] ?? false;
    return p.elements.every((el) => isElementChecked(p.purposeName, el));
  };

  const isPurposeIndeterminate = (p: ConsentPurpose) => {
    if (p.mandatory || p.elements.length === 0) return false;
    const someChecked = p.elements.some((el) => isElementChecked(p.purposeName, el));
    const allCheckedVal = p.elements.every((el) => isElementChecked(p.purposeName, el));
    return someChecked && !allCheckedVal;
  };

  const handlePurposeToggle = (p: ConsentPurpose) => {
    if (p.mandatory) return;
    if (p.elements.length === 0) {
      const current = checked[p.purposeName]?.[PURPOSE_KEY] ?? false;
      setChecked((prev) => ({ ...prev, [p.purposeName]: { [PURPOSE_KEY]: !current } }));
      return;
    }
    const allCheckedVal = isPurposeFullyChecked(p);
    setChecked((prev) => ({
      ...prev,
      [p.purposeName]: Object.fromEntries(p.elements.map((el) => [el, !allCheckedVal])),
    }));
  };

  const handleElementToggle = (purposeName: string, el: string) => {
    setChecked((prev) => ({
      ...prev,
      [purposeName]: { ...prev[purposeName], [el]: !(prev[purposeName]?.[el] ?? false) },
    }));
  };

  const [submitting, setSubmitting] = useState<'allow' | 'deny' | null>(null);
  const [submitError, setSubmitError] = useState<string | null>(null);

  const handleAllow = async () => {
    setSubmitting('allow');
    setSubmitError(null);

    const consentedPurposes = purposes
      .filter((p) => p.mandatory || isPurposeFullyChecked(p) || isPurposeIndeterminate(p))
      .map((p) => ({
        purposeName: p.purposeName,
        consentedElements: p.elements.filter((el) => p.mandatory || isElementChecked(p.purposeName, el)),
      }));

    try {
      await submitConsent({
        consentToken,
        sessionDataKeyConsent,
        spId,
        approved: true,
        consentedPurposes,
        ...(existingConsentId ? { existingConsentId } : {}),
      });
      submitIdpForm(sessionDataKeyConsent, true, {
        claims: parseMandatoryClaims(data.mandatoryClaims),
        scopes: data.scopes,
      });
    } catch (err) {
      console.error('Failed to submit consent', err);
      setSubmitError('Failed to submit consent. Please try again.');
      setSubmitting(null);
    }
  };

  const handleDeny = () => {
    setSubmitting('deny');
    submitIdpForm(sessionDataKeyConsent, false);
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        bgcolor: 'background.default',
        p: 2,
      }}
    >
      <Box sx={{ mb: 3 }}>
        <img
          src="https://wso2.cachefly.net/wso2/sites/all/image_resources/logos/WSO2-Logo-Black.webp"
          alt="WSO2"
          style={{ height: 32 }}
        />
      </Box>

      <Paper sx={{ p: 4, maxWidth: 440, width: '100%' }}>
        <Typography variant="h5" sx={{ fontWeight: 700, mb: 3, lineHeight: 1.3, textAlign: 'center' }}>
          <Typography component="span" variant="h5" sx={{ fontWeight: 700, color: 'warning.main' }}>
            {appName}
          </Typography>
          {' '}wants to access your account.
        </Typography>

        <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
          Signed in as <strong>{user.displayName}</strong>{user.email ? ` (${user.email})` : ''}
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
          This will allow the application to:
        </Typography>

        <Box sx={{ bgcolor: 'background.default', borderRadius: 2, p: 2, mb: 3, minHeight: 64 }}>
          {purposes.map((purpose, idx) => (
            <Box key={purpose.purposeName} sx={{ mb: idx < purposes.length - 1 ? 2 : 0 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
                <Box
                  sx={{
                    width: 8,
                    height: 8,
                    borderRadius: '50%',
                    bgcolor: 'primary.main',
                    flexShrink: 0,
                  }}
                />
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={isPurposeFullyChecked(purpose)}
                      indeterminate={isPurposeIndeterminate(purpose)}
                      disabled={purpose.mandatory || submitting !== null}
                      onChange={() => handlePurposeToggle(purpose)}
                      size="small"
                      sx={{ p: '2px 8px 2px 4px' }}
                    />
                  }
                  label={
                    <>
                      <Typography
                        variant="body2"
                        sx={{ fontWeight: 600, color: purpose.mandatory ? 'text.disabled' : 'text.primary' }}
                      >
                        {purpose.purposeName}
                        {purpose.mandatory && (
                          <Typography component="span" sx={{ color: 'error.main', ml: '2px', fontWeight: 600 }}>
                            *
                          </Typography>
                        )}
                      </Typography>
                      {purpose.purposeDescription && (
                        <Typography variant="caption" color="text.secondary" sx={{ display: 'block', lineHeight: 1.4 }}>
                          {purpose.purposeDescription}
                        </Typography>
                      )}
                    </>
                  }
                  sx={{ m: 0 }}
                />
              </Box>

              <Box sx={{ pl: 4 }}>
                {purpose.elements.map((el) => (
                  <Box key={el} sx={{ display: 'flex', alignItems: 'center' }}>
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={purpose.mandatory || isElementChecked(purpose.purposeName, el)}
                          disabled={purpose.mandatory || submitting !== null}
                          onChange={() => !purpose.mandatory && handleElementToggle(purpose.purposeName, el)}
                          size="small"
                          sx={{ p: '2px 8px 2px 4px' }}
                        />
                      }
                      label={
                        <Typography variant="caption" sx={{ color: purpose.mandatory ? 'text.disabled' : 'text.secondary' }}>
                          {el}
                        </Typography>
                      }
                      sx={{ m: 0 }}
                    />
                  </Box>
                ))}
              </Box>
            </Box>
          ))}
        </Box>

        <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 3, textAlign: 'center', lineHeight: 1.5 }}>
          By clicking 'Allow', you agree to share the data related to the above selections with {appName}.
        </Typography>

        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
          <Button
            variant="contained"
            fullWidth
            onClick={() => void handleAllow()}
            disabled={submitting !== null}
            sx={{ borderRadius: '50px', textTransform: 'none', fontWeight: 600, fontSize: '0.95rem', py: 1.25 }}
          >
            {submitting === 'allow' ? <CircularProgress size={20} sx={{ color: 'inherit' }} /> : 'Allow'}
          </Button>
          <Button
            variant="outlined"
            fullWidth
            onClick={handleDeny}
            disabled={submitting !== null}
            sx={{ borderRadius: '50px', textTransform: 'none', fontWeight: 600, fontSize: '0.95rem', py: 1.25, borderColor: 'divider', color: 'text.secondary', '&:hover': { bgcolor: 'action.hover', borderColor: 'divider' } }}
          >
            {submitting === 'deny' ? <CircularProgress size={20} sx={{ color: 'inherit' }} /> : 'Deny'}
          </Button>
        </Box>
      </Paper>

      <Snackbar
        open={!!submitError}
        autoHideDuration={6000}
        onClose={() => setSubmitError(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert onClose={() => setSubmitError(null)} severity="error" sx={{ width: '100%' }}>
          {submitError}
        </Alert>
      </Snackbar>
    </Box>
  );
}
