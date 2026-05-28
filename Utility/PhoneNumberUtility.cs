using System;
using PhoneNumbers;

namespace ACS.Core.Utility
{
    public class PhoneNumber
    {
        public string AreaCode { get; set; }

        public string Number { get; set; }

        public string Extension { get; set; }
    }

    public interface IPhoneNumberUtility
    {
        bool Validate(string value);

        bool TryParse(string value, out PhoneNumber phoneNumber);

        bool TryParseAndFormat(string areaCode, string number, string extension, out string formattedPhoneNumber);

        bool TryParseAndFormat(string value, out string formattedPhoneNumber);
    }

    public class PhoneNumberUtility : IPhoneNumberUtility
    {
        #region internals

        private readonly PhoneNumberUtil _phoneNumberUtil = PhoneNumberUtil.GetInstance();

        #endregion

        public PhoneNumberUtility()
        {

        }

        public bool Validate(string value)
        {
            try
            {
                var phoneNumber = _phoneNumberUtil.Parse(value, "US");

                return _phoneNumberUtil.IsValidNumber(phoneNumber);
            }
            catch (NumberParseException e)
            {
                return false;
            }
        }

        public bool TryParse(string value, out PhoneNumber phoneNumber)
        {
            phoneNumber = new PhoneNumber();
            
            if (!TryParseInternal(value, out var phoneNumberUtilNumber))
                return false;

            var phoneNumberString = phoneNumberUtilNumber.NationalNumber.ToString();

            phoneNumber.AreaCode = phoneNumberString.Substring(0, 3);
            phoneNumber.Number = $"{phoneNumberString.Substring(3, 3)}{phoneNumberString.Substring(6, 4)}";
            phoneNumber.Extension = phoneNumberUtilNumber.Extension;

            return true;
        }

        private bool TryParseInternal(string value, out PhoneNumbers.PhoneNumber phoneNumber)
        {
            phoneNumber = null;

            try
            {
                phoneNumber = _phoneNumberUtil.Parse(value, "US");

                return _phoneNumberUtil.IsValidNumber(phoneNumber);
            }
            catch (NumberParseException)
            {
                return false;
            }
        }

        public bool TryParseAndFormat(string areaCode, string number, string extension, out string formattedPhoneNumber)
        {
            return TryParseAndFormat($"{areaCode}{number}x{extension}", out formattedPhoneNumber);
        }

        public bool TryParseAndFormat(string value, out string formattedPhoneNumber)
        {
            formattedPhoneNumber = string.Empty;

            var success = this.TryParseInternal(value, out var phoneNumber);

            if (!success)
                return false;

            formattedPhoneNumber = _phoneNumberUtil.Format(phoneNumber, PhoneNumberFormat.NATIONAL);

            return true;
        }
    }
}
    