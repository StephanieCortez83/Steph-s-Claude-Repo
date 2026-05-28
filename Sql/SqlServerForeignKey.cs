using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Sql
{
    public class SqlServerForeignKey
    {
        public int ForeignKeyId { get; set; }

        public string Name { get; set; }
        
        public int ForeignKeyEntityId { get; set; }

        public string ForeignKeyEntityName { get; set; }

        public int PrimaryKeyEntityId { get; set; }

        public string PrimaryKeyEntityName { get; set; }

        public List<SqlServerForeignKeyRelationship> Relationships { get; set; }
    }

    public class SqlServerForeignKeyRelationship
    {
        public SqlServerColumn ForeignKeyColumn { get; set; }

        public SqlServerColumn PrimaryKeyColumn { get; set; }
    }
}
