using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web.UI;

namespace ACS.Core.Utility
{
    public class DateUtility
    {
        public const String quote = "\'";

        public static string FormatWhereClauseForEffectiveDate(DateTime asOfDate, string tablePrefix = "")
        {
            tablePrefix = !string.IsNullOrWhiteSpace(tablePrefix) ? $"{tablePrefix}." : tablePrefix;
            string strDate = quote + asOfDate.ToShortDateString() + " " + asOfDate.ToShortTimeString() + quote;

            var inactiveWhereClause = $@"(
	                                        {tablePrefix}[EFFECTIVE_DATE] IS NULL
	                                        OR
	                                        {tablePrefix}[EFFECTIVE_DATE] <= {strDate}
                                        )
                                        AND
                                        (
	                                        {tablePrefix}[EXPIRATION_DATE] IS NULL
	                                        OR
	                                        {tablePrefix}[EXPIRATION_DATE] >= {strDate}
                                        )";
            
            return inactiveWhereClause;
        }

        public static String ToDBDate(DateTime dt)
        {
            if (dt != DateTime.MinValue)
            {
                return quote + dt.ToShortDateString() + " " + dt.ToShortTimeString() + quote;
            }
            else
            {
                return "NULL";
            }
        }
    }
}
