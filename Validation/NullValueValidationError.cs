using System.ComponentModel.DataAnnotations;

namespace ACS.Core.Validation
{
    public class NullValueValidationError : ValidationErrorBase
    {
        #region constructor

        public NullValueValidationError(ValidationContext validationContext)
        {
            ValidationCategoryType = ValidationCategoryTypeCode.NullValue;
            ValidationDetailType = ValidationDetailTypeCode.NullValueRequired;
            Target = validationContext.ObjectType.Name;
            Property = validationContext.MemberName;
            ErrorMessage = $"Null {validationContext.DisplayName}";
        }

        public NullValueValidationError(string area, string propertyName)
        {
            ValidationCategoryType = ValidationCategoryTypeCode.NullValue;
            ValidationDetailType = ValidationDetailTypeCode.NullValueRequired;
            Target = area;
            Property = propertyName;
            ErrorMessage = $"Null {propertyName}";
        }

        #endregion constructor
    }
}
