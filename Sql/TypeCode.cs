using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Sql
{
    public class TypeCode
    {
        public string Name { get; set; }

        public List<TypeCodeItem> TypeCodeItems { get; set; } = new List<TypeCodeItem>();
    }
}
