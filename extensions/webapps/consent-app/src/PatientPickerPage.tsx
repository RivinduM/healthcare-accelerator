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

import { useState } from 'react';
import {
  AppBar,
  Avatar,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  Divider,
  FormControl,
  MenuItem,
  Select,
  Toolbar,
  Typography,
} from '@wso2/oxygen-ui';
import type { ConsentPatient, ConsentUser } from './types';

function getInitials(name: string): string {
  return name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);
}

interface Props {
  patients: ConsentPatient[];
  user: ConsentUser;
  onProceed: (patient: ConsentPatient) => void;
  onCancel: () => void;
}

export default function PatientPickerPage({ patients, user, onProceed, onCancel }: Props) {
  const [selectedId, setSelectedId] = useState('');
  const selectedPatient = patients.find((p) => p.id === selectedId) ?? null;

  const isEmpty = patients.length === 0;

  return (
    <Box sx={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', bgcolor: 'background.default' }}>
      <AppBar position="static" elevation={0} sx={{ bgcolor: 'background.paper', borderBottom: '1px solid', borderColor: 'divider', color: 'inherit' }}>
        <Toolbar sx={{ gap: 1.5, px: { xs: 2, sm: 4 } }}>
          <img
            src="https://wso2.cachefly.net/wso2/sites/all/image_resources/logos/WSO2-Logo-Black.webp"
            alt="WSO2"
            style={{ height: 28, display: 'block' }}
          />
          <Typography sx={{ fontSize: '15px', fontWeight: 400, letterSpacing: '0.04em', color: 'text.primary' }}>
            OPEN HEALTHCARE
          </Typography>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, ml: 'auto' }}>
            <Avatar sx={{ width: 32, height: 32, fontSize: '13px', bgcolor: 'primary.main', fontWeight: 700 }}>
              {getInitials(user.displayName)}
            </Avatar>
            <Box sx={{ display: { xs: 'none', sm: 'block' } }}>
              <Typography variant="body2" sx={{ fontWeight: 600, lineHeight: 1.2 }}>{user.displayName}</Typography>
              {user.email && <Typography variant="caption" sx={{ color: 'text.secondary' }}>{user.email}</Typography>}
            </Box>
          </Box>
        </Toolbar>
      </AppBar>

      <Box component="main" sx={{ flex: 1, display: 'flex', justifyContent: 'center', alignItems: 'flex-start', p: { xs: 2, sm: '40px 16px 60px' } }}>
        <Card elevation={2} sx={{ width: '100%', maxWidth: 560, borderRadius: '12px', border: '1px solid', borderColor: 'divider' }}>
          <CardContent sx={{ p: { xs: 3, sm: '36px 40px 32px' } }}>
            <Typography variant="h5" sx={{ fontWeight: 700, letterSpacing: '-0.02em', mb: 0.5 }}>
              Select Patient
            </Typography>
            <Typography variant="body2" sx={{ color: 'text.secondary', mb: 3 }}>
              Choose the patient record you want to associate with this session.
            </Typography>

            {isEmpty ? (
              <Box sx={{ p: 2, mb: 3, bgcolor: '#fff5f5', border: '1px solid #ffcdd2', borderRadius: 2 }}>
                <Typography variant="body2" sx={{ color: 'error.main', fontWeight: 600, mb: 0.5 }}>No patients available</Typography>
                <Typography variant="body2" sx={{ color: 'error.main' }}>No patient records found for your account.</Typography>
              </Box>
            ) : (
              <>
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, mb: 3 }}>
                  <Chip
                    label={`Practitioner: ${user.displayName}`}
                    size="small"
                    sx={{ bgcolor: 'rgba(255, 81, 0, 0.08)', color: 'primary.main', fontWeight: 600, fontSize: '11px' }}
                  />
                  <Chip
                    label={`${patients.length} patient${patients.length !== 1 ? 's' : ''} available`}
                    size="small"
                    sx={{ bgcolor: '#f0faf0', color: '#2e7d32', fontWeight: 600, fontSize: '11px' }}
                  />
                </Box>

                <Typography variant="caption" sx={{ fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'text.secondary', display: 'block', mb: 1 }}>
                  Patient
                </Typography>
                <FormControl fullWidth size="small" sx={{ mb: 3 }}>
                  <Select
                    value={selectedId}
                    displayEmpty
                    renderValue={(value: string) =>
                      value
                        ? (patients.find((p) => p.id === value)?.name ?? value)
                        : <span style={{ color: 'rgba(0,0,0,0.42)' }}>Choose a patient…</span>
                    }
                    onChange={(e: { target: { value: unknown } }) => setSelectedId(e.target.value as string)}
                    sx={{ borderRadius: '8px' }}
                  >
                    {patients.map((p) => (
                      <MenuItem key={p.id} value={p.id}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                          <Avatar sx={{ width: 28, height: 28, fontSize: '11px', bgcolor: 'primary.main', fontWeight: 700 }}>
                            {getInitials(p.name)}
                          </Avatar>
                          <Box>
                            <Typography variant="body2" sx={{ fontWeight: 600, lineHeight: 1.2 }}>{p.name}</Typography>
                            {p.mrn && <Typography variant="caption" sx={{ color: 'text.secondary' }}>{p.mrn}</Typography>}
                          </Box>
                        </Box>
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>

                {selectedPatient && (
                  <Box sx={{ border: '1px solid', borderColor: 'divider', borderRadius: '8px', bgcolor: 'background.default', p: 2, mb: 3 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                      <Avatar sx={{ width: 48, height: 48, fontSize: '18px', bgcolor: 'primary.main', fontWeight: 700 }}>
                        {getInitials(selectedPatient.name)}
                      </Avatar>
                      <Box>
                        <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>{selectedPatient.name}</Typography>
                        {selectedPatient.mrn && <Typography variant="caption" sx={{ color: 'text.secondary' }}>{selectedPatient.mrn}</Typography>}
                      </Box>
                    </Box>
                    <Divider sx={{ mb: 1.5 }} />
                    {selectedPatient.fhirUser && (
                      <Box sx={{ display: 'flex', gap: 1.5 }}>
                        <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em', minWidth: 80 }}>
                          FHIR User
                        </Typography>
                        <Typography variant="body2">{selectedPatient.fhirUser}</Typography>
                      </Box>
                    )}
                  </Box>
                )}

                <Divider sx={{ mb: 3 }} />
              </>
            )}

            <Box sx={{ display: 'flex', gap: 1.5 }}>
              {!isEmpty && (
                <Button
                  variant="contained"
                  color="primary"
                  fullWidth
                  disabled={!selectedPatient}
                  onClick={() => selectedPatient && onProceed(selectedPatient)}
                  sx={{ fontWeight: 400, fontSize: '15px', py: 1.5, textTransform: 'none' }}
                >
                  {selectedPatient ? <CircularProgress size={20} sx={{ display: 'none' }} /> : null}
                  Proceed
                </Button>
              )}
              <Button
                variant="outlined"
                onClick={onCancel}
                sx={{ color: 'error.main', borderColor: 'error.main', fontWeight: 600, fontSize: '15px', py: 1.5, px: 3, textTransform: 'none', '&:hover': { bgcolor: '#fff5f5', borderColor: 'error.main' } }}
              >
                Cancel
              </Button>
            </Box>
          </CardContent>
        </Card>
      </Box>

      <Box component="footer" sx={{ textAlign: 'center', py: 2, px: 2, borderTop: '1px solid', borderColor: 'divider', bgcolor: 'background.paper' }}>
        <Typography variant="caption" sx={{ color: 'text.secondary' }}>
          WSO2 Healthcare | © {new Date().getFullYear()}
        </Typography>
      </Box>
    </Box>
  );
}
