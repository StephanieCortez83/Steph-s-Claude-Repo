using System.ComponentModel.DataAnnotations;

namespace ACS.Core.Validation
{
    public class RequiredValidationError : ValidationErrorBase
    {
        #region constructor

        public RequiredValidationError(ValidationContext validationContext)
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BadArgument;
            ValidationDetailType = ValidationDetailTypeCode.Required;
            Target = validationContext.ObjectType.Name;
            Property = validationContext.MemberName;
            ErrorMessage = $"{validationContext.DisplayName} is required.";
        }

        public RequiredValidationError(string area, string propertyName, string errorMessage = "")
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BadArgument;
            ValidationDetailType = ValidationDetailTypeCode.Required;
            Target = area;
            Property = propertyName;
            ErrorMessage = string.IsNullOrWhiteSpace(errorMessage) ? $"{propertyName} is required" : errorMessage;
        }

        #endregion constructor
    }
}
