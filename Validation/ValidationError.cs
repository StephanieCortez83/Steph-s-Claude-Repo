using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Validation
{
    public class ValidationError : ValidationErrorBase
    {
        #region constructors

        public ValidationError()
        {
        }

        public ValidationError(ValidationCategoryTypeCode validationCategoryType, ValidationDetailTypeCode validationType, string area, string property, string errorMessage)
        {
            this.ValidationCategoryType = validationCategoryType;
            this.ValidationDetailType = validationType;
            this.Target = area;
            this.Property = property;
            this.ErrorMessage = errorMessage;
        }

        #endregion
    }
}
