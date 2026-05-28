namespace ACS.Core.Validation
{
    public interface IValidationError
    {
        ValidationCategoryTypeCode ValidationCategoryType { get; set; }

        ValidationDetailTypeCode ValidationDetailType { get; set; }

        string Target { get; set; }

        string Property { get; set; }

        string ErrorMessage { get; set; }
    }
}