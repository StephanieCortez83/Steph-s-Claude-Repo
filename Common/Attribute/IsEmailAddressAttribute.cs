using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Common.Attribute
{
    public class IsEmailAddressAttribute : DataTypeAttribute
    {
        public bool AllowEmpty { get; set; }

        public IsEmailAddressAttribute(bool allowEmpty = false) : base(DataType.EmailAddress)
        {
            AllowEmpty = allowEmpty;
        }

        public override bool IsValid(object value)
        {
            if (value == null)
                return true;

            var input = value as string;
            var emailAddressAttribute = new EmailAddressAttribute();

            return (input != null) && (string.IsNullOrWhiteSpace(input) || emailAddressAttribute.IsValid(input));
        }
    }
}
