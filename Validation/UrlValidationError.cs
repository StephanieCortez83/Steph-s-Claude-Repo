using System.ComponentModel.DataAnnotations;

namespace ACS.Core.Validation
{
    public class UrlValidationError : ValidationErrorBase
    {
        #region constructor

        public UrlValidationError(ValidationContext validationContext)
        {
            ValidationCategoryType = ValidationCategoryTypeCode.BadArgument;
            ValidationDetailType = ValidationDetailTypeCode.InvalidValue;
            Target = validationContext.ObjectType.Name;
            Property = validationContext.MemberName;
            ErrorMessage = $"{validationContext.DisplayName} is not a valid url.";
        }

        #endregion coinstructor
    }
}
