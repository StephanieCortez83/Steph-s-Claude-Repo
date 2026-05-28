using System.ComponentModel.DataAnnotations;

namespace ACS.Core.Validation
{
    public class LimitExceededValidationError : ValidationErrorBase
    {
        #region constructor

        public LimitExceededValidationError(ValidationContext validationContext)
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BadArgument;
            ValidationDetailType = ValidationDetailTypeCode.LimitExceeded;
            Target = validationContext.ObjectType.Name;
            Property = validationContext.MemberName;
            ErrorMessage = $"Limit exceeded for {validationContext.DisplayName}";
        }

        public LimitExceededValidationError(string area, string propertyName, string errorMessage = "")
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BusinessRule;
            ValidationDetailType = ValidationDetailTypeCode.LimitExceeded;
            Target = area;
            Property = propertyName;
            ErrorMessage = string.IsNullOrWhiteSpace(errorMessage) ? $"Limit exceeded for {propertyName}" : errorMessage;
        }

        #endregion constructor
    }
}
