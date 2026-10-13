using ACS.Modules.Charts.Features.ExportCharts;
using FluentValidation;

namespace ACS.Modules.Charts.Features.ExportDataStation;

// NOTE: All rules are synchronous — use TestValidate() in tests, not TestValidateAsync().

/// <summary>
/// Validates <see cref="ExportDataStationQuery"/>. Filter rules are delegated to
/// <see cref="ExportChartsQueryValidator"/> so the two exports can never drift apart.
/// </summary>
public sealed class ExportDataStationQueryValidator : AbstractValidator<ExportDataStationQuery>
{
	public const int MaxColumns = 40;

	public ExportDataStationQueryValidator()
	{
		RuleFor(q => q.Format)
			.NotEmpty().WithMessage("Export format is required.")
			.Must(f => f is "csv" or "excel").WithMessage("Format must be 'csv' or 'excel'.");

		RuleFor(q => q.Filters)
			.NotNull().WithMessage("Filters are required.")
			.SetValidator(new ExportChartsQueryValidator());

		RuleFor(q => q.Columns)
			.NotEmpty().WithMessage("Select at least one column.")
			.Must(c => c.Count <= MaxColumns).WithMessage($"Select at most {MaxColumns} columns.")
			.Must(c => c.Distinct(StringComparer.Ordinal).Count() == c.Count).WithMessage("Columns must not repeat.");

		RuleForEach(q => q.Columns)
			.Must(key => DataStationFields.TryGet(key, out _))
			.WithMessage((_, key) => $"'{key}' is not an exportable Data Station column.");
	}
}
