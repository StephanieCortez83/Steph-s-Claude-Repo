using ACS.Modules.Charts.Features.ExportCharts;
using ACS.Modules.Charts.Features.ExportDataStation;
using FluentValidation;

namespace ACS.Modules.Charts.Features.ExportDataStationLogNotes;

// NOTE: All rules are synchronous — use TestValidate() in tests, not TestValidateAsync().

public sealed class ExportDataStationLogNotesQueryValidator : AbstractValidator<ExportDataStationLogNotesQuery>
{
	public ExportDataStationLogNotesQueryValidator()
	{
		RuleFor(q => q.Format)
			.NotEmpty().WithMessage("Export format is required.")
			.Must(f => f is "csv" or "excel").WithMessage("Format must be 'csv' or 'excel'.");

		// Chart selection rules are shared with the chart export so the two never drift apart.
		RuleFor(q => q.Filters)
			.NotNull().WithMessage("Filters are required.")
			.SetValidator(new ExportChartsQueryValidator());

		RuleFor(q => q.Columns)
			.NotEmpty().WithMessage("Select at least one column.")
			.Must(c => c.Count <= ExportDataStationQueryValidator.MaxColumns)
			.WithMessage($"Select at most {ExportDataStationQueryValidator.MaxColumns} columns.")
			.Must(c => c.Distinct(StringComparer.Ordinal).Count() == c.Count).WithMessage("Columns must not repeat.");

		RuleForEach(q => q.Columns)
			.Must(key => DataStationLogNoteFields.TryGet(key, out _))
			.WithMessage((_, key) => $"'{key}' is not an exportable log-note column.");

		RuleFor(q => q.NoteTo)
			.Must((q, to) => !to.HasValue || !q.NoteFrom.HasValue || to.Value >= q.NoteFrom.Value)
			.When(q => q.NoteTo.HasValue)
			.WithMessage("Note date end must be on or after note date start.");

		When(q => !string.IsNullOrWhiteSpace(q.CategoryIds), () =>
		{
			RuleFor(q => q.CategoryIds!)
				.Must(s => s.Split(',', StringSplitOptions.RemoveEmptyEntries).All(p => int.TryParse(p.Trim(), out int n) && n > 0))
				.WithMessage("Category IDs must be a comma-separated list of positive IDs.");
		});
	}
}
