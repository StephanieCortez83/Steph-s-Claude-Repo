using System.Collections.Generic;
using ACS.Core.SqlServer;

namespace ACS.Core.Sql
{
    public class SqlServerColumn
    {
        #region properties

        public int SqlServerEntityId { get; set; }

        public string SqlServerEntityName { get; set; }

        public int ColumnId { get; set; }

        public string Name { get; set; }

        public string FormattedName { get; set; }

        public string DataTypeName { get; set; }

        public SqlServerDataTypeCode DataType { get; set; }

        public short MaxLength { get; set; }

        public byte Precision { get; set; }

        public byte Scale { get; set; }

        public bool IsNullable { get; set; }

        public bool IsPrimaryKey { get; set; }

        public bool IsForeignKey { get; set; }

        public virtual bool IsIdentity { get; set; }

        public bool IsComputed { get; set; }

        public List<SqlServerExtendedProperty> ExtendedProperties { get; set; } = new List<SqlServerExtendedProperty>();

        #endregion
    }
}
