using ACS.Core.Common.Regex;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace ACS.Core.Extensions
{
	public static class StringExtensions
    {
        static Regex AlphaTextRegex = new Regex(Pattern.Extract.AlphaText);

        /// <summary>
        /// Mask random characters in a string.
        /// </summary>
        /// <param name="value">The value to mask.</param>
        /// <param name="maskCharacter">The character to use for masking. Defaults to an asterisk.</param>
        /// <param name="numberOfCharactersToMask">The number of characters to mask in a string. If not specified it will mask one more than half of the characters.</param>
        /// <returns>A masked string.</returns>
        public static string Mask(this string value, char maskCharacter = '*', int numberOfCharactersToMask = int.MinValue)
        {
            var rnd = new Random();
            var resultBuilder = new StringBuilder();
            var maskCount = numberOfCharactersToMask > int.MinValue ? numberOfCharactersToMask : (int)Math.Ceiling(value.Length / 2.0m);

            var randomIndices = Enumerable.Range(0, value.Length)
                .OrderBy(x => rnd.Next())
                .Take(maskCount)
                .ToList();

            for (var i = 0; i < value.Length; i++)
                resultBuilder.Append(randomIndices.Contains(i) ? maskCharacter : value[i]);

            var result = resultBuilder.ToString();

            return result;
        }

        /// <summary>
        /// Transform a comma-delimited string into a <see cref="List{T}"/> of type <see cref="string"/>
        /// </summary>
        /// <param name="commaDelimitedValue">The comma-delimited string to transform.</param>
        /// <param name="nullOrWhitespaceInputReturnsNull">If set to true, the return value will be null if an empty or null string is input.</param>
        /// <returns>A <see cref="List{T}"/> of type <see cref="string"/> containing the comma-delimited values.</returns>
        public static List<string> SplitCsv(this string commaDelimitedValue, bool nullOrWhitespaceInputReturnsNull = false)
        {
            if (string.IsNullOrWhiteSpace(commaDelimitedValue))
                return nullOrWhitespaceInputReturnsNull ? null : new List<string>();

            return commaDelimitedValue
                .TrimEnd(',')
                .Split(',')
                .AsEnumerable<string>()
                .Select(s => s.Trim())
                .ToList();
        }

        public static string ToCsv(this List<string> valueList) =>
            string.Join(", ", valueList);

        /// <summary>
        /// Convert string values to standardized .Net names for fields/properties.
        /// </summary>
        /// <param name="value">The value to convert.</param>
        /// <returns>A standardized, Pascal-cased value.</returns>
        public static string ToPascalCase(this string value)
        {
            if (string.IsNullOrWhiteSpace(value))
                return string.Empty;

            // some people use this to mark deprecation, so strip it temporarily
            var startsWithX = value.Substring(0, 1).Equals("x"); 
            value = startsWithX ? value.Remove(0, 1) : value;

            // extract the alpha-only characters
            var matches = AlphaTextRegex.Matches(value);
            var alphaText = matches.Cast<object>().Aggregate(string.Empty, (current, m) => current + m.ToString());

            // split along the underscores
            var splitValue = value.Split('_');

            // now see if we have a case where we're mixing casing 
            // styles (i.e. ELMAH_Error) and reassemble
            var upperCaseCount = splitValue.Count(s => s.All(char.IsUpper));
            var mixedCaseCount = splitValue.Length - upperCaseCount;
            var isMixedStyle = upperCaseCount > 0 && mixedCaseCount > 0;

            if (isMixedStyle)
            {
                var newValues = new List<string>();

                foreach (var val in splitValue)
                {
                    var newValue = val;

                    if (val.All(char.IsUpper))
                        newValue = ToPascalCase(newValue);

                    newValues.Add(newValue);
                }

                value = string.Join("_", newValues);
            }

            // if all characters aren't uppercase and there's no underscore(s),
            // assume it's PascalCased and return
            if (!isMixedStyle && !alphaText.All(char.IsUpper)) 
                return startsWithX ? $"x{value}" : value;

            // if it's not PascalCased, assume Oracle/Legacy and look
            // for underscores and split
            splitValue = value.Split('_');
            var newValueParts = new List<string>();

            // now reassemble into PascalCase based on the split
            foreach (var valuePart in splitValue.Where(s => !string.IsNullOrWhiteSpace(s)))
            {
                var cleanValuePart = ScrubIllegalCharacters(valuePart);

                cleanValuePart = cleanValuePart.Trim().Substring(0, 1).ToUpper() +
                                 cleanValuePart.Trim().Substring(1, cleanValuePart.Length - 1).ToLower();

                newValueParts.Add(cleanValuePart);
            }

            var finalValue = string.Join(string.Empty, newValueParts);

            return startsWithX ? $"x{finalValue}" : finalValue;
        }

        /// <summary>
        /// Convert a value to Camel-case.
        /// </summary>
        /// <param name="value">The value to convert to Camel-case.</param>
        /// <returns>A Camel-cased value.</returns>
        public static string ToCamelCase(this string value)
        {
            var cleanValue = ScrubIllegalCharacters(value);

            return cleanValue.Trim().Substring(0, 1).ToLower() + cleanValue.Substring(1);
        }

        /// <summary>
        /// Convert a string to a properly formatted display name string.
        /// </summary>
        /// <param name="value">The string to convert.</param>
        /// <returns>A formatted display string.</returns>
        public static string ToDisplayName(this string value) =>
            new Regex(Pattern.DisplayName, RegexOptions.IgnorePatternWhitespace).Replace(value, " ");

        public static string FromInterfaceName(this string value)
        {
            var name = value.Substring(1, value.Length - 1);

            if (name.Contains("<"))
            {
                var carrotIndex = name.IndexOf("<");
                name = name.Substring(0, carrotIndex);
            }

            return name;
        }

        // <summary>
        /// Remove characters that are illegal for .Net property/field names.
        /// </summary>
        /// <param name="value">The field/property name to scrub.</param>
        /// <returns>A cleaned up field/property name.</returns>
        public static string ScrubIllegalCharacters(string value) =>
            value.Replace(" ", string.Empty)
                .Replace("?", string.Empty)
                .Replace("-", string.Empty)
                .Replace("\\", string.Empty)
                .Replace("/", string.Empty)
                .Replace(",", string.Empty)
                .Replace("[", string.Empty)
                .Replace("]", string.Empty)
                .Replace("#", "Number")
                .Replace("%", "Percent")
                .Replace("$", "Dollars");

		public static bool IsInteger(this string value) =>
	        int.TryParse(value, out _);

	}
}
