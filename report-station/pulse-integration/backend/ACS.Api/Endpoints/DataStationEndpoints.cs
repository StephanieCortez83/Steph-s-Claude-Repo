using ACS.Modules.Charts.Features.ExportCharts;
using ACS.Modules.Charts.Features.ExportDataStation;
using ACS.Modules.Charts.Features.GetDataStationFields;
using MediatR;

namespace ACS.Api.Endpoints;

public static class DataStationEndpoints
{
	public static void Map(WebApplication app)
	{
		RouteGroupBuilder group = app.MapGroup("/api/data-station").WithTags("DataStation").RequireAuthorization();

		// GET /api/data-station/fields — column catalog and limits for the UI.
		// Requires AllowAccessToDataStation (172) — enforced by AuthorizationBehavior via [HasRight].
		group.MapGet("/fields", async (IMediator mediator, CancellationToken ct) =>
			Results.Ok(await mediator.Send(new GetDataStationFieldsQuery(), ct)))
			.Produces<DataStationFieldsDto>(200);

		// POST /api/data-station/export — raw-data export of the requested columns.
		// Requires 172 + CanSeeDashboard (32); MaskPhi=false additionally requires 173.
		// POST (not GET) because the column list and filters are too large/structured for a query string.
		group.MapPost("/export", async (
			ExportDataStationRequest body, IMediator mediator, CancellationToken ct) =>
		{
			ExportChartsResult result = await mediator.Send(
				new ExportDataStationQuery(body.Filters, body.Columns, body.Format, body.MaskPhi), ct);
			return Results.Stream(result.Content, result.ContentType, result.FileName);
		})
		.Produces(200)
		.ProducesValidationProblem();

		// TODO: GET /options — authorized facilities + chart statuses for the filter pickers.
		// Needs a repository method that reuses the same facility-authorization query as
		// IChartSearchRepository; see INTEGRATION.md "Open items".
	}
}

/// <summary>Request body for POST /api/data-station/export.</summary>
public sealed record ExportDataStationRequest(
	ExportChartsQuery Filters,
	IReadOnlyList<string> Columns,
	string Format,
	bool MaskPhi = true);
