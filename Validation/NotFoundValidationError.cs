using System.ComponentModel.DataAnnotations;

namespace ACS.Core.Validation
{
    public class NotFoundValidationError : ValidationErrorBase
    {
        #region constructor

        public NotFoundValidationError(ValidationContext validationContext)
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BadArgument;
            ValidationDetailType = ValidationDetailTypeCode.NotFound;
            Target = validationContext.ObjectType.Name;
            Property = validationContext.MemberName;
            ErrorMessage = $"Invalid {validationContext.DisplayName}";
        }

        public NotFoundValidationError(string area, string propertyName, string errorMessage = "")
        {
            Target = area;
            Property = propertyName;
            ErrorMessage = string.IsNullOrWhiteSpace(errorMessage) ? $"{propertyName} not found" : errorMessage;
            ValidationCategoryType = ValidationCategoryTypeCode.BadArgument;
            ValidationDetailType = ValidationDetailTypeCode.NotFound;
        }

        #endregion constructor
    }
}
