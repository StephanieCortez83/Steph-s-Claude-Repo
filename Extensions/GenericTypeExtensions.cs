using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Extensions
{
    public static class GenericTypeExtensions
    {
        public static bool In<T>(this T val, params T[] values) where T : struct =>
            values.Contains(val);

    }
}
