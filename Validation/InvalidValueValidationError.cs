using System.ComponentModel.DataAnnotations;

namespace ACS.Core.Validation
{
    public class InvalidValueValidationError : ValidationErrorBase
    {
        #region constructor

        public InvalidValueValidationError(ValidationContext validationContext)
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BadArgument;
            ValidationDetailType = ValidationDetailTypeCode.InvalidValue;
            Target = validationContext.ObjectType.Name;
            Property = validationContext.MemberName;
            ErrorMessage = $"Invalid {validationContext.DisplayName}";
        }

        public InvalidValueValidationError(string area, string propertyName, string errorMessage = "")
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BadArgument;
            ValidationDetailType = ValidationDetailTypeCode.InvalidValue;
            Target = area;
            Property = propertyName;
            ErrorMessage = string.IsNullOrWhiteSpace(errorMessage) ? $"Invalid {propertyName}" : errorMessage;
        }

        #endregion constructor
    }
}
