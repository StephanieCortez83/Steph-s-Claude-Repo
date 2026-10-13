using ACS.Shared.Data;
using Dapper;

namespace ACS.Modules.Charts.DataAccess;

public sealed class DataStationLogNoteDataAccess : IDataStationLogNoteDataAccess
{
	private readonly IDbSession _session;

	public DataStationLogNoteDataAccess(IDbSession session) => _session = session;

	public async Task<IReadOnlyList<DataStationLogNoteRow>> GetForChartsAsync(
		IReadOnlyCollection<int> chartIds,
		DateOnly? noteFrom,
		DateOnly? noteTo,
		IReadOnlyCollection<int>? categoryIds,
		bool includeSystemNotes,
		int maxRows,
		CancellationToken ct)
	{
		if (chartIds.Count == 0) return [];

		// Inline SQL (same convention as ChartLogNoteDataAccess) — the projection and joins mirror
		// dbo.GetChartLogNotes. ID lists travel as ONE comma-separated string and are split server-side
		// with STRING_SPLIT: Dapper's `IN @list` expansion creates one parameter per item and a report
		// can cover ~3000 charts, which would exceed SQL Server's 2100-parameter limit.
		IReadOnlyList<DataStationLogNoteRow> rows = (await _session.Connection.QueryAsync<DataStationLogNoteRow>(
			new CommandDefinition(
				"""
				SELECT TOP (@MaxRows)
				       ln.LOG_NOTE_ID                              AS LogNoteId,
				       ln.CHART_ID                                 AS ChartId,
				       ln.SUMMARY                                  AS Summary,
				       ln.DETAIL                                   AS Detail,
				       CAST(ISNULL(ln.SYSTEM_DEFINED, 0) AS bit)   AS SystemDefined,
				       ln.COMPLETION_DATE                          AS CompletionDate,
				       CONCAT(up.LAST_NAME, ', ', up.FIRST_NAME)   AS CompletedByName,
				       ln.CATEGORY_ID                              AS CategoryId,
				       lnc.DESCRIPTION                             AS CategoryDescription,
				       ca.AccessDateTime                           AS AccessDateTime,
				       ln.CREATION_DATE_TIME                       AS CreationDateTime
				FROM   dbo.VW_ACS26_LOG_NOTE ln
				LEFT JOIN dbo.USER_PROFILE up WITH (NOLOCK)
				       ON up.USER_PROFILE_ID = ln.COMPLETED_BY_USER_ID
				LEFT JOIN dbo.LOG_NOTE_CATEGORY lnc WITH (NOLOCK)
				       ON lnc.LOG_NOTE_CATEGORY_ID = ln.CATEGORY_ID
				LEFT JOIN (
				    SELECT CHART_ID,
				           CHART_ACCESS_EVENT_TYPE_CODE,
				           MIN(ACCESS_DATE_TIME) AS AccessDateTime
				    FROM   dbo.CHART_ACCESS WITH (NOLOCK)
				    WHERE  CHART_ID IN (SELECT TRY_CAST(value AS int) FROM STRING_SPLIT(@ChartIds, ','))
				    GROUP  BY CHART_ID, CHART_ACCESS_EVENT_TYPE_CODE
				) ca ON ca.CHART_ID = ln.CHART_ID
				     AND ca.CHART_ACCESS_EVENT_TYPE_CODE = CASE ln.CATEGORY_ID
				         WHEN 2  THEN 'C'
				         WHEN 3  THEN 'A'
				         WHEN 10 THEN 'D'
				         ELSE NULL
				     END
				WHERE  ln.CHART_ID IN (SELECT TRY_CAST(value AS int) FROM STRING_SPLIT(@ChartIds, ','))
				  AND  (@NoteFrom IS NULL        OR ln.CREATION_DATE_TIME >= @NoteFrom)
				  AND  (@NoteToExclusive IS NULL OR ln.CREATION_DATE_TIME <  @NoteToExclusive)
				  AND  (@CategoryIds IS NULL     OR ln.CATEGORY_ID IN (SELECT TRY_CAST(value AS int) FROM STRING_SPLIT(@CategoryIds, ',')))
				  AND  (@IncludeSystemNotes = 1  OR ISNULL(ln.SYSTEM_DEFINED, 0) = 0)
				ORDER BY ln.CHART_ID, ln.CREATION_DATE_TIME, ln.LOG_NOTE_ID
				OPTION (RECOMPILE)
				""",
				new
				{
					MaxRows = maxRows,
					ChartIds = string.Join(',', chartIds),
					NoteFrom = noteFrom?.ToDateTime(TimeOnly.MinValue),
					// "To" is inclusive of the whole day → compare against the start of the next day.
					NoteToExclusive = noteTo?.AddDays(1).ToDateTime(TimeOnly.MinValue),
					CategoryIds = categoryIds is { Count: > 0 } ? string.Join(',', categoryIds) : null,
					IncludeSystemNotes = includeSystemNotes,
				},
				transaction: _session.Transaction,
				cancellationToken: ct))).AsList();

		return rows;
	}
}
