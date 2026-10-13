using ACS.Modules.Charts.Features.ExportCharts;
using ACS.Shared.Contracts;
using MediatR;

namespace ACS.Modules.Charts.Features.ExportDataStationLogNotes;

/// <summary>
/// Data Station "Chart Log Notes" report: one row per log note, for the charts selected by
/// <see cref="Filters"/>, optionally narrowed by note date, category and system/user authorship.
/// Stored values only — no counts, durations, or other calculations.
///
/// Rights (AND-ed by AuthorizationBehavior):
///   AllowAccessToDataStation (172) — may use the Data Station
///   CanSeeDashboard (32)           — same right the underlying chart export requires
///   Charts (3)                     — same right GetChartLogNotesQuery requires to read a chart's notes
/// <see cref="MaskPhi"/> = false additionally requires AllowDataStationUnmaskedPhi (173) — checked in the handler.
/// </summary>
[HasRight(UserRight.AllowAccessToDataStation)]
[HasRight(UserRight.CanSeeDashboard)]
[HasRight(UserRight.Charts)]
public record ExportDataStationLogNotesQuery(
	/// <summary>Selects the charts (same contract as the chart search export; facility-authorized).</summary>
	ExportChartsQuery Filters,
	/// <summary>Column keys from <see cref="DataStationLogNoteFields"/>, in output order.</summary>
	IReadOnlyList<string> Columns,
	/// <summary>"csv" or "excel".</summary>
	string Format,
	bool MaskPhi = true,
	/// <summary>Only notes created on/after this date.</summary>
	DateOnly? NoteFrom = null,
	/// <summary>Only notes created on/before this date (inclusive).</summary>
	DateOnly? NoteTo = null,
	/// <summary>Comma-separated LOG_NOTE_CATEGORY_IDs; blank = every category.</summary>
	string? CategoryIds = null,
	/// <summary>false = only notes a person wrote.</summary>
	bool IncludeSystemNotes = true
) : IRequest<ExportChartsResult>;
