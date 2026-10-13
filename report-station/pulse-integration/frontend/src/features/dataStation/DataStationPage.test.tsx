// @vitest-environment jsdom
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import DataStationPage from './DataStationPage';

// ASSUMPTION: Pulse's vitest setup provides jsdom + @testing-library (ChartLogNotesPage.test.tsx suggests so).
vi.mock('../../auth/useAuth', () => ({ useAuth: () => ({ getAccessToken: async () => 'tok' }) }));
vi.mock('../../hooks/useHasRight', () => ({ useHasRight: () => true }));
vi.mock('../../lib/userRights', () => ({ UserRight: { AllowAccessToDataStation: 172, AllowDataStationUnmaskedPhi: 173 } }));

const CATALOGS = {
  chart: { report: 'chart', maxRows: 3001, maxColumns: 40, dateBases: [], fields: [{ key: 'facility', caption: 'Facility', group: 'Chart', phi: false }] },
  logNotes: { report: 'logNotes', maxRows: 20000, maxColumns: 40, dateBases: [], fields: [{ key: 'summary', caption: 'Summary', group: 'Note', phi: true }] },
};

const urls: string[] = [];
beforeEach(() => {
  urls.length = 0;
  vi.stubGlobal('fetch', vi.fn(async (url: string) => {
    urls.push(url);
    const report = new URL(url, 'http://x').searchParams.get('report') as 'chart' | 'logNotes';
    return new Response(JSON.stringify(CATALOGS[report]), { status: 200, headers: { 'content-type': 'application/json' } });
  }));
});
afterEach(() => { cleanup(); vi.unstubAllGlobals(); });

describe('DataStationPage report types', () => {
  it('starts on chart data without note filters', async () => {
    render(<DataStationPage />);
    await screen.findByText('Facility');
    expect(screen.queryByTestId('data-station-note-filters')).toBeNull();
    expect(urls[0]).toContain('/api/data-station/fields?report=chart');
  });

  it('switching to chart log notes loads its columns, shows note filters, and clears chosen columns', async () => {
    render(<DataStationPage />);
    fireEvent.click(await screen.findByLabelText('Facility'));          // choose a chart column first
    fireEvent.click(screen.getByRole('button', { name: 'Chart log notes' }));
    await screen.findByText('Summary');
    expect(screen.getByTestId('data-station-note-filters')).toBeTruthy();
    expect(urls.at(-1)).toContain('/api/data-station/fields?report=logNotes');
    expect(screen.getByText('Nothing selected yet.')).toBeTruthy();       // selection was reset
    await waitFor(() => expect(screen.queryByText('Facility')).toBeNull());
  });
});
