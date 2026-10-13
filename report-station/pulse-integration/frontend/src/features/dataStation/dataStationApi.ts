import { buildExportRequest, exportPath, type DataStationFormState, type ReportType } from './buildExportRequest';

export interface DataStationField {
  key: string;
  caption: string;
  group: string;
  phi: boolean;
}

export interface DataStationFieldsDto {
  report: ReportType;
  fields: DataStationField[];
  maxRows: number;
  maxColumns: number;
  dateBases: string[];
}

export class DataStationError extends Error {
  constructor(message: string, readonly status: number, readonly details: string[] = []) {
    super(message);
  }
}

type GetToken = () => Promise<string>;

async function authedFetch(getToken: GetToken, url: string, init: RequestInit = {}) {
  const token = await getToken();
  return fetch(url, {
    ...init,
    credentials: 'include',
    headers: { ...(init.headers ?? {}), Authorization: `Bearer ${token}` },
  });
}

/** ProblemDetails / ValidationProblemDetails → readable lines. */
async function toError(res: Response): Promise<DataStationError> {
  if (res.status === 403) return new DataStationError('You do not have access to this export.', 403);
  try {
    const body = await res.json();
    const details: string[] = body?.errors ? Object.values<string[]>(body.errors).flat() : [];
    return new DataStationError(body?.title ?? body?.detail ?? `Export failed (${res.status})`, res.status, details);
  } catch {
    return new DataStationError(`Export failed (${res.status})`, res.status);
  }
}

export async function fetchFields(getToken: GetToken, report: ReportType = 'chart'): Promise<DataStationFieldsDto> {
  const res = await authedFetch(getToken, `/api/data-station/fields?report=${encodeURIComponent(report)}`);
  if (!res.ok) throw await toError(res);
  return res.json();
}

export async function runExport(
  getToken: GetToken,
  form: DataStationFormState,
): Promise<{ blob: Blob; fileName: string }> {
  const res = await authedFetch(getToken, exportPath(form.reportType), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(buildExportRequest(form)),
  });
  if (!res.ok) throw await toError(res);
  const disposition = res.headers.get('content-disposition') ?? '';
  const match = /filename\*?=(?:UTF-8'')?"?([^";]+)"?/i.exec(disposition);
  return { blob: await res.blob(), fileName: match?.[1] ?? `${form.reportType === 'logNotes' ? 'data-station-log-notes' : 'data-station-export'}.${form.format === 'excel' ? 'xlsx' : 'csv'}` };
}

export function saveBlob(blob: Blob, fileName: string) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = fileName;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}
