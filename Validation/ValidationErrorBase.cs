namespace ACS.Core.Validation
{
    public class ValidationErrorBase : IValidationError
    {
        #region properties

        public ValidationCategoryTypeCode ValidationCategoryType { get; set; }

        public ValidationDetailTypeCode ValidationDetailType { get; set; }

        public string Target { get; set; }

        public string Property { get; set; }

        public string ErrorMessage { get; set; }

        #endregion properties
    }
}
