using ACS.Modules.Charts.Features.SearchCharts;

namespace ACS.Modules.Charts.Features.ExportDataStation;

/// <summary>
/// How a field behaves when PHI masking is on.
/// </summary>
public enum PhiKind
{
	/// <summary>Not patient-identifying — never masked.</summary>
	None,
	/// <summary>Patient name → initials (matches ExportChartsView convention).</summary>
	Name,
	/// <summary>MRN / long patient ID → last 4 characters only.</summary>
	LastFour,
	/// <summary>Date of birth → year only.</summary>
	YearOnly,
	/// <summary>Free text that may contain PHI — withheld entirely while masking is on.</summary>
	FreeText,
	/// <summary>
	/// Text a person typed (log-note summary/detail). Withheld while masking is on, except for
	/// system-generated notes, whose text is produced by Pulse itself.
	/// </summary>
	UserAuthoredText,
}

/// <summary>
/// One exportable raw column. <see cref="Read"/> returns the stored value as text — there are
/// deliberately no aggregate, rate, count, or score fields in this catalog.
/// </summary>
public sealed record DataStationField(
	string Key,
	string Caption,
	string Group,
	PhiKind Phi,
	Func<ChartListItemDto, string> Read);

/// <summary>
/// The Data Station column catalog = the columns ExportChartsQueryHandler returns today
/// (minus the four internal *_ID columns), so the two exports never disagree about a column.
/// </summary>
public static class DataStationFields
{
	private const string DateFmt = "MM/dd/yyyy";

	public const string Withheld = "[withheld]";

	public static readonly IReadOnlyList<DataStationField> All =
	[
		// Chart
		new("facility",              "Facility",                 "Chart",     PhiKind.None,     c => c.Facility),
		new("chartId",               "Chart ID",                 "Chart",     PhiKind.None,     c => c.ChartId.ToString()),
		new("facilityChartId",       "Facility Chart ID",        "Chart",     PhiKind.None,     c => c.FacilityChartId ?? ""),
		new("facilityAdminChartId",  "Facility Admin Chart ID",  "Chart",     PhiKind.None,     c => c.FacilityAdminChartId ?? ""),
		new("status",                "Status",                   "Chart",     PhiKind.None,     c => c.Status),
		new("pendingReason",         "Pending Reason",           "Chart",     PhiKind.None,     c => c.PendingReason ?? ""),
		new("serviceModel",          "Service Model",            "Chart",     PhiKind.None,     c => c.ServiceModelCode ?? ""),
		new("emr",                   "EMR",                      "Chart",     PhiKind.None,     c => c.Emr ?? ""),
		// Patient
		new("patientName",           "Patient Name",             "Patient",   PhiKind.Name,     c => c.PatientName ?? ""),
		new("medicalRecordNumber",   "Medical Record #",         "Patient",   PhiKind.LastFour, c => c.MedicalRecordNumber ?? ""),
		new("longPatientId",         "Long Patient ID",          "Patient",   PhiKind.LastFour, c => c.LongPatientId ?? ""),
		new("dateOfBirth",           "Date of Birth",            "Patient",   PhiKind.YearOnly, c => c.PatientDateOfBirth?.ToString(DateFmt) ?? ""),
		new("patientClass",          "Patient Class",            "Patient",   PhiKind.None,     c => c.PatientClass ?? ""),
		new("patientDisposition",    "Patient Disposition",      "Patient",   PhiKind.None,     c => c.PatientDisposition ?? ""),
		new("census",                "Census",                   "Patient",   PhiKind.None,     c => c.Census ?? ""),
		// Dates
		new("receivedDate",          "Received Date",            "Dates",     PhiKind.None,     c => c.ReceivedDate.ToString(DateFmt)),
		new("dateOfService",         "Date of Service",          "Dates",     PhiKind.None,     c => c.DateOfService.ToString(DateFmt)),
		new("dischargeDate",         "Discharge Date",           "Dates",     PhiKind.None,     c => c.DischargeDate?.ToString(DateFmt) ?? ""),
		new("sentDate",              "Sent Date",                "Dates",     PhiKind.None,     c => c.SentDate?.ToString(DateFmt) ?? ""),
		new("lastChanged",           "Last Changed",             "Dates",     PhiKind.None,     c => c.LastChangedDate.ToString("MM/dd/yyyy HH:mm")),
		new("lastImageReceipt",      "Last Image Receipt",       "Dates",     PhiKind.None,     c => c.LastImageReceiptDate ?? ""),
		// Provider & location
		new("physician",             "Physician",                "Provider & Location", PhiKind.None, c => c.PhysicianName ?? ""),
		new("midLevel",              "Mid Level",                "Provider & Location", PhiKind.None, c => c.MidLevel ?? ""),
		new("locationCode",          "Location Code",            "Provider & Location", PhiKind.None, c => c.LocationCode ?? ""),
		new("observationDepartment", "OB Department",           "Provider & Location", PhiKind.None, c => c.ObservationDepartment ?? ""),
		new("observationArrivalSource","OB Arrival Source",      "Provider & Location", PhiKind.None, c => c.ObservationArrivalSource ?? ""),
		// Assignment & notes
		new("assignedToFirst",       "Assigned To (First)",      "Assignment & Notes", PhiKind.None,     c => c.AssignedToFirstName ?? ""),
		new("assignedToLast",        "Assigned To (Last)",       "Assignment & Notes", PhiKind.None,     c => c.AssignedToLastName ?? ""),
		new("clientComment",         "Client Comment",           "Assignment & Notes", PhiKind.FreeText, c => c.ClientComment ?? ""),
		new("coderNotes",            "Coder Notes",              "Assignment & Notes", PhiKind.FreeText, c => c.CoderNotes ?? ""),
	];

	private static readonly Dictionary<string, DataStationField> ByKey =
		All.ToDictionary(f => f.Key, StringComparer.Ordinal);

	public static bool TryGet(string key, out DataStationField field) => ByKey.TryGetValue(key, out field!);

	/// <summary>Applies the masking rule for <paramref name="field"/> to an already-read value.</summary>
	public static string Mask(DataStationField field, string value, ChartListItemDto row)
	{
		if (field.Phi == PhiKind.None || value.Length == 0) return value;
		return field.Phi switch
		{
			PhiKind.Name     => Initials(row.PatientFirstName, row.PatientLastName),
			PhiKind.LastFour => value.Length <= 4 ? value : "***" + value[^4..],
			PhiKind.YearOnly => row.PatientDateOfBirth?.Year.ToString() ?? "",
			PhiKind.FreeText => Withheld,
			_                => value,
		};
	}

	private static string Initials(string? first, string? last)
		=> string.Concat(
			first is { Length: > 0 } ? $"{char.ToUpperInvariant(first[0])}." : "",
			last  is { Length: > 0 } ? $"{char.ToUpperInvariant(last[0])}."  : "");
}
