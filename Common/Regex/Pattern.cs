namespace ACS.Core.Common.Regex
{
    public struct Pattern
    {
        public struct Api
        {
            public static string Filter = "^[a-zA-Z0-9]+:\\[[a-zA-Z0-9]+\\][a-zA-Z0-9]";

            public static string Sort = "^((\\+|\\-))[a-zA-Z0-9]";
        }

        public static string DisplayName = "(?<=[A-Z])(?=[A-Z][a-z]) | (?<=[^A-Z])(?=[A-Z]) | (?<=[A-Za-z])(?=[^A-Za-z])";

        public static string EmailAddress = "^([a-zA-Z0-9_\\-\\.]+)@((\\[[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\\]?)$";

        public struct Extract
        {
            public static string AlphanumericText = "[a-zA-Z0-9]+";

            public static string AlphaText = "[A-Za-z]+";

            public static string TextBetweenBrackets = "(?<=\\[).+?(?=\\])";

            public static string TextOutsideOfBrackets = "([^[\\]]+)(?:$|\\[)";

            public static string TextWithoutLineBreaks = "(\r)( )+(\r)";

            public static string TextWithoutLineBreaksAndTabs = "(\r)( )+(\t)";

            public static string TextWithoutLineFeeds = "[\\r\\n]+";

            public static string TextWithoutMultipleLineBreaks = "(\r)(\t)+";

            public static string TextWithoutTabs = "(\t)( )+(\t)";

            public static string TextWithoutTabsAndLineBreaks = "(\t)( )+(\r)";

            public static string TextWithoutRedundantTabs = "(\r)(\t)+(\r)";

            public static string TextWithoutTags = "<[^>]*>";
        }

        public static string Password = "(?=^.{8,15}$)((?=.*\\d)(?=.*[A-Z])(?=.*[a-z])|(?=.*\\d)(?=.*[^A-Za-z0-9])(?=.*[a-z])|(?=.*[^A-Za-z0-9])(?=.*[A-Z])(?=.*[a-z])|(?=.*\\d)(?=.*[A-Z])(?=.*[^A-Za-z0-9]))^.*";

        public static string PhoneNumber = "^\\D?(\\d{3})\\D?\\D?(\\d{3})\\D?(\\d{4})$";

        public static string RepeatingCharacters = "^((.)(?!\\2{1,}))+$";

        public static string SignOnIdPattern = @"^[a-zA-Z0-9_-]+$";

        public static string ThreeOrMoreRepeatingCharacters = @"(.)\1\1+";

        public static string Url = "^((http|https|ftp)\\://)?[a-zA-Z0-9\\-\\.]+\\.[a-zA-Z]{2,3}(:[a-zA-Z0-9]*)?/?([a-zA-Z0-9\\-\\,\\._\\?\\,'/\\\\+&amp;%\\$#\\=~])*$";

       
    }
}
