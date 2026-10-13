/**
 * Pure helpers for the Data Station page: turn the form state into the exact
 * body POST /api/data-station/export expects (camelCase of ExportDataStationRequest /
 * ExportChartsQuery). Kept free of React so it can be unit-tested.
 */

export type ReportType = 'chart' | 'logNotes';

export const REPORT_LABELS: Record<ReportType, string> = {
  chart: 'Chart data',
  logNotes: 'Chart log notes',
};

export const REPORT_DESCRIPTIONS: Record<ReportType, string> = {
  chart: 'One row per chart.',
  logNotes: 'One row per log note, with the chart it belongs to.',
};

/** POST route for each report. */
export const exportPath = (r: ReportType) =>
  r === 'logNotes' ? '/api/data-station/log-notes/export' : '/api/data-station/export';

export type DateBasis = 'dos' | 'received' | 'sent' | 'discharge' | 'approved' | 'completed';

export const DATE_BASIS_LABELS: Record<DateBasis, string> = {
  dos: 'Date of Service',
  received: 'Received Date',
  sent: 'Sent Date',
  discharge: 'Discharge Date',
  approved: 'Approved Date',
  completed: 'Completed Date',
};

export interface DataStationFormState {
  reportType: ReportType;
  /** Comma-separated facility IDs (ExportChartsQuery.Facilities — required). */
  facilities: string;
  /** Comma-separated CHART_STATUS_IDs (ExportChartsQuery.Statuses). */
  statuses: string;
  dateBasis: DateBasis;
  /** yyyy-MM-dd or '' */
  dateFrom: string;
  dateTo: string;
  /** Column keys, in output order. */
  columns: string[];
  format: 'csv' | 'excel';
  maskPhi: boolean;
  /** Log-notes report only: notes created on/after this date (yyyy-MM-dd or ''). */
  noteFrom: string;
  noteTo: string;
  /** Log-notes report only: comma-separated LOG_NOTE_CATEGORY_IDs; blank = all. */
  categoryIds: string;
  /** Log-notes report only: false = only notes a person wrote. */
  includeSystemNotes: boolean;
}

export interface ExportDataStationRequest {
  filters: Record<string, string>;
  columns: string[];
  format: 'csv' | 'excel';
  maskPhi: boolean;
  noteFrom?: string;
  noteTo?: string;
  categoryIds?: string;
  includeSystemNotes?: boolean;
}

const cleanList = (s: string) =>
  s
    .split(',')
    .map((p) => p.trim())
    .filter(Boolean)
    .join(',');


export function buildExportRequest(s: DataStationFormState): ExportDataStationRequest {
  const filters: Record<string, string> = {
    facilities: cleanList(s.facilities),
    statuses: cleanList(s.statuses),
  };
  // dos -> dosFrom/dosTo, sent -> sentFrom/sentTo, ... (matches ExportChartsQuery)
  if (s.dateFrom) filters[`${s.dateBasis}From`] = s.dateFrom;
  if (s.dateTo) filters[`${s.dateBasis}To`] = s.dateTo;
  const body: ExportDataStationRequest = { filters, columns: s.columns, format: s.format, maskPhi: s.maskPhi };
  if (s.reportType === 'logNotes') {
    if (s.noteFrom) body.noteFrom = s.noteFrom;
    if (s.noteTo) body.noteTo = s.noteTo;
    const cats = cleanList(s.categoryIds);
    if (cats) body.categoryIds = cats;
    body.includeSystemNotes = s.includeSystemNotes;
  }
  return body;
}

/** Human-readable problems to show before calling the server. The server re-validates everything. */
export function validateForm(s: DataStationFormState): string[] {
  const errs: string[] = [];
  if (!cleanList(s.facilities)) errs.push('Choose at least one facility.');
  if (!/^[\d,\s]*$/.test(s.facilities)) errs.push('Facilities must be numeric IDs separated by commas.');
  if (!/^[\d,\s]*$/.test(s.statuses)) errs.push('Statuses must be numeric IDs separated by commas.');
  if (s.dateFrom && s.dateTo && s.dateTo < s.dateFrom)
    errs.push(`${DATE_BASIS_LABELS[s.dateBasis]} end must be on or after its start.`);
  if (s.reportType === 'logNotes') {
    if (!/^[\d,\s]*$/.test(s.categoryIds)) errs.push('Categories must be numeric IDs separated by commas.');
    if (s.noteFrom && s.noteTo && s.noteTo < s.noteFrom) errs.push('Note date end must be on or after its start.');
  }
  if (s.columns.length === 0) errs.push('Select at least one column.');
  return errs;
}

