using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Common.Attribute
{
    [AttributeUsage(AttributeTargets.Field | AttributeTargets.Property)]
    public class MaskAttribute : System.Attribute
    {
        #region internals

        private int _maskedInt = 0;
        private string _maskedString = string.Empty;

        #endregion internals

        #region constructors

        public MaskAttribute(string mask)
        {
            _maskedString = mask;
        }

        public MaskAttribute(int mask)
        {
            _maskedInt = mask;
        }

        #endregion constructors

        #region methods

        public object GetMask<T>()
        {
            switch (Type.GetTypeCode(typeof(T)))
            {
                case TypeCode.String:
                    return _maskedString;
                case TypeCode.Int64:
                case TypeCode.Int32:
                case TypeCode.Int16:
                    return _maskedInt;
                default:
                    throw new InvalidOperationException($"{nameof(GetMask)} does not support type parameter of type {typeof(T)}.");
            }
        }

        #endregion methods
    }
}
