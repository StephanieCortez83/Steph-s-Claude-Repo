using System.Text;
using ACS.Modules.Charts.Features.ExportCharts;
using ACS.Modules.Charts.Features.SearchCharts;
using ACS.Modules.Charts.Repositories;
using ACS.Shared.Contracts;
using ClosedXML.Excel;
using MediatR;

namespace ACS.Modules.Charts.Features.ExportDataStation;

public sealed class ExportDataStationQueryHandler : IRequestHandler<ExportDataStationQuery, ExportChartsResult>
{
	/// <summary>Same cap as the chart export (legacy DashboardView parity).</summary>
	public const int MaxExportCount = 3001;

	private const string ExcelContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

	private readonly IChartSearchRepository _repository;
	private readonly ICurrentUserService _user;

	// ASSUMPTION: ICurrentUserService (HasRight(int)) is the service AuthorizationBehavior uses —
	// confirm its namespace/registration; adjust the using above if it lives elsewhere.
	public ExportDataStationQueryHandler(IChartSearchRepository repository, ICurrentUserService user)
	{
		_repository = repository;
		_user = user;
	}

	public async Task<ExportChartsResult> Handle(ExportDataStationQuery request, CancellationToken ct)
	{
		if (!request.MaskPhi && !_user.HasRight(UserRight.AllowDataStationUnmaskedPhi))
			throw new UnauthorizedAccessException("Turning off PHI masking requires the Allow Data Station Unmasked PHI right.");

		// Facility authorization + bulk-search right are enforced inside the repository, exactly as for ExportCharts.
		IReadOnlyList<ChartListItemDto> rows = await _repository.ExportAsync(request.Filters, MaxExportCount, ct);

		List<DataStationField> columns = request.Columns.Select(k => DataStationFields.TryGet(k, out DataStationField f)
			? f : throw new ArgumentException($"Unknown column '{k}'.")).ToList();

		return request.Format == "excel" ? BuildExcel(rows, columns, request.MaskPhi) : BuildCsv(rows, columns, request.MaskPhi);
	}

	private static string Cell(DataStationField f, ChartListItemDto row, bool mask)
	{
		string value = f.Read(row);
		return mask ? DataStationFields.Mask(f, value, row) : value;
	}

	private static ExportChartsResult BuildExcel(IReadOnlyList<ChartListItemDto> rows, List<DataStationField> columns, bool mask)
	{
		using XLWorkbook workbook = new XLWorkbook();
		IXLWorksheet ws = workbook.Worksheets.Add("Data Station");

		for (int c = 0; c < columns.Count; c++)
		{
			ws.Cell(1, c + 1).Value = columns[c].Caption;
			ws.Cell(1, c + 1).Style.Font.Bold = true;
		}
		for (int r = 0; r < rows.Count; r++)
			for (int c = 0; c < columns.Count; c++)
				ws.Cell(r + 2, c + 1).Value = Cell(columns[c], rows[r], mask); // always text: stored values, never formulas

		MemoryStream stream = new MemoryStream();
		workbook.SaveAs(stream);
		stream.Position = 0;
		return new ExportChartsResult(stream, ExcelContentType, "data-station-export.xlsx");
	}

	private static ExportChartsResult BuildCsv(IReadOnlyList<ChartListItemDto> rows, List<DataStationField> columns, bool mask)
	{
		MemoryStream stream = new MemoryStream();
		using StreamWriter writer = new StreamWriter(stream, new UTF8Encoding(encoderShouldEmitUTF8Identifier: true), leaveOpen: true);

		writer.WriteLine(string.Join(",", columns.Select(c => CsvEscape(c.Caption))));
		foreach (ChartListItemDto row in rows)
			writer.WriteLine(string.Join(",", columns.Select(c => CsvEscape(Cell(c, row, mask)))));

		writer.Flush();
		stream.Position = 0;
		return new ExportChartsResult(stream, "text/csv", "data-station-export.csv");
	}

	/// <summary>
	/// RFC-4180 quoting, plus neutralising spreadsheet formula injection: a stored value that starts
	/// with = + - @ would be executed as a formula when the CSV is opened in Excel, so it is prefixed
	/// with a single quote. (Data Station returns raw data — it must never *become* a calculation.)
	/// </summary>
	internal static string CsvEscape(string value)
	{
		if (value.Length == 0) return value;
		if (value[0] is '=' or '+' or '-' or '@') value = "'" + value;
		if (value.Contains(',') || value.Contains('"') || value.Contains('\n') || value.Contains('\r'))
			return $"\"{value.Replace("\"", "\"\"")}\"";
		return value;
	}
}
