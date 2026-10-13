using ACS.Modules.Charts.DataAccess;
using ACS.Modules.Charts.Features.ExportDataStation;
using ACS.Modules.Charts.Features.SearchCharts;

namespace ACS.Modules.Charts.Features.ExportDataStationLogNotes;

/// <summary>One report row = one log note plus the chart it belongs to.</summary>
public sealed record LogNoteReportRow(ChartListItemDto Chart, DataStationLogNoteRow Note);

public sealed record DataStationLogNoteField(
	string Key,
	string Caption,
	string Group,
	PhiKind Phi,
	Func<LogNoteReportRow, string> Read);

/// <summary>
/// Column catalog for the "Chart Log Notes" report: the stored LOG_NOTE fields (same ones the chart's
/// Log Notes page shows) plus a few identifying chart columns for context. No counts, ages, or other
/// derived values.
/// </summary>
public static class DataStationLogNoteFields
{
	private const string DateFmt = "MM/dd/yyyy";
	private const string DateTimeFmt = "MM/dd/yyyy HH:mm";

	public static readonly IReadOnlyList<DataStationLogNoteField> All =
	[
		// Note
		new("logNoteId",      "Log Note ID",         "Note",  PhiKind.None,             r => r.Note.LogNoteId.ToString()),
		new("category",       "Category",            "Note",  PhiKind.None,             r => r.Note.CategoryDescription ?? ""),
		new("summary",        "Summary",             "Note",  PhiKind.UserAuthoredText, r => r.Note.Summary ?? ""),
		new("detail",         "Detail",              "Note",  PhiKind.UserAuthoredText, r => r.Note.Detail ?? ""),
		new("systemDefined",  "System Generated",    "Note",  PhiKind.None,             r => r.Note.SystemDefined ? "Yes" : "No"),
		new("noteCreated",    "Note Created",        "Note",  PhiKind.None,             r => r.Note.CreationDateTime?.ToString(DateTimeFmt) ?? ""),
		new("noteCompleted",  "Note Completed",      "Note",  PhiKind.None,             r => r.Note.CompletionDate?.ToString(DateTimeFmt) ?? ""),
		new("completedBy",    "Completed By",        "Note",  PhiKind.None,             r => r.Note.CompletedByName ?? ""),
		new("eventTime",      "Chart Event Time",    "Note",  PhiKind.None,             r => r.Note.AccessDateTime?.ToString(DateTimeFmt) ?? ""),
		// Chart
		new("facility",              "Facility",                "Chart",   PhiKind.None,     r => r.Chart.Facility),
		new("chartId",               "Chart ID",                "Chart",   PhiKind.None,     r => r.Chart.ChartId.ToString()),
		new("facilityChartId",       "Facility Chart ID",       "Chart",   PhiKind.None,     r => r.Chart.FacilityChartId ?? ""),
		new("facilityAdminChartId",  "Facility Admin Chart ID", "Chart",   PhiKind.None,     r => r.Chart.FacilityAdminChartId ?? ""),
		new("dateOfService",         "Date of Service",         "Chart",   PhiKind.None,     r => r.Chart.DateOfService.ToString(DateFmt)),
		new("chartStatus",           "Chart Status",            "Chart",   PhiKind.None,     r => r.Chart.Status),
		new("physician",             "Physician",               "Chart",   PhiKind.None,     r => r.Chart.PhysicianName ?? ""),
		// Patient
		new("patientName",           "Patient Name",            "Patient", PhiKind.Name,     r => r.Chart.PatientName ?? ""),
		new("medicalRecordNumber",   "Medical Record #",        "Patient", PhiKind.LastFour, r => r.Chart.MedicalRecordNumber ?? ""),
	];

	private static readonly Dictionary<string, DataStationLogNoteField> ByKey =
		All.ToDictionary(f => f.Key, StringComparer.Ordinal);

	public static bool TryGet(string key, out DataStationLogNoteField field) => ByKey.TryGetValue(key, out field!);

	public static string Mask(DataStationLogNoteField field, string value, LogNoteReportRow row)
	{
		if (field.Phi == PhiKind.None || value.Length == 0) return value;
		return field.Phi switch
		{
			PhiKind.Name             => Initials(row.Chart.PatientFirstName, row.Chart.PatientLastName),
			PhiKind.LastFour         => value.Length <= 4 ? value : "***" + value[^4..],
			PhiKind.UserAuthoredText => row.Note.SystemDefined ? value : DataStationFields.Withheld,
			_                        => value,
		};
	}

	private static string Initials(string? first, string? last)
		=> string.Concat(
			first is { Length: > 0 } ? $"{char.ToUpperInvariant(first[0])}." : "",
			last  is { Length: > 0 } ? $"{char.ToUpperInvariant(last[0])}."  : "");
}
