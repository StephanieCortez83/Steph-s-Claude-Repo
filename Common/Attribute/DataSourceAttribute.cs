using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Common.Attribute
{
    [AttributeUsage(AttributeTargets.All, AllowMultiple = false)]
    public class DataSourceAttribute : System.Attribute
    {
        public string FieldName { get; set; }

        public string Source { get; set; }

        public bool IsPrimaryKey { get; set; }

        public bool IsForeignKey { get; set; }
    }
}
