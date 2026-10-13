using ACS.Modules.Charts.Features.ExportDataStation;
using ACS.Shared.Contracts;
using MediatR;

namespace ACS.Modules.Charts.Features.GetDataStationFields;

/// <summary>Column catalog + limits for the Data Station UI, so the UI never hard-codes them.</summary>
[HasRight(UserRight.AllowAccessToDataStation)]
public sealed record GetDataStationFieldsQuery : IRequest<DataStationFieldsDto>;

public sealed record DataStationFieldDto(string Key, string Caption, string Group, bool Phi);

public sealed record DataStationFieldsDto(
	IReadOnlyList<DataStationFieldDto> Fields,
	int MaxRows,
	int MaxColumns,
	IReadOnlyList<string> DateBases);

public sealed class GetDataStationFieldsQueryHandler : IRequestHandler<GetDataStationFieldsQuery, DataStationFieldsDto>
{
	public Task<DataStationFieldsDto> Handle(GetDataStationFieldsQuery request, CancellationToken ct)
		=> Task.FromResult(new DataStationFieldsDto(
			DataStationFields.All
				.Select(f => new DataStationFieldDto(f.Key, f.Caption, f.Group, f.Phi != PhiKind.None))
				.ToList(),
			ExportDataStationQueryHandler.MaxExportCount,
			ExportDataStationQueryValidator.MaxColumns,
			// Keys match the ExportChartsQuery From/To pairs.
			["dos", "received", "sent", "discharge", "approved", "completed"]));
}
