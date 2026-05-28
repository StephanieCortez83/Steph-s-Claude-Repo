using System.ComponentModel.DataAnnotations;

namespace ACS.Core.Validation
{
    public class UniqueValidationError : ValidationErrorBase
    {
        #region constructor

        public UniqueValidationError(ValidationContext validationContext)
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BadArgument;
            ValidationDetailType = ValidationDetailTypeCode.Unique;
            Target = validationContext.ObjectType.Name;
            Property = validationContext.MemberName;
            ErrorMessage = $"{validationContext.DisplayName} must be unique.";
        }

        public UniqueValidationError(string objectTypeName, string propertyName, string propertyDisplayName, string errorMessage = "")
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BadArgument;
            ValidationDetailType = ValidationDetailTypeCode.Unique;
            Target = objectTypeName;
            Property = propertyName;
            ErrorMessage = string.IsNullOrWhiteSpace(errorMessage) ? $"{propertyDisplayName} must be unique" : errorMessage;
        }

        #endregion constructor
    }
}
