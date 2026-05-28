using System.ComponentModel.DataAnnotations;

namespace ACS.Core.Validation
{
    public class DateOutOfRangeValidationError : ValidationErrorBase
    {
        #region constructor

        public DateOutOfRangeValidationError(ValidationContext validationContext)
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BusinessRule;
            ValidationDetailType = ValidationDetailTypeCode.DateOutOfRange;
            Target = validationContext.ObjectType.Name;
            Property = validationContext.MemberName;
            ErrorMessage = $"{validationContext.DisplayName} is out of range.";
        }

        public DateOutOfRangeValidationError(string area, string propertyName, string errorMessage = "")
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BusinessRule;
            ValidationDetailType = ValidationDetailTypeCode.DateOutOfRange;
            Target = area;
            Property = propertyName;
            ErrorMessage = string.IsNullOrWhiteSpace(errorMessage) ? $"Invalid {propertyName}" : errorMessage;
        }

        #endregion constructor
    }
}
