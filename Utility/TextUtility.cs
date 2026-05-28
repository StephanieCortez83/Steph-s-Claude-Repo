using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace ACS.Core.Utility
{
    public class TextUtility
    {
        public static Regex LineBreakRegex = new Regex(Common.Regex.Pattern.Extract.TextWithoutLineBreaks);
        public static Regex LineBreaksAndTabsRegex = new Regex(Common.Regex.Pattern.Extract.TextWithoutLineBreaksAndTabs);
        public static Regex LineFeedsRegex = new Regex(Common.Regex.Pattern.Extract.TextWithoutLineFeeds);
        public static Regex MultipleLineBreaksRegex = new Regex(Common.Regex.Pattern.Extract.TextWithoutMultipleLineBreaks);
        public static Regex RedundantTabsRegex = new Regex(Common.Regex.Pattern.Extract.TextWithoutRedundantTabs);
        public static Regex TabRegex = new Regex(Common.Regex.Pattern.Extract.TextWithoutTabs);
        public static Regex TabsAndLineBreaksRegex = new Regex(Common.Regex.Pattern.Extract.TextWithoutTabsAndLineBreaks);
        public static Regex TagsRegex = new Regex(Common.Regex.Pattern.Extract.TextWithoutTags);

        public enum DestinationScrubType
        {
            Filename,
            Javascript,
            Json,
            Sql
        }

        public static string Scrub(DestinationScrubType scrubType, string text)
        {
            switch (scrubType)
            {
                case DestinationScrubType.Filename:
                {
                    text = text.Replace(" ", "_");
                    text = text.Replace("\\", string.Empty);
                    text = text.Replace("/", string.Empty);
                    text = text.Replace("'", string.Empty);
                    text = LineBreakRegex.Replace(text, string.Empty);
                    text = TabRegex.Replace(text, string.Empty);
                    text = LineBreaksAndTabsRegex.Replace(text, string.Empty);
                    text = TabsAndLineBreaksRegex.Replace(text, string.Empty);
                    text = RedundantTabsRegex.Replace(text, string.Empty);
                    text = MultipleLineBreaksRegex.Replace(text, string.Empty);
                    text = MultipleLineBreaksRegex.Replace(text, string.Empty);
                    text = LineFeedsRegex.Replace(text, string.Empty);
                    text = TagsRegex.Replace(text, string.Empty);
                    break;
                }

                case DestinationScrubType.Javascript:
                {
                    text = text.Replace('"', '\"');
                    text = text.Replace("'", "\'");
                    break;
                }

                case DestinationScrubType.Json:
                {
                    text = text.Replace("\n", "\\n");
                    text = text.Replace("\t", "\\t");
                    text = text.Replace("\r", "\\r");
                    break;
                }

                case DestinationScrubType.Sql:
                {
                    text = text.Replace("'", "''");
                    break;
                }
            }

            return text;
        }
    }
}
