using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Sql
{
    public class SqlServerIndex
    {
        public string IndexName { get; set; }

        public int IndexId { get; set; }

        public string SqlServerEntityName { get; set; }

        public int SqlServerEntityId { get; set; }

        public List<SqlServerColumn> MemberColumns { get; set; }

        public List<SqlServerColumn> IncludedColumns { get; set; }

        public SqlServerSysIndexTypeCode IndexType { get; set; }

        public bool IsUnique { get; set; }

        public bool IsDescendingKey { get; set; }

        public byte ColumnOrdinal { get; set; }

        public bool IsPrimaryKey { get; set; }

        public bool IsIncludeColumn { get; set; }

        public string MemberColumnIdentifier { get; set; }

        public override string ToString()
        {
            return $"[{this.SqlServerEntityName}].[{this.IndexName}]";
        }
    }
}
