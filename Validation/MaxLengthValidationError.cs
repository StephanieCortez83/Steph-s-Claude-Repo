using System.ComponentModel.DataAnnotations;

namespace ACS.Core.Validation
{
    public class MaxLengthValidationError : ValidationErrorBase
    {
        #region constructor

        public MaxLengthValidationError(int maxLength, ValidationContext validationContext)
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BadArgument;
            ValidationDetailType = ValidationDetailTypeCode.MaxLength;
            Target = validationContext.ObjectType.Name;
            Property = validationContext.MemberName;
            ErrorMessage = $"{validationContext.DisplayName} cannot be longer than {maxLength} characters.";
        }

        #endregion constructor
    }
}
