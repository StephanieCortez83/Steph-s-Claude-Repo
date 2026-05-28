using System.ComponentModel.DataAnnotations;

namespace ACS.Core.Validation
{
    public class MinLengthValidationError : ValidationErrorBase
    {
        #region constructor

        public MinLengthValidationError(int minLength, ValidationContext validationContext)
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BadArgument;
            ValidationDetailType = ValidationDetailTypeCode.MinLength;
            Target = validationContext.ObjectType.Name;
            Property = validationContext.MemberName;
            ErrorMessage = $"{validationContext.DisplayName} must be at least {minLength} characters.";
        }

        #endregion constructor
    }
}
