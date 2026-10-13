namespace ACS.Modules.Charts.DataAccess;

/// <summary>One log note, projected for the Data Station report (aliased to PascalCase so Dapper maps it by name).</summary>
public sealed class DataStationLogNoteRow
{
	public long LogNoteId { get; set; }
	public int ChartId { get; set; }
	public string? Summary { get; set; }
	public string? Detail { get; set; }
	public bool SystemDefined { get; set; }
	public DateTime? CompletionDate { get; set; }
	public string? CompletedByName { get; set; }
	public int? CategoryId { get; set; }
	public string? CategoryDescription { get; set; }
	/// <summary>Event timestamp for Completed / Approved / Demographics-Completed notes (from CHART_ACCESS).</summary>
	public DateTime? AccessDateTime { get; set; }
	public DateTime? CreationDateTime { get; set; }
}

public interface IDataStationLogNoteDataAccess
{
	/// <summary>
	/// Log notes for many charts at once (no pagination, no per-chart round trips).
	/// Returns at most <paramref name="maxRows"/> rows ordered by chart, then creation time.
	/// Callers must already have verified the user is authorized for every chart in <paramref name="chartIds"/>.
	/// </summary>
	Task<IReadOnlyList<DataStationLogNoteRow>> GetForChartsAsync(
		IReadOnlyCollection<int> chartIds,
		DateOnly? noteFrom,
		DateOnly? noteTo,
		IReadOnlyCollection<int>? categoryIds,
		bool includeSystemNotes,
		int maxRows,
		CancellationToken ct);
}
