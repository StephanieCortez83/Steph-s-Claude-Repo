using System;

namespace ACS.Core.Extensions
{
	public static class DateTimeExtensions
	{
		#region Methods

		public static DateTime SqlSafeMinDate(this DateTime dt, DateTime safeMinDateDefault) =>
			dt < safeMinDateDefault ? safeMinDateDefault : dt;

		public static DateTime SqlSafeMinDate(this DateTime dt, string safeDtStr) =>
			SqlSafeMinDate(dt, DateTime.Parse(safeDtStr));

		public static DateTime SqlSafeMinDate(this DateTime dt) =>
			SqlSafeMinDate(dt, DateTime.Parse("01-01-1900"));

		public static bool BadSearchDate(this DateTime dt) =>
			dt < DateTime.Parse("01-01-1900") || dt.Date >= DateTime.Today.AddDays(1);

		public static DateTime FixBadSearchDate(this DateTime dt, DateTime safeDate) =>
			BadSearchDate(dt) ? safeDate : dt;
		        
        public static DateTime ToCentralTime(this DateTime utcTime)
        {
            if (utcTime.Kind != DateTimeKind.Utc)
                throw new ArgumentException("ToCentralTime() expects a UTC DateTime.", nameof(utcTime));

            return TimeZoneInfo.ConvertTimeFromUtc(utcTime, CentralStandardTimeZone);
        }

        private static readonly TimeZoneInfo CentralStandardTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Central Standard Time");

        #endregion Methods
    }
}
