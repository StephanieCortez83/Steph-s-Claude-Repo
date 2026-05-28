using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Sql
{
    public class SqlServerView : SqlServerEntity
    {
        public List<SqlServerColumn> Columns { get; set; } = new List<SqlServerColumn>();

        public new SqlServerEntityTypeCode EntityType => SqlServerEntityTypeCode.View;
    }
}
