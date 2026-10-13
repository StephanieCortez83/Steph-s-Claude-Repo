using ACS.Modules.Charts.Features.ExportCharts;
using ACS.Modules.Charts.Features.SearchCharts;
using ACS.Modules.Charts.Repositories;
using ACS.Shared.Contracts;
using MediatR;

namespace ACS.Modules.Charts.Features.ExportDataStation;

public sealed class ExportDataStationQueryHandler : IRequestHandler<ExportDataStationQuery, ExportChartsResult>
{
	/// <summary>Same cap as the chart export (legacy DashboardView parity).</summary>
	public const int MaxExportCount = 3001;

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

		IEnumerable<IReadOnlyList<string>> body = rows.Select(row =>
			(IReadOnlyList<string>)columns.Select(c => Cell(c, row, request.MaskPhi)).ToList());

		return DataStationFileWriter.Build(request.Format, columns.Select(c => c.Caption).ToList(), body,
			"Data Station", "data-station-export");
	}

	private static string Cell(DataStationField f, ChartListItemDto row, bool mask)
	{
		string value = f.Read(row);
		return mask ? DataStationFields.Mask(f, value, row) : value;
	}
}
