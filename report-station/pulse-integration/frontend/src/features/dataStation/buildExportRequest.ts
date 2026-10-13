/**
 * Pure helpers for the Data Station page: turn the form state into the exact
 * body POST /api/data-station/export expects (camelCase of ExportDataStationRequest /
 * ExportChartsQuery). Kept free of React so it can be unit-tested.
 */

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
}

export interface ExportDataStationRequest {
  filters: Record<string, string>;
  columns: string[];
  format: 'csv' | 'excel';
  maskPhi: boolean;
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
  return { filters, columns: s.columns, format: s.format, maskPhi: s.maskPhi };
}

/** Human-readable problems to show before calling the server. The server re-validates everything. */
export function validateForm(s: DataStationFormState): string[] {
  const errs: string[] = [];
  if (!cleanList(s.facilities)) errs.push('Choose at least one facility.');
  if (!/^[\d,\s]*$/.test(s.facilities)) errs.push('Facilities must be numeric IDs separated by commas.');
  if (!/^[\d,\s]*$/.test(s.statuses)) errs.push('Statuses must be numeric IDs separated by commas.');
  if (s.dateFrom && s.dateTo && s.dateTo < s.dateFrom)
    errs.push(`${DATE_BASIS_LABELS[s.dateBasis]} end must be on or after its start.`);
  if (s.columns.length === 0) errs.push('Select at least one column.');
  return errs;
}

