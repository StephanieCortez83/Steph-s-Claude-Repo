using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Sql
{
    public class SqlServerTable : SqlServerEntity
    {
        public List<SqlServerColumn> Columns { get; set; } = new List<SqlServerColumn>();

        public List<SqlServerIndex> Indexes { get; set; } = new List<SqlServerIndex>();

        public List<SqlServerForeignKey> ForeignKeys { get; set; } = new List<SqlServerForeignKey>();

        public new SqlServerEntityTypeCode EntityType => SqlServerEntityTypeCode.Table;
    }
}
