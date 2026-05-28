using System.Collections.Generic;
using ACS.Core.SqlServer;

namespace ACS.Core.Sql
{
    public interface ISqlServerEntity
    {
        int Id { get; set; }

        string Name { get; set; }

        string FormattedName { get; set; }

        string SchemaOwner { get; set; }

        List<SqlServerExtendedProperty> ExtendedProperties { get; set; }

        SqlServerEntityTypeCode EntityType { get; set; }

        string ToString();
    }

    public class SqlServerEntity : ISqlServerEntity
    {
        public int Id { get; set; }

        public string Name { get; set; }

        public string FormattedName { get; set; }

        public string SchemaOwner { get; set; }

        public List<SqlServerExtendedProperty> ExtendedProperties { get; set; } = new List<SqlServerExtendedProperty>();

        public SqlServerEntityTypeCode EntityType { get; set; }
        
        public override string ToString()
        {
            return this.SchemaOwner + "." + this.Name;
        }
    }
}
