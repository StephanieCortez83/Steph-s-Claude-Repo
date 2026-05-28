using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ACS.Core.SqlServer;

namespace ACS.Core.Sql
{
    public class SqlServerStoredProcedure : SqlServerEntity
    {
        public bool IsStartupSproc { get; set; }

        public new SqlServerEntityTypeCode EntityType => SqlServerEntityTypeCode.StoredProcedure;
    }
}
