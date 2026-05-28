using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Validation
{
    public static class DataAnnotationsValidator
    {
        public static bool TryValidateValue(object value, ValidationContext validationContext, IEnumerable<ValidationAttribute> validationAttributes, out ICollection<IValidationError> validationErrors)
        {
            validationErrors = new List<IValidationError>();

            foreach (var validationAttribute in validationAttributes)
            {
                switch (validationAttribute)
                {
                    case EmailAddressAttribute emailAddressAttribute:
                    {
                        var success = Validator.TryValidateValue(value, validationContext, new List<ValidationResult>(), new List<ValidationAttribute>() { emailAddressAttribute });

                        if (!success)
                            validationErrors.Add(new EmailAddressValidationError(validationContext));

                        break;
                    }
                    case MaxLengthAttribute maxLengthAttribute:
                    {
                        var success = Validator.TryValidateValue(value, validationContext, new List<ValidationResult>(), new List<ValidationAttribute>() { maxLengthAttribute });

                        if (!success)
                            validationErrors.Add(new MaxLengthValidationError(maxLengthAttribute.Length, validationContext));

                        break;
                    }
                    case MinLengthAttribute maxLengthAttribute:
                    {
                        var success = Validator.TryValidateValue(value, validationContext, new List<ValidationResult>(), new List<ValidationAttribute>() { maxLengthAttribute });

                        if (!success)
                            validationErrors.Add(new MinLengthValidationError(maxLengthAttribute.Length, validationContext));

                        break;
                    }
                    case PhoneAttribute phoneAttribute:
                    {
                        var success = Validator.TryValidateValue(value, validationContext, new List<ValidationResult>(), new List<ValidationAttribute>() { phoneAttribute });

                        if (!success)
                            validationErrors.Add(new PhoneNumberValidationError(validationContext));

                        break;
                    }
                    case RequiredAttribute requiredAttribute:
                    {
                        var success = Validator.TryValidateValue(value, validationContext, new List<ValidationResult>(), new List<ValidationAttribute>() { requiredAttribute });

                        if (!success)
                            validationErrors.Add(new RequiredValidationError(validationContext));

                        break;
                    }
                    case StringLengthAttribute stringLengthAttribute:
                    {
                        var success = Validator.TryValidateValue(value, validationContext, new List<ValidationResult>(), new List<ValidationAttribute>() { stringLengthAttribute });

                        if (!success)
                            validationErrors.Add(new StringLengthValidationError(stringLengthAttribute.MinimumLength, stringLengthAttribute.MaximumLength, validationContext));

                        break;
                    }
                }
            }

            return !validationErrors.Any();
        }
    }
}
