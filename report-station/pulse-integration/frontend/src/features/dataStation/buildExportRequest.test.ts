import { describe, expect, it } from 'vitest';
import { buildExportRequest, validateForm, type DataStationFormState } from './buildExportRequest';

const base: DataStationFormState = {
  facilities: ' 5, 7 ,',
  statuses: '5',
  dateBasis: 'sent',
  dateFrom: '2026-06-01',
  dateTo: '2026-06-30',
  columns: ['patientName', 'status'],
  format: 'csv',
  maskPhi: true,
};

describe('buildExportRequest', () => {
  it('maps the chosen date basis onto the matching From/To filters', () => {
    const r = buildExportRequest(base);
    expect(r.filters).toEqual({ facilities: '5,7', statuses: '5', sentFrom: '2026-06-01', sentTo: '2026-06-30' });
    expect(r.columns).toEqual(['patientName', 'status']);
    expect(r.maskPhi).toBe(true);
  });

  it('omits empty dates and keeps masking on by default shape', () => {
    const r = buildExportRequest({ ...base, dateBasis: 'dos', dateFrom: '', dateTo: '' });
    expect(Object.keys(r.filters).sort()).toEqual(['facilities', 'statuses']);
  });
});

describe('validateForm', () => {
  it('accepts a good form', () => expect(validateForm(base)).toEqual([]));
  it('flags missing facility, bad ids, reversed dates, no columns', () => {
    const errs = validateForm({ ...base, facilities: '', statuses: 'a', dateFrom: '2026-07-01', columns: [] });
    expect(errs).toHaveLength(4);
  });
});
