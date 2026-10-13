using ACS.Modules.Charts.DataAccess;
using ACS.Modules.Charts.Features.ExportCharts;
using ACS.Modules.Charts.Features.ExportDataStation;
using ACS.Modules.Charts.Features.SearchCharts;
using ACS.Modules.Charts.Repositories;
using ACS.Shared.Contracts;
using FluentValidation;
using MediatR;

namespace ACS.Modules.Charts.Features.ExportDataStationLogNotes;

public sealed class ExportDataStationLogNotesQueryHandler : IRequestHandler<ExportDataStationLogNotesQuery, ExportChartsResult>
{
	/// <summary>Max charts a log-note report may cover (same cap as the chart export).</summary>
	public const int MaxCharts = ExportDataStationQueryHandler.MaxExportCount;

	/// <summary>Max note rows in one file. Over the cap the user is asked to narrow the filters — never silently truncated.</summary>
	public const int MaxNoteRows = 20_000;

	private readonly IChartSearchRepository _charts;
	private readonly IDataStationLogNoteDataAccess _notes;
	private readonly ICurrentUserService _user;

	// ASSUMPTION: ICurrentUserService as in ExportDataStationQueryHandler — confirm namespace.
	public ExportDataStationLogNotesQueryHandler(
		IChartSearchRepository charts, IDataStationLogNoteDataAccess notes, ICurrentUserService user)
	{
		_charts = charts;
		_notes = notes;
		_user = user;
	}

	public async Task<ExportChartsResult> Handle(ExportDataStationLogNotesQuery request, CancellationToken ct)
	{
		if (!request.MaskPhi && !_user.HasRight(UserRight.AllowDataStationUnmaskedPhi))
			throw new UnauthorizedAccessException("Turning off PHI masking requires the Allow Data Station Unmasked PHI right.");

		// 1) Charts — facility authorization is enforced inside the repository, exactly as for ExportCharts.
		//    Ask for one more than the cap so an over-large selection is detected instead of silently cut.
		IReadOnlyList<ChartListItemDto> charts = await _charts.ExportAsync(request.Filters, MaxCharts + 1, ct);
		if (charts.Count > MaxCharts)
			throw new ValidationException($"More than {MaxCharts:N0} charts match these filters. Narrow the facility, status, or date range.");

		// 2) Notes for exactly those (already-authorized) charts, in one batched query.
		IReadOnlyList<DataStationLogNoteRow> notes = await _notes.GetForChartsAsync(
			charts.Select(c => c.ChartId).Distinct().ToList(),
			request.NoteFrom, request.NoteTo, ParseIds(request.CategoryIds),
			request.IncludeSystemNotes, MaxNoteRows + 1, ct);
		if (notes.Count > MaxNoteRows)
			throw new ValidationException($"More than {MaxNoteRows:N0} log notes match these filters. Narrow the date range or categories, or exclude system notes.");

		// 3) One row per note. Charts with no matching notes simply have no rows.
		Dictionary<int, ChartListItemDto> chartById = charts.GroupBy(c => c.ChartId).ToDictionary(g => g.Key, g => g.First());
		List<DataStationLogNoteField> columns = request.Columns.Select(k => DataStationLogNoteFields.TryGet(k, out DataStationLogNoteField f)
			? f : throw new ArgumentException($"Unknown column '{k}'.")).ToList();

		IEnumerable<IReadOnlyList<string>> body = notes
			.Where(n => chartById.ContainsKey(n.ChartId))
			.Select(n => new LogNoteReportRow(chartById[n.ChartId], n))
			.Select(row => (IReadOnlyList<string>)columns.Select(c =>
			{
				string value = c.Read(row);
				return request.MaskPhi ? DataStationLogNoteFields.Mask(c, value, row) : value;
			}).ToList());

		return DataStationFileWriter.Build(request.Format, columns.Select(c => c.Caption).ToList(), body,
			"Log Notes", "data-station-log-notes");
	}

	private static IReadOnlyCollection<int>? ParseIds(string? csv)
		=> string.IsNullOrWhiteSpace(csv)
			? null
			: csv.Split(',', StringSplitOptions.RemoveEmptyEntries).Select(s => int.Parse(s.Trim())).ToList();
}
