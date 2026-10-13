import {
  Alert,
  Box,
  Button,
  Checkbox,
  Chip,
  CircularProgress,
  FormControl,
  FormControlLabel,
  InputLabel,
  MenuItem,
  Paper,
  Select,
  Stack,
  TextField,
  Typography,
} from '@mui/material';
import { useEffect, useMemo, useState } from 'react';
import { useAuth } from '../../auth/useAuth';
import { useHasRight } from '../../hooks/useHasRight';
import { UserRight } from '../../lib/userRights';
import {
  DATE_BASIS_LABELS,
  validateForm,
  type DataStationFormState,
  type DateBasis,
} from './buildExportRequest';
import { DataStationError, fetchFields, runExport, saveBlob, type DataStationFieldsDto } from './dataStationApi';

const INITIAL: DataStationFormState = {
  facilities: '',
  statuses: '',
  dateBasis: 'dos',
  dateFrom: '',
  dateTo: '',
  columns: [],
  format: 'csv',
  maskPhi: true,
};

/**
 * Data Station — self-service raw-data export.
 * Every column is a stored value returned as-is: no formulas, totals, rates or scores.
 */
export default function DataStationPage() {
  const { getAccessToken } = useAuth();
  const canUse = useHasRight(UserRight.AllowAccessToDataStation);
  const canUnmask = useHasRight(UserRight.AllowDataStationUnmaskedPhi);

  const [catalog, setCatalog] = useState<DataStationFieldsDto | null>(null);
  const [form, setForm] = useState<DataStationFormState>(INITIAL);
  const [busy, setBusy] = useState(false);
  const [errors, setErrors] = useState<string[]>([]);
  const [done, setDone] = useState<string | null>(null);

  useEffect(() => {
    if (!canUse) return;
    let cancelled = false;
    fetchFields(getAccessToken)
      .then((c) => !cancelled && setCatalog(c))
      .catch((e: DataStationError) => !cancelled && setErrors([e.message, ...e.details]));
    return () => {
      cancelled = true;
    };
  }, [canUse, getAccessToken]);

  const groups = useMemo(() => {
    const m = new Map<string, DataStationFieldsDto['fields']>();
    catalog?.fields.forEach((f) => m.set(f.group, [...(m.get(f.group) ?? []), f]));
    return [...m.entries()];
  }, [catalog]);
  const byKey = useMemo(() => new Map(catalog?.fields.map((f) => [f.key, f])), [catalog]);

  if (!canUse) {
    return (
      <Alert severity="warning" data-testid="data-station-no-access">
        You don't have access to the Data Station. Ask an administrator to grant the "Allow Access To Data Station" right.
      </Alert>
    );
  }

  const set = <K extends keyof DataStationFormState>(k: K, v: DataStationFormState[K]) => {
    setDone(null);
    setForm((f) => ({ ...f, [k]: v }));
  };
  const toggleColumn = (key: string) =>
    set('columns', form.columns.includes(key) ? form.columns.filter((c) => c !== key) : [...form.columns, key]);
  const move = (i: number, d: -1 | 1) => {
    const next = [...form.columns];
    [next[i], next[i + d]] = [next[i + d], next[i]];
    set('columns', next);
  };

  async function onRun() {
    const problems = validateForm(form);
    setErrors(problems);
    if (problems.length) return;
    setBusy(true);
    try {
      const { blob, fileName } = await runExport(getAccessToken, form);
      saveBlob(blob, fileName);
      setDone(`Downloaded ${fileName}`);
    } catch (e) {
      const err = e as DataStationError;
      setErrors([err.message, ...(err.details ?? [])]);
    } finally {
      setBusy(false);
    }
  }

  return (
    <Box sx={{ maxWidth: 1100, mx: 'auto' }} data-testid="data-station-page">
      <Typography variant="h5" sx={{ fontWeight: 700 }}>Data Station</Typography>
      <Typography color="text.secondary" sx={{ mb: 2 }}>
        Pick your filters and columns. You get the rows exactly as Pulse stores them — no formulas, totals or calculations.
        {catalog && ` Up to ${catalog.maxRows.toLocaleString()} rows per export.`}
      </Typography>

      <Paper sx={{ p: 2, mb: 2 }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 1 }}>1. Which charts?</Typography>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
          {/* TODO: replace with facility / status pickers once GET /api/data-station/options exists. */}
          <TextField label="Facility IDs" helperText="Comma-separated, e.g. 12, 15" value={form.facilities}
            onChange={(e) => set('facilities', e.target.value)} required fullWidth />
          <TextField label="Status IDs" helperText="Comma-separated; blank = see date-range rules" value={form.statuses}
            onChange={(e) => set('statuses', e.target.value)} fullWidth />
        </Stack>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} sx={{ mt: 2 }}>
          <FormControl fullWidth>
            <InputLabel id="ds-basis">Filter dates by</InputLabel>
            <Select labelId="ds-basis" label="Filter dates by" value={form.dateBasis}
              onChange={(e) => set('dateBasis', e.target.value as DateBasis)}>
              {(Object.keys(DATE_BASIS_LABELS) as DateBasis[]).map((b) => (
                <MenuItem key={b} value={b}>{DATE_BASIS_LABELS[b]}</MenuItem>
              ))}
            </Select>
          </FormControl>
          <TextField type="date" label="From" slotProps={{ inputLabel: { shrink: true } }} value={form.dateFrom}
            onChange={(e) => set('dateFrom', e.target.value)} fullWidth />
          <TextField type="date" label="To" slotProps={{ inputLabel: { shrink: true } }} value={form.dateTo}
            onChange={(e) => set('dateTo', e.target.value)} fullWidth />
        </Stack>
      </Paper>

      <Paper sx={{ p: 2, mb: 2 }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 1 }}>2. Which columns?</Typography>
        {!catalog ? <CircularProgress size={22} /> : (
          <Stack direction={{ xs: 'column', md: 'row' }} spacing={3} sx={{ alignItems: 'flex-start' }}>
            <Box sx={{ flex: 1 }}>
              {groups.map(([group, fields]) => (
                <Box key={group} sx={{ mb: 1.5 }}>
                  <Typography variant="overline" color="text.secondary">{group}</Typography>
                  <Box sx={{ display: 'flex', flexDirection: 'column' }}>
                    {fields.map((f) => (
                      <FormControlLabel key={f.key} label={<>{f.caption}{f.phi && <Chip size="small" label="PHI" sx={{ ml: 1 }} />}</>}
                        control={<Checkbox size="small" checked={form.columns.includes(f.key)} onChange={() => toggleColumn(f.key)} />} />
                    ))}
                  </Box>
                </Box>
              ))}
            </Box>
            <Box sx={{ flex: 1, minWidth: 260 }}>
              <Typography variant="subtitle2" sx={{ mb: 1 }}>Your columns, in order ({form.columns.length})</Typography>
              {form.columns.length === 0 && <Typography color="text.secondary">Nothing selected yet.</Typography>}
              {form.columns.map((key, i) => (
                <Stack key={key} direction="row" spacing={1} sx={{ py: 0.25, alignItems: 'center' }}>
                  <Typography sx={{ flex: 1 }}>{i + 1}. {byKey.get(key)?.caption ?? key}</Typography>
                  <Button size="small" disabled={i === 0} onClick={() => move(i, -1)} aria-label={`Move ${key} up`}>↑</Button>
                  <Button size="small" disabled={i === form.columns.length - 1} onClick={() => move(i, 1)} aria-label={`Move ${key} down`}>↓</Button>
                  <Button size="small" onClick={() => toggleColumn(key)} aria-label={`Remove ${key}`}>✕</Button>
                </Stack>
              ))}
            </Box>
          </Stack>
        )}
      </Paper>

      <Paper sx={{ p: 2, mb: 2 }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 1 }}>3. Output</Typography>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} sx={{ alignItems: { md: 'center' } }}>
          <FormControl sx={{ minWidth: 200 }}>
            <InputLabel id="ds-format">Format</InputLabel>
            <Select labelId="ds-format" label="Format" value={form.format}
              onChange={(e) => set('format', e.target.value as 'csv' | 'excel')}>
              <MenuItem value="csv">CSV</MenuItem>
              <MenuItem value="excel">Excel (.xlsx)</MenuItem>
            </Select>
          </FormControl>
          <FormControlLabel
            control={<Checkbox checked={form.maskPhi} disabled={!canUnmask} onChange={(e) => set('maskPhi', e.target.checked)} />}
            label={canUnmask ? 'Mask patient information (recommended)' : 'Patient information is masked (you don’t have the right to unmask it)'} />
        </Stack>
        {!form.maskPhi && <Alert severity="warning" sx={{ mt: 1 }}>Masking is off — the file will contain full patient identifiers. Make sure its destination is secure.</Alert>}
      </Paper>

      {errors.length > 0 && (
        <Alert severity="error" sx={{ mb: 2 }} data-testid="data-station-errors">
          <ul style={{ margin: 0, paddingLeft: 18 }}>{errors.map((e, i) => <li key={i}>{e}</li>)}</ul>
        </Alert>
      )}
      {done && <Alert severity="success" sx={{ mb: 2 }}>{done}</Alert>}

      <Button variant="contained" size="large" onClick={onRun} disabled={busy || !catalog} data-testid="data-station-run">
        {busy ? 'Running…' : 'Run export'}
      </Button>
    </Box>
  );
}
