using System.ComponentModel.DataAnnotations;
using ACS.Core.Extensions;

namespace ACS.Core.Validation
{
    public class UniqueValueValidationError : ValidationErrorBase
    {
        #region constructor

        public UniqueValueValidationError(ValidationContext validationContext)
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BusinessRule;
            ValidationDetailType = ValidationDetailTypeCode.Unique;
            Target = validationContext.ObjectType.Name;
            Property = validationContext.MemberName;
            ErrorMessage = $"Invalid {validationContext.DisplayName}";
        }
        
        public UniqueValueValidationError(string area, string propertyName, string errorMessage = "")
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BusinessRule;
            ValidationDetailType = ValidationDetailTypeCode.Unique;
            Target = area;
            Property = propertyName;
            ErrorMessage = string.IsNullOrWhiteSpace(errorMessage) ? string.Format(ValidationDetailTypeCode.Unique.GetDisplayDescription(), propertyName) : errorMessage;
        }

        #endregion constructor
    }
}
