using System.Text;
using ACS.Modules.Charts.Features.ExportCharts;
using ClosedXML.Excel;

namespace ACS.Modules.Charts.Features.ExportDataStation;

/// <summary>
/// Writes Data Station results to CSV or Excel. Shared by every Data Station report so the
/// "raw values only, never a formula" guarantee lives in exactly one place.
/// </summary>
public static class DataStationFileWriter
{
	private const string ExcelContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

	public static ExportChartsResult Build(
		string format,
		IReadOnlyList<string> captions,
		IEnumerable<IReadOnlyList<string>> rows,
		string sheetName,
		string fileBaseName)
		=> format == "excel" ? BuildExcel(captions, rows, sheetName, fileBaseName) : BuildCsv(captions, rows, fileBaseName);

	private static ExportChartsResult BuildExcel(
		IReadOnlyList<string> captions, IEnumerable<IReadOnlyList<string>> rows, string sheetName, string fileBaseName)
	{
		using XLWorkbook workbook = new XLWorkbook();
		IXLWorksheet ws = workbook.Worksheets.Add(sheetName);

		for (int c = 0; c < captions.Count; c++)
		{
			ws.Cell(1, c + 1).Value = captions[c];
			ws.Cell(1, c + 1).Style.Font.Bold = true;
		}

		int r = 2;
		foreach (IReadOnlyList<string> row in rows)
		{
			// Always written as text values: stored data, never formulas.
			for (int c = 0; c < row.Count; c++) ws.Cell(r, c + 1).Value = row[c];
			r++;
		}

		MemoryStream stream = new MemoryStream();
		workbook.SaveAs(stream);
		stream.Position = 0;
		return new ExportChartsResult(stream, ExcelContentType, fileBaseName + ".xlsx");
	}

	private static ExportChartsResult BuildCsv(
		IReadOnlyList<string> captions, IEnumerable<IReadOnlyList<string>> rows, string fileBaseName)
	{
		MemoryStream stream = new MemoryStream();
		using StreamWriter writer = new StreamWriter(stream, new UTF8Encoding(encoderShouldEmitUTF8Identifier: true), leaveOpen: true);

		writer.WriteLine(string.Join(",", captions.Select(CsvEscape)));
		foreach (IReadOnlyList<string> row in rows)
			writer.WriteLine(string.Join(",", row.Select(CsvEscape)));

		writer.Flush();
		stream.Position = 0;
		return new ExportChartsResult(stream, "text/csv", fileBaseName + ".csv");
	}

	/// <summary>
	/// RFC-4180 quoting, plus neutralising spreadsheet formula injection: a stored value that starts
	/// with = + - @ would be executed as a formula when the CSV is opened in Excel, so it is prefixed
	/// with a single quote. (Data Station returns raw data — it must never *become* a calculation.)
	/// </summary>
	public static string CsvEscape(string value)
	{
		if (value.Length == 0) return value;
		if (value[0] is '=' or '+' or '-' or '@') value = "'" + value;
		if (value.Contains(',') || value.Contains('"') || value.Contains('\n') || value.Contains('\r'))
			return $"\"{value.Replace("\"", "\"\"")}\"";
		return value;
	}
}
