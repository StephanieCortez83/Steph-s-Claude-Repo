using ACS.Modules.Charts.Features.ExportDataStation;
using ACS.Modules.Charts.Features.ExportDataStationLogNotes;
using ACS.Shared.Contracts;
using FluentValidation;
using MediatR;

namespace ACS.Modules.Charts.Features.GetDataStationFields;

/// <summary>
/// Column catalog + limits for the Data Station UI, so the UI never hard-codes them.
/// <paramref name="Report"/> is "chart" (default) or "logNotes".
/// </summary>
[HasRight(UserRight.AllowAccessToDataStation)]
public sealed record GetDataStationFieldsQuery(string Report = DataStationReports.Chart) : IRequest<DataStationFieldsDto>;

public static class DataStationReports
{
	public const string Chart = "chart";
	public const string LogNotes = "logNotes";
}

public sealed record DataStationFieldDto(string Key, string Caption, string Group, bool Phi);

public sealed record DataStationFieldsDto(
	string Report,
	IReadOnlyList<DataStationFieldDto> Fields,
	int MaxRows,
	int MaxColumns,
	IReadOnlyList<string> DateBases);

public sealed class GetDataStationFieldsQueryHandler : IRequestHandler<GetDataStationFieldsQuery, DataStationFieldsDto>
{
	// Keys match the ExportChartsQuery From/To pairs (they select the charts in both reports).
	private static readonly string[] DateBases = ["dos", "received", "sent", "discharge", "approved", "completed"];

	public Task<DataStationFieldsDto> Handle(GetDataStationFieldsQuery request, CancellationToken ct)
	{
		DataStationFieldsDto dto = request.Report switch
		{
			DataStationReports.Chart => new DataStationFieldsDto(
				request.Report,
				DataStationFields.All.Select(f => new DataStationFieldDto(f.Key, f.Caption, f.Group, f.Phi != PhiKind.None)).ToList(),
				ExportDataStationQueryHandler.MaxExportCount,
				ExportDataStationQueryValidator.MaxColumns,
				DateBases),
			DataStationReports.LogNotes => new DataStationFieldsDto(
				request.Report,
				DataStationLogNoteFields.All.Select(f => new DataStationFieldDto(f.Key, f.Caption, f.Group, f.Phi != PhiKind.None)).ToList(),
				ExportDataStationLogNotesQueryHandler.MaxNoteRows,
				ExportDataStationQueryValidator.MaxColumns,
				DateBases),
			_ => throw new ValidationException($"Unknown report '{request.Report}'. Use '{DataStationReports.Chart}' or '{DataStationReports.LogNotes}'."),
		};
		return Task.FromResult(dto);
	}
}
