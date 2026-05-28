using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Template
{
    public enum DotNetDataTypeCode
    {
        [Display(ShortName = "int")]
        Int = 1,
        [Display(ShortName = "Int16")]
        Int16 = 2,
        [Display(ShortName = "Int32")]
        Int32 = 3,
        [Display(ShortName = "Int64")]
        Int64 = 4,
        [Display(ShortName = "byte")]
        Byte = 5,
        [Display(ShortName = "byte[]")]
        ByteArray = 6,
        [Display(ShortName = "bool")]
        Boolean = 7,
        [Display(ShortName = "char")]
        Char = 8,
        [Display(ShortName = "DateTime")]
        DateTime = 9,
        [Display(ShortName = "decimal")]
        Decimal = 10,
        [Display(ShortName = "double")]
        Double = 11,
        [Display(ShortName = "string")]
        String = 12,
        [Display(ShortName = "single")]
        Single = 13,
        [Display(ShortName = "Guid")]
        Guid = 14
    }
}
