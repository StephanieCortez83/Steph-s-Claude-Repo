using ACS.Modules.Charts.Features.ExportCharts;
using ACS.Modules.Charts.Features.ExportDataStation;
using ACS.Modules.Charts.Features.ExportDataStationLogNotes;
using ACS.Modules.Charts.Features.GetDataStationFields;
using MediatR;

namespace ACS.Api.Endpoints;

public static class DataStationEndpoints
{
	public static void Map(WebApplication app)
	{
		RouteGroupBuilder group = app.MapGroup("/api/data-station").WithTags("DataStation").RequireAuthorization();

		// GET /api/data-station/fields?report=chart|logNotes — column catalog and limits for the UI.
		// Requires AllowAccessToDataStation (172) — enforced by AuthorizationBehavior via [HasRight].
		group.MapGet("/fields", async (string? report, IMediator mediator, CancellationToken ct) =>
			Results.Ok(await mediator.Send(new GetDataStationFieldsQuery(report ?? DataStationReports.Chart), ct)))
			.Produces<DataStationFieldsDto>(200)
			.ProducesValidationProblem();

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

		// POST /api/data-station/log-notes/export — "Chart Log Notes" report: one row per log note.
		// Requires 172 + CanSeeDashboard (32) + Charts (3); MaskPhi=false additionally requires 173.
		// 400 (validation problem) when the selection is too large — narrow the filters; never silently truncated.
		group.MapPost("/log-notes/export", async (
			ExportDataStationLogNotesRequest body, IMediator mediator, CancellationToken ct) =>
		{
			ExportChartsResult result = await mediator.Send(
				new ExportDataStationLogNotesQuery(body.Filters, body.Columns, body.Format, body.MaskPhi,
					body.NoteFrom, body.NoteTo, body.CategoryIds, body.IncludeSystemNotes), ct);
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

/// <summary>Request body for POST /api/data-station/log-notes/export.</summary>
public sealed record ExportDataStationLogNotesRequest(
	ExportChartsQuery Filters,
	IReadOnlyList<string> Columns,
	string Format,
	bool MaskPhi = true,
	DateOnly? NoteFrom = null,
	DateOnly? NoteTo = null,
	string? CategoryIds = null,
	bool IncludeSystemNotes = true);
