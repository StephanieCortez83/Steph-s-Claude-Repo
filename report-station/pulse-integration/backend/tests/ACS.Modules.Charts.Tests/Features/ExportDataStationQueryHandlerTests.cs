using ACS.Modules.Charts.Features.ExportCharts;
using ACS.Modules.Charts.Features.ExportDataStation;
using ACS.Modules.Charts.Features.SearchCharts;
using ACS.Modules.Charts.Repositories;
using ACS.Shared;
using ACS.Shared.Contracts;
using FluentValidation.TestHelper;
using Xunit;

namespace ACS.Modules.Charts.Tests.Features;

// ASSUMPTIONS: xunit + FluentValidation.TestHelper (the validator tests use TestValidate); hand-written
// fakes are used instead of a mocking library because the project's choice isn't visible from here.
public sealed class ExportDataStationQueryHandlerTests
{
	private static readonly ChartListItemDto Row = new()
	{
		Facility = "TIA - Playa Vista", ChartId = 1048211, MedicalRecordNumber = "MRN12345678",
		PatientName = "REYES, ANA", PatientFirstName = "Ana", PatientLastName = "Reyes",
		PatientDateOfBirth = new DateTime(1958, 4, 11), Status = "Billed",
		ClientComment = "call back, re: =SUM(A1)", ReceivedDate = new DateTime(2026, 6, 3), DateOfService = new DateTime(2026, 6, 2),
	};

	private sealed class FakeRepo(params ChartListItemDto[] rows) : IChartSearchRepository
	{
		public int? LastMax;
		public Task<PagedResult<ChartListItemDto>> SearchAsync(SearchChartsQuery query, CancellationToken ct) => throw new NotSupportedException();
		public Task<IReadOnlyList<ChartListItemDto>> ExportAsync(ExportChartsQuery query, int maxCount, CancellationToken ct)
		{ LastMax = maxCount; return Task.FromResult<IReadOnlyList<ChartListItemDto>>(rows); }
	}

	private sealed class FakeUser(bool canUnmask) : ICurrentUserService
	{
		public bool HasRight(int rightId) => canUnmask && rightId == UserRight.AllowDataStationUnmaskedPhi;
	}

	private static ExportChartsQuery Filters() => new("1", "5", "csv", DosFrom: new DateOnly(2026, 6, 1));

	private static async Task<string> RunCsv(bool mask, bool canUnmask, params string[] cols)
	{
		FakeRepo repo = new(Row);
		ExportDataStationQueryHandler h = new(repo, new FakeUser(canUnmask));
		ExportChartsResult r = await h.Handle(new ExportDataStationQuery(Filters(), cols, "csv", mask), default);
		using StreamReader sr = new(r.Content);
		return (await sr.ReadToEndAsync()).TrimStart('﻿');
	}

	[Fact]
	public async Task Returns_only_requested_columns_in_requested_order()
	{
		string csv = await RunCsv(true, false, "status", "facility");
		Assert.Equal("Status,Facility\r\nBilled,TIA - Playa Vista\r\n".Replace("\r\n", Environment.NewLine), csv);
	}

	[Fact]
	public async Task Masks_phi_by_default()
	{
		string csv = await RunCsv(true, false, "patientName", "medicalRecordNumber", "dateOfBirth", "clientComment");
		Assert.Contains("A.R.,***5678,1958,[withheld]", csv);
	}

	[Fact]
	public async Task Unmasked_export_requires_the_unmask_right()
	{
		await Assert.ThrowsAsync<UnauthorizedAccessException>(() => RunCsv(false, false, "patientName"));
		string csv = await RunCsv(false, true, "medicalRecordNumber");
		Assert.Contains("MRN12345678", csv);
	}

	[Fact]
	public async Task Stored_text_that_looks_like_a_formula_is_neutralised()
	{
		string csv = await RunCsv(false, true, "clientComment");
		Assert.Contains("\"call back, re: =SUM(A1)\"", csv);           // mid-string '=' is harmless
		Assert.Equal("'=1+1", DataStationFileWriter.CsvEscape("=1+1")); // leading '=' is not
	}

	[Fact]
	public async Task Passes_the_row_cap_to_the_repository()
	{
		FakeRepo repo = new(Row);
		await new ExportDataStationQueryHandler(repo, new FakeUser(false))
			.Handle(new ExportDataStationQuery(Filters(), ["facility"], "csv"), default);
		Assert.Equal(3001, repo.LastMax);
	}

	[Fact]
	public void Catalog_has_no_calculated_fields_and_unique_keys()
	{
		Assert.Equal(DataStationFields.All.Count, DataStationFields.All.Select(f => f.Key).Distinct().Count());
		Assert.DoesNotContain(DataStationFields.All, f => f.Key.Contains("total", StringComparison.OrdinalIgnoreCase)
			|| f.Key.Contains("rate", StringComparison.OrdinalIgnoreCase) || f.Key.Contains("count", StringComparison.OrdinalIgnoreCase));
	}
}

public sealed class ExportDataStationQueryValidatorTests
{
	private readonly ExportDataStationQueryValidator _v = new();
	private static ExportChartsQuery F() => new("1", "5", null, DosFrom: new DateOnly(2026, 6, 1));

	[Fact]
	public void Valid_request_passes()
		=> _v.TestValidate(new ExportDataStationQuery(F(), ["facility", "status"], "csv")).ShouldNotHaveAnyValidationErrors();

	[Fact]
	public void Unknown_or_repeated_or_missing_columns_fail()
	{
		_v.TestValidate(new ExportDataStationQuery(F(), ["total_billed"], "csv")).ShouldHaveAnyValidationError();
		_v.TestValidate(new ExportDataStationQuery(F(), ["facility", "facility"], "csv")).ShouldHaveAnyValidationError();
		_v.TestValidate(new ExportDataStationQuery(F(), [], "csv")).ShouldHaveAnyValidationError();
	}

	[Fact]
	public void Bad_format_or_filters_fail()
	{
		_v.TestValidate(new ExportDataStationQuery(F(), ["facility"], "json")).ShouldHaveAnyValidationError();
		_v.TestValidate(new ExportDataStationQuery(new ExportChartsQuery("", "5"), ["facility"], "csv")).ShouldHaveAnyValidationError();
	}
}
