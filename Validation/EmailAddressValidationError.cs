using System.ComponentModel.DataAnnotations;

namespace ACS.Core.Validation
{
    public class EmailAddressValidationError : ValidationErrorBase
    {
        #region constructor

        public EmailAddressValidationError(ValidationContext validationContext)
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BadArgument;
            ValidationDetailType = ValidationDetailTypeCode.InvalidValue;
            Target = validationContext.ObjectType.Name;
            Property = validationContext.MemberName;
            ErrorMessage = $"{validationContext.DisplayName} is not a valid email address.";
        }

        #endregion constructor
    }
}
