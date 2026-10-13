using ACS.Modules.Charts.DataAccess;
using ACS.Modules.Charts.Features.ExportCharts;
using ACS.Modules.Charts.Features.ExportDataStationLogNotes;
using ACS.Modules.Charts.Features.SearchCharts;
using ACS.Modules.Charts.Repositories;
using ACS.Shared;
using ACS.Shared.Contracts;
using FluentValidation;
using FluentValidation.TestHelper;
using Xunit;

namespace ACS.Modules.Charts.Tests.Features;

// ASSUMPTIONS: same as ExportDataStationQueryHandlerTests (xunit, FluentValidation.TestHelper, hand-written fakes,
// ICurrentUserService namespace). ValidationException is assumed to surface as a 400 via existing middleware.
public sealed class ExportDataStationLogNotesQueryHandlerTests
{
	private static ChartListItemDto Chart(int id) => new()
	{
		Facility = "TIA - Playa Vista", ChartId = id, FacilityChartId = $"ENC-{id}", MedicalRecordNumber = "MRN12345678",
		PatientName = "REYES, ANA", PatientFirstName = "Ana", PatientLastName = "Reyes", Status = "Billed",
		DateOfService = new DateTime(2026, 6, 2), ReceivedDate = new DateTime(2026, 6, 3),
	};

	private static DataStationLogNoteRow Note(int chartId, long id, string summary, bool system) => new()
	{
		LogNoteId = id, ChartId = chartId, Summary = summary, Detail = "call back, re: =SUM(A1)", SystemDefined = system,
		CategoryDescription = system ? "Completed" : "Coder Note", CompletedByName = "Alvarez, Jamie",
		CreationDateTime = new DateTime(2026, 6, 4, 9, 30, 0),
	};

	private sealed class FakeCharts(params ChartListItemDto[] rows) : IChartSearchRepository
	{
		public int? LastMax;
		public Task<PagedResult<ChartListItemDto>> SearchAsync(SearchChartsQuery q, CancellationToken ct) => throw new NotSupportedException();
		public Task<IReadOnlyList<ChartListItemDto>> ExportAsync(ExportChartsQuery q, int maxCount, CancellationToken ct)
		{ LastMax = maxCount; return Task.FromResult<IReadOnlyList<ChartListItemDto>>(rows); }
	}

	private sealed class FakeNotes(params DataStationLogNoteRow[] rows) : IDataStationLogNoteDataAccess
	{
		public IReadOnlyCollection<int>? ChartIds; public int? MaxRows; public bool? IncludeSystem;
		public Task<IReadOnlyList<DataStationLogNoteRow>> GetForChartsAsync(IReadOnlyCollection<int> chartIds, DateOnly? from, DateOnly? to,
			IReadOnlyCollection<int>? categoryIds, bool includeSystemNotes, int maxRows, CancellationToken ct)
		{ ChartIds = chartIds; MaxRows = maxRows; IncludeSystem = includeSystemNotes; return Task.FromResult<IReadOnlyList<DataStationLogNoteRow>>(rows); }
	}

	private sealed class FakeUser(bool canUnmask) : ICurrentUserService
	{
		public bool HasRight(int rightId) => canUnmask && rightId == UserRight.AllowDataStationUnmaskedPhi;
	}

	private static ExportChartsQuery Filters() => new("1", "5", "csv", DosFrom: new DateOnly(2026, 6, 1));

	private static async Task<string> RunCsv(FakeCharts charts, FakeNotes notes, bool mask, bool canUnmask, params string[] cols)
	{
		ExportDataStationLogNotesQueryHandler h = new(charts, notes, new FakeUser(canUnmask));
		ExportChartsResult r = await h.Handle(new ExportDataStationLogNotesQuery(Filters(), cols, "csv", mask), default);
		using StreamReader sr = new(r.Content);
		return (await sr.ReadToEndAsync()).TrimStart('﻿');
	}

	[Fact]
	public async Task One_row_per_note_with_chart_context_in_requested_order()
	{
		FakeCharts charts = new(Chart(1), Chart(2));
		FakeNotes notes = new(Note(1, 100, "Chart completed", true), Note(1, 101, "Needs query", false), Note(2, 102, "Approved", true));
		string csv = await RunCsv(charts, notes, true, false, "facilityChartId", "summary");
		string[] lines = csv.Split(["\r\n", "\n"], StringSplitOptions.RemoveEmptyEntries);
		Assert.Equal("Facility Chart ID,Summary", lines[0]);
		Assert.Equal(4, lines.Length);                                     // header + 3 notes
		Assert.Contains("ENC-2,Approved", lines[3]);
	}

