using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Extensions
{
    public static class IntExtensions
    {
        private static readonly RNGCryptoServiceProvider _generator = new RNGCryptoServiceProvider();

        /// <summary>
        /// Takes an enum value and compares it against one or more possible matching enum values.
        /// </summary>
        /// <param name="selected">The value being compared.</param>
        /// <param name="list">The list of matching enum values.</param>
        /// <returns>True if the value is contained in the possible values.</returns>
        public static bool In(this int selected, params int[] list)
        {
            return list.Contains(selected);
        }

        // based on https://scottlilly.com/create-better-random-numbers-in-c/
        public static int RandomBetween(int minimumValue, int maximumValue)
        {
            var randomNumber = new byte[1];

            _generator.GetBytes(randomNumber);

            var asciiValueOfRandomCharacter = Convert.ToDouble(randomNumber[0]);

            // We are using Math.Max, and substracting 0.00000000001, 
            // to ensure "multiplier" will always be between 0.0 and .99999999999
            // Otherwise, it's possible for it to be "1", which causes problems in our rounding.
            var multiplier = Math.Max(0, (asciiValueOfRandomCharacter / 255d) - 0.00000000001d);

            // We need to add one to the range, to allow for the rounding done with Math.Floor
            var range = maximumValue - minimumValue + 1;

            var randomValueInRange = Math.Floor(multiplier * range);

            return (int)(minimumValue + randomValueInRange);
        }

		public static string ToCsv(this List<int> valueList) =>
			string.Join(", ", valueList);

        public static string ToCsv(this int[] valueList) =>
            string.Join(", ", valueList);

        public static string ToCsv(this IEnumerable<int> valueList) =>
            string.Join(", ", valueList);
    }
}
