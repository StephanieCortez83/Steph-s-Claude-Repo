import { describe, expect, it } from 'vitest';
import { buildExportRequest, exportPath, validateForm, type DataStationFormState } from './buildExportRequest';

const base: DataStationFormState = {
  reportType: 'chart',
  noteFrom: '',
  noteTo: '',
  categoryIds: '',
  includeSystemNotes: true,
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

describe('log notes report', () => {
  const notes: DataStationFormState = {
    ...base,
    reportType: 'logNotes',
    columns: ['summary', 'facility'],
    noteFrom: '2026-06-01',
    noteTo: '2026-06-30',
    categoryIds: ' 2, 3,',
    includeSystemNotes: false,
  };

  it('adds the note filters only for the log notes report', () => {
    const r = buildExportRequest(notes);
    expect(r).toMatchObject({ noteFrom: '2026-06-01', noteTo: '2026-06-30', categoryIds: '2,3', includeSystemNotes: false });
    const chart = buildExportRequest({ ...notes, reportType: 'chart' });
    expect(chart).not.toHaveProperty('noteFrom');
    expect(chart).not.toHaveProperty('includeSystemNotes');
  });

  it('posts to its own route', () => {
    expect(exportPath('chart')).toBe('/api/data-station/export');
    expect(exportPath('logNotes')).toBe('/api/data-station/log-notes/export');
  });

  it('validates note dates and categories', () => {
    expect(validateForm(notes)).toEqual([]);
    expect(validateForm({ ...notes, noteFrom: '2026-07-01', categoryIds: 'x' })).toHaveLength(2);
    // note filters are ignored for the chart report
    expect(validateForm({ ...notes, reportType: 'chart', categoryIds: 'x' })).toEqual([]);
  });
});

describe('validateForm', () => {
  it('accepts a good form', () => expect(validateForm(base)).toEqual([]));
  it('flags missing facility, bad ids, reversed dates, no columns', () => {
    const errs = validateForm({ ...base, facilities: '', statuses: 'a', dateFrom: '2026-07-01', columns: [] });
    expect(errs).toHaveLength(4);
  });
});