	[Fact]
	public async Task Masking_withholds_user_written_text_but_keeps_system_text_and_masks_patient_fields()
	{
		FakeCharts charts = new(Chart(1));
		FakeNotes notes = new(Note(1, 100, "Chart completed", true), Note(1, 101, "Pt called about bill", false));
		string csv = await RunCsv(charts, notes, true, false, "summary", "detail", "patientName", "medicalRecordNumber");
		Assert.Contains("Chart completed,\"call back, re: =SUM(A1)\",A.R.,***5678", csv);   // system note shown
		Assert.Contains("[withheld],[withheld],A.R.,***5678", csv);                          // user note withheld
		Assert.DoesNotContain("Pt called about bill", csv);
	}

	[Fact]
	public async Task Unmasked_requires_the_unmask_right()
	{
		FakeCharts charts = new(Chart(1)); FakeNotes notes = new(Note(1, 101, "Pt called about bill", false));
		await Assert.ThrowsAsync<UnauthorizedAccessException>(() => RunCsv(charts, notes, false, false, "summary"));
		Assert.Contains("Pt called about bill", await RunCsv(charts, notes, false, true, "summary"));
	}

	[Fact]
	public async Task Notes_are_fetched_only_for_the_authorized_charts_returned_by_the_chart_repository()
	{
		FakeCharts charts = new(Chart(7), Chart(9)); FakeNotes notes = new();
		await RunCsv(charts, notes, true, false, "summary");
		Assert.Equal(new[] { 7, 9 }, notes.ChartIds!.OrderBy(i => i));
	}

	[Fact]
	public async Task Too_many_charts_is_an_error_not_a_silent_truncation()
	{
		FakeCharts charts = new(Enumerable.Range(1, ExportDataStationLogNotesQueryHandler.MaxCharts + 1).Select(Chart).ToArray());
		await Assert.ThrowsAsync<ValidationException>(() => RunCsv(charts, new FakeNotes(), true, false, "summary"));
		Assert.Equal(ExportDataStationLogNotesQueryHandler.MaxCharts + 1, charts.LastMax);
	}

	[Fact]
	public async Task Too_many_notes_is_an_error_not_a_silent_truncation()
	{
		DataStationLogNoteRow[] many = Enumerable.Range(1, ExportDataStationLogNotesQueryHandler.MaxNoteRows + 1)
			.Select(i => Note(1, i, "x", true)).ToArray();
		await Assert.ThrowsAsync<ValidationException>(() => RunCsv(new FakeCharts(Chart(1)), new FakeNotes(many), true, false, "summary"));
	}

	[Fact]
	public void Catalog_is_raw_only_with_unique_keys()
	{
		Assert.Equal(DataStationLogNoteFields.All.Count, DataStationLogNoteFields.All.Select(f => f.Key).Distinct().Count());
		Assert.DoesNotContain(DataStationLogNoteFields.All, f => f.Key.Contains("count", StringComparison.OrdinalIgnoreCase)
			|| f.Key.Contains("total", StringComparison.OrdinalIgnoreCase) || f.Key.Contains("age", StringComparison.OrdinalIgnoreCase));
	}
}

public sealed class ExportDataStationLogNotesQueryValidatorTests
{
	private readonly ExportDataStationLogNotesQueryValidator _v = new();
	private static ExportChartsQuery F() => new("1", "5", null, DosFrom: new DateOnly(2026, 6, 1));

	[Fact]
	public void Valid_request_passes()
		=> _v.TestValidate(new ExportDataStationLogNotesQuery(F(), ["summary", "facility"], "csv",
			NoteFrom: new DateOnly(2026, 6, 1), NoteTo: new DateOnly(2026, 6, 30), CategoryIds: "2, 3")).ShouldNotHaveAnyValidationErrors();

	[Fact]
	public void Chart_columns_are_not_log_note_columns()
		=> _v.TestValidate(new ExportDataStationLogNotesQuery(F(), ["emr"], "csv")).ShouldHaveAnyValidationError();

	[Fact]
	public void Reversed_note_dates_bad_categories_and_bad_filters_fail()
	{
		_v.TestValidate(new ExportDataStationLogNotesQuery(F(), ["summary"], "csv",
			NoteFrom: new DateOnly(2026, 6, 30), NoteTo: new DateOnly(2026, 6, 1))).ShouldHaveAnyValidationError();
		_v.TestValidate(new ExportDataStationLogNotesQuery(F(), ["summary"], "csv", CategoryIds: "a,b")).ShouldHaveAnyValidationError();
		_v.TestValidate(new ExportDataStationLogNotesQuery(new ExportChartsQuery("", "5"), ["summary"], "csv")).ShouldHaveAnyValidationError();
	}
}
