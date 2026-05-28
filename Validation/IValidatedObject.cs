using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Validation
{
    public interface IValidatedObject
    {
        /// <summary>
        /// This will call validation on an object and indicate if the object has a valid state.
        /// </summary>
        bool IsValid { get; }
    }
}
