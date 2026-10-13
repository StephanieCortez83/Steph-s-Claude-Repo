using ACS.Modules.Charts.Features.ExportCharts;
using ACS.Shared.Contracts;
using MediatR;

namespace ACS.Modules.Charts.Features.ExportDataStation;

/// <summary>
/// Self-service raw-data export. Returns exactly the requested columns, in the requested order,
/// for the rows matched by <see cref="Filters"/> — stored values only, no calculations.
///
/// Rights (AND-ed by AuthorizationBehavior):
///   AllowAccessToDataStation (172) — may use the Data Station
///   CanSeeDashboard (32)           — same right the underlying chart export requires
/// Turning <see cref="MaskPhi"/> off additionally requires AllowDataStationUnmaskedPhi (173);
/// that check lives in the handler because it depends on the request payload.
/// </summary>
[HasRight(UserRight.AllowAccessToDataStation)]
[HasRight(UserRight.CanSeeDashboard)]
public record ExportDataStationQuery(
	/// <summary>Same filter contract as the chart search export (facilities, statuses, date ranges, ...).</summary>
	ExportChartsQuery Filters,
	/// <summary>Column keys from <see cref="DataStationFields"/>, in output order.</summary>
	IReadOnlyList<string> Columns,
	/// <summary>"csv" or "excel".</summary>
	string Format,
	/// <summary>Default true. false requires AllowDataStationUnmaskedPhi.</summary>
	bool MaskPhi = true
) : IRequest<ExportChartsResult>;
