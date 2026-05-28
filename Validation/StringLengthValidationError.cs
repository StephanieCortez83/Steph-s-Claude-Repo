using System.ComponentModel.DataAnnotations;

namespace ACS.Core.Validation
{
    public class StringLengthValidationError : ValidationErrorBase
    {
        #region constructor

        public StringLengthValidationError(int minimumLength, int maximumLength, ValidationContext validationContext)
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BadArgument;
            ValidationDetailType = ValidationDetailTypeCode.MinLength;
            Target = validationContext.ObjectType.Name;
            Property = validationContext.MemberName;

            if (minimumLength > 0 && maximumLength > 0)
            {
                ErrorMessage = $"{validationContext.DisplayName} must be between {minimumLength} and {maximumLength} characters.";
            }
            else if (minimumLength > 0 && maximumLength <= 0)
            {
                ErrorMessage = $"{validationContext.DisplayName} must be at least {maximumLength} characters.";

            }
            else ErrorMessage = $"{validationContext.DisplayName} cannot be longer than {maximumLength} characters.";
        }

        #endregion constructor
    }
}
