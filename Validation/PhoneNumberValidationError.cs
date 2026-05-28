using System.ComponentModel.DataAnnotations;

namespace ACS.Core.Validation
{
    public class PhoneNumberValidationError : ValidationErrorBase
    {
        #region cosntructor

        public PhoneNumberValidationError(ValidationContext validationContext)
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BadArgument;
            ValidationDetailType = ValidationDetailTypeCode.InvalidValue;
            Target = validationContext.ObjectType.Name;
            Property = validationContext.MemberName;
            ErrorMessage = $"{validationContext.DisplayName} is not a valid phone number.";
        }

        #endregion constructor
    }
}
