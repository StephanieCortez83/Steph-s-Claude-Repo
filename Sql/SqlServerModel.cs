using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text.RegularExpressions;
using ACS.Core.Common.Regex;
using ACS.Core.Extensions;
using ACS.Core.Sql;
using TypeCode = ACS.Core.Sql.TypeCode;

namespace ACS.Core.SqlServer
{
    public class SqlServerModel
    {
        #region internals

        private Regex AlphaTextRegex = new Regex(Pattern.Extract.AlphaText);

        #endregion internals

        #region properties

        /// <summary>
        /// A connection string that indicates which
        /// database to model.
        /// </summary>
        public string ConnectionString { get; set; }

        /// <summary>
        /// A schema prefix to ignore when generating
        /// class and property names
        /// </summary>
        public string IgnorePrefix { get; set; }

        /// <summary>
        /// Indicates whether or not to model tables.
        /// </summary>
        public bool ModelTables { get; set; } = true;

        /// <summary>
        /// Indicates whether or not to model views.
        /// </summary>
        public bool ModelViews { get; set; } = true;

        /// <summary>
        /// Indicates whether or not to model stored procedures.
        /// </summary>
        public bool ModelStoredProcedures { get; set; } = true;

        /// <summary>
        /// Indicates whether or not to model enums.
        /// </summary>
        public bool ModelTypeCodes { get; set; } = true;

        /// <summary>
        /// If this list has any values, it will scope the modeling to
        /// just those table names present in this list.
        /// </summary>
        public List<string> ScopedTableNameList { get; set; }

        /// <summary>
        /// If this list has any values, it will scope the modeling to
        /// just those type code table names present in this list.
        /// </summary>
        public List<string> ScopedTypeCodeTableNameList { get; set; }

        /// <summary>
        /// If this list has any values, it will scope the modeling to
        /// just those view names present in this list.
        /// </summary>
        public List<string> ScopedViewNameList { get; set; }

        /// <summary>
        /// After modeling is complete this will contain a list of
        /// SqlServerTable representing the database tables.
        /// </summary>
        public List<SqlServerTable> Tables { get; private set; } = new List<SqlServerTable>();

        /// <summary>
        /// After modeling is complete this will contain a list of
        /// SqlServerView representing the database views.
        /// </summary>
        public List<SqlServerView> Views { get; private set; } = new List<SqlServerView>();

        /// <summary>
        /// After modeling is complete this will contain a list of
        /// SqlServerStoredProcedures representing the database stored procedures.
        /// </summary>
        public List<SqlServerStoredProcedure> StoredProcedures { get; private set; } = new List<SqlServerStoredProcedure>();

        public List<TypeCode> TypeCodes { get; private set; } = new List<TypeCode>();

        #endregion properties

        #region constructors

        public SqlServerModel()
        {

        }

        public SqlServerModel(string connectionString)
        {
            this.ConnectionString = connectionString;
        }

        #endregion constructors

        #region generate

        public void GenerateModel()
        {
            if (string.IsNullOrWhiteSpace(ConnectionString))
                throw new ArgumentException("ConnectionString is required");

            if (this.ModelTables)
                this.Tables = BuildTables();

            if (this.ModelViews)
                this.Views = BuildViews();

            if (this.ModelStoredProcedures)
                this.StoredProcedures = BuildStoredProcedures();

            if (this.ModelTypeCodes)
                this.TypeCodes = BuildTypeCodes();
        }

        #endregion generate
        
        #region tables

        /// <summary>
        /// Get a list of tables from sys.objects.
        /// </summary>
        /// <returns>A list of tables found.</returns>
        private List<SqlServerTable> BuildTables()
        {
            // get the list of tables
             var tableList = GetEntities<SqlServerTable>(SqlServerEntityTypeCode.Table);

            //------------------------------------------------------
            // table extended properties
            //------------------------------------------------------
            var tableIdList = tableList.Select(t => t.Id).ToList();
            var extendedPropertyList = GetExtendedProperties(SqlServerExtendedPropertyTypeCode.Table, tableIdList);

            // attach each extended property to its respective table
            foreach (var extendedProperty in extendedPropertyList)
            {
                var table = tableList.FirstOrDefault(t => t.Id == extendedProperty.MajorId);
                table?.ExtendedProperties.Add(extendedProperty);
            }

            //------------------------------------------------------
            // columns
            //------------------------------------------------------
            var columnList = GetColumns(SqlServerEntityTypeCode.Table, tableIdList);

            // attach columns to their respective table objects
            if (columnList.Any())
            {
                foreach (var column in columnList)
                {
                    var table = tableList.FirstOrDefault(t => t.Id == column.SqlServerEntityId);
                    table?.Columns.Add(column);
                }

                // get the extended properties for each column
                extendedPropertyList = GetExtendedProperties(SqlServerExtendedPropertyTypeCode.Column, tableIdList);

                // attach each column extended property to its column
                foreach (var extendedProperty in extendedPropertyList)
                {
                    var column = columnList.FirstOrDefault(c => c.SqlServerEntityId == extendedProperty.MajorId && c.ColumnId == extendedProperty.MinorId);

                    column?.ExtendedProperties.Add(extendedProperty);
                }
            }

            //------------------------------------------------------
            // table indexes
            //------------------------------------------------------
            var indexList = GetIndexes(tableList);

            // attach indexes to their respective table objects
            if (indexList.Any())
            {
                foreach (var index in indexList)
                {
                    var table = tableList.FirstOrDefault(t => t.Id == index.SqlServerEntityId);

                    if (table != null)
                    {
                        table.Indexes.Add(index);

                        // if the index is a primary key, try to find the corresponding column in its
                        // parent table
                        if (index.IsPrimaryKey)
                        {
                            foreach (var memberColumn in index.MemberColumns)
                            {
                                var column = table.Columns.FirstOrDefault(c => c.ColumnId == memberColumn.ColumnId);

                                if (column != null)
                                    column.IsPrimaryKey = true;
                            }
                        }
                    }
                }
            }

            //------------------------------------------------------
            // foreign keys
            //------------------------------------------------------
            var foreignKeyList = GetForeignKeys(tableList);

            // attach foreign keys to their respective table objects
            if (foreignKeyList.Any())
            {
                foreach (var foreignKey in foreignKeyList)
                {
                    var table = tableList.FirstOrDefault(t => t.Id == foreignKey.ForeignKeyEntityId);

                    table?.ForeignKeys.Add(foreignKey);
                }
            }

            return tableList;
        }

        #endregion tables

        #region views

        /// <summary>
        /// Get a list of views from sys.objects.
        /// </summary>
        /// <returns>A list of tables found.</returns>
        private List<SqlServerView> BuildViews()
        {
            var viewList = GetEntities<SqlServerView>(SqlServerEntityTypeCode.View);

            //------------------------------------------------------
            // view extended properties
            //------------------------------------------------------
            var viewIdList = viewList.Select(t => t.Id).ToList();
            var extendedPropertyList = GetExtendedProperties(SqlServerExtendedPropertyTypeCode.View, viewIdList);

            // attach each extended property to its respective table
            foreach (var extendedProperty in extendedPropertyList)
            {
                var view = viewList.FirstOrDefault(t => t.Id == extendedProperty.MajorId);
                view?.ExtendedProperties.Add(extendedProperty);
            }

            //------------------------------------------------------
            // columns
            //------------------------------------------------------
            var columnList = GetColumns(SqlServerEntityTypeCode.View, viewIdList);

            // attach columns to their respective view objects
            if (columnList.Any())
            {
                foreach (var column in columnList)
                {
                    var view = viewList.FirstOrDefault(t => t.Id == column.SqlServerEntityId);
                    view?.Columns.Add(column);
                }

                // get the extended properties for each column
                extendedPropertyList = GetExtendedProperties(SqlServerExtendedPropertyTypeCode.Column, viewIdList);

                // attach each column extended property to its column
                foreach (var extendedProperty in extendedPropertyList)
                {
                    var column = columnList.FirstOrDefault(c => c.SqlServerEntityId == extendedProperty.MajorId && c.ColumnId == extendedProperty.MinorId);

                    column?.ExtendedProperties.Add(extendedProperty);
                }
            }

            return viewList;
        }

        #endregion

        #region entities

        /// <summary>
        /// Get a list of entities (tables or views) from the database
        /// </summary>
        /// <returns>A list of SqlServerEntity that represents the tables or views in the database.</returns>
        private List<T> GetEntities<T>(SqlServerEntityTypeCode sqlServerEntityType) where T : ISqlServerEntity, new()
        {
            var sqlService = new SqlService();
            sqlService.ConnectionString = this.ConnectionString;
            sqlService.AutoCloseConnection = true;

            try
            {
                var entityList = new List<T>();
                var whereClause = string.Empty;

                switch (sqlServerEntityType)
                {
                    case SqlServerEntityTypeCode.Table:
                    {
                        whereClause = "sys.objects.type = 'U'";

                        // limit the to model to particular tables, if any
                        if (ScopedTableNameList != null && ScopedTableNameList.Any())
                        {
                            var formattedTableNameList = new List<string>();

                            foreach (var tableName in ScopedTableNameList)
                                formattedTableNameList.Add($"'{tableName}'");

                            whereClause += $" AND sys.objects.name IN ({string.Join(",", formattedTableNameList)}) ";
                        }

                        break;
                    }
                    case SqlServerEntityTypeCode.TypeCode:
                    {
                        whereClause = "sys.objects.type = 'U'";

                        // limit the to model to particular tables, if any
                        if (ScopedTypeCodeTableNameList != null && ScopedTypeCodeTableNameList.Any())
                        {
                            var formattedTableNameList = new List<string>();

                            foreach (var tableName in ScopedTypeCodeTableNameList)
                                formattedTableNameList.Add($"'{tableName}'");

                            whereClause += $" AND sys.objects.name IN ({string.Join(",", formattedTableNameList)}) ";
                        }

                        whereClause += "AND (sys.objects.name LIKE '%_TYPE_CODE' OR sys.objects.name LIKE '%TypeCode') ";

                        break;
                    }
                    case SqlServerEntityTypeCode.View:
                    {
                        whereClause = "sys.objects.type = 'V'";

                        // limit the to model to particular views, if any
                        if (ScopedViewNameList != null && ScopedViewNameList.Any())
                        {
                            var formattedViewNameList = new List<string>();

                            foreach (var viewName in ScopedViewNameList)
                                formattedViewNameList.Add($"'{viewName}'");

                            whereClause += $" AND sys.objects.name IN ({string.Join(",", formattedViewNameList)}) ";
                        }

                        break;
                    }
                }

                sqlService.AddParameter("@PAGE_INDEX", SqlDbType.Int, 0);
                sqlService.AddParameter("@PAGE_SIZE", SqlDbType.Int, int.MaxValue);
                sqlService.AddParameter("@WHERE_CLAUSE", SqlDbType.VarChar, whereClause);
                sqlService.AddParameter("@ORDER_BY_CLAUSE", SqlDbType.VarChar, string.Empty);
                sqlService.AddOutputParameter("@RECORD_COUNT", SqlDbType.Int);

                using (var reader = sqlService.ExecuteStoredProcedureReader("SYS_OBJECTS_SELECT"))
                {
                    while (reader.Read())
                    {
                        var entity = new T();

                        entity.EntityType = sqlServerEntityType;
                        entity.Id = reader.GetInt32(0);
                        entity.Name = reader.GetString(1);
                        entity.SchemaOwner = reader.GetString(2);

                        var formattedName = !string.IsNullOrWhiteSpace(IgnorePrefix) && entity.Name.Contains(IgnorePrefix) ? entity.Name.Replace(IgnorePrefix, string.Empty) : entity.Name;
                        var alphaText = AlphaTextRegex.Match(formattedName).Value;
                        
                        entity.FormattedName = alphaText.Replace("_", string.Empty).All(char.IsUpper) ? formattedName.ToPascalCase() : formattedName;

                        entityList.Add(entity);
                    }
                }

                return entityList;
            }
            finally
            {
                sqlService.Dispose();
            }
        }

        #endregion entities

        #region columns

        /// <summary>
        /// Get a list of columns for any entity.
        /// </summary>
        /// <param name="objectIdList">The list of object ids to get columns for.</param>
        private List<SqlServerColumn> GetColumns(SqlServerEntityTypeCode sqlServerEntityType, List<int> objectIdList)
        {
            var sqlService = new SqlService();
            sqlService.ConnectionString = this.ConnectionString;
            sqlService.AutoCloseConnection = true;

            var columnList = new List<SqlServerColumn>();
            var whereClause = string.Empty;

            switch (sqlServerEntityType)
            {
                case SqlServerEntityTypeCode.Table:
                {
                    whereClause = "sys.objects.type = 'U'";
                    break;
                }
                case SqlServerEntityTypeCode.View:
                {
                    whereClause = "sys.objects.type = 'V'";
                    break;
                }
            }

            // limit the sys.objects query to just those ids being modeled
            if (objectIdList.Any())
            {
                var idListString = string.Join(",", objectIdList);
                whereClause += $" AND [sys].[objects].[object_id] IN ({idListString})";
            }

            sqlService.AddParameter("@PAGE_INDEX", SqlDbType.Int, 0);
            sqlService.AddParameter("@PAGE_SIZE", SqlDbType.Int, int.MaxValue);
            sqlService.AddParameter("@WHERE_CLAUSE", SqlDbType.VarChar, whereClause);
            sqlService.AddParameter("@ORDER_BY_CLAUSE", SqlDbType.VarChar, string.Empty);
            sqlService.AddOutputParameter("@RECORD_COUNT", SqlDbType.Int);

            using (var reader = sqlService.ExecuteStoredProcedureReader("SYS_COLUMNS_SELECT"))
            {
                while (reader.Read())
                {
                    var column = new SqlServerColumn();
                    column.SqlServerEntityId = reader.GetInt32(0);
                    column.SqlServerEntityName = reader.GetString(1);
                    column.ColumnId = reader.GetInt32(2);
                    column.Name = reader.GetString(3);
                    column.FormattedName = !string.IsNullOrWhiteSpace(IgnorePrefix) && column.Name.Contains(IgnorePrefix) ? column.Name.Replace(IgnorePrefix, string.Empty).ToPascalCase() : column.Name.ToPascalCase();
                    column.DataTypeName = reader.GetString(4);
                    column.DataType = (SqlServerDataTypeCode)reader.GetInt32(5);
                    column.MaxLength = reader.GetInt16(6);
                    column.Precision = reader.GetByte(7);
                    column.Scale = reader.GetByte(8);
                    column.IsNullable = reader.GetBoolean(9);
                    column.IsIdentity = reader.GetBoolean(10);
                    column.IsComputed = reader.GetBoolean(11);

                    columnList.Add(column);
                }
            }

            return columnList;
        }

        #endregion columns   

        #region indexes

        /// <summary>
        /// Get indexes for objects.
        /// </summary>
        /// <param name="tableList">The list of tables to get indexes for.</param>
        private List<SqlServerIndex> GetIndexes(List<SqlServerTable> tableList)
        {
            var sqlService = new SqlService();
            sqlService.ConnectionString = this.ConnectionString;
            sqlService.AutoCloseConnection = true;

            try
            {
                var indexList = new List<SqlServerIndex>();
                var whereClause = string.Empty;

                // limit the sys.indexes query to just those object ids being modeled
                if (tableList.Any())
                {
                    var idListString = string.Join(",", tableList.Select(t => t.Id));
                    whereClause = $"[object_id] IN ({idListString})";
                }

                sqlService.AddParameter("@PAGE_INDEX", SqlDbType.Int, 0);
                sqlService.AddParameter("@PAGE_SIZE", SqlDbType.Int, int.MaxValue);
                sqlService.AddParameter("@WHERE_CLAUSE", SqlDbType.VarChar, whereClause);
                sqlService.AddParameter("@ORDER_BY_CLAUSE", SqlDbType.VarChar, string.Empty);
                sqlService.AddOutputParameter("@RECORD_COUNT", SqlDbType.Int);

                using (var reader = sqlService.ExecuteStoredProcedureReader("SYS_INDEXES_SELECT"))
                {
                    while (reader.Read())
                    {
                        var indexId = reader.GetInt32(1);
                        var objectId = reader.GetInt32(3);
                        var isIncludedColumn = reader.GetBoolean(11);

                        var index = indexList.FirstOrDefault(i => i.SqlServerEntityId == objectId && i.IndexId == indexId);

                        if (index == null)
                        {
                            index = new SqlServerIndex();
                            index.IndexName = reader.GetString(0);
                            index.IndexId = reader.GetInt32(1);
                            index.SqlServerEntityName = reader.GetString(2);
                            index.SqlServerEntityId = reader.GetInt32(3);
                            index.IndexType = (SqlServerSysIndexTypeCode)reader.GetByte(6);
                            index.IsUnique = reader.GetBoolean(7);
                            index.IsDescendingKey = reader.GetBoolean(8);
                            index.ColumnOrdinal = reader.GetByte(9);
                            index.IsPrimaryKey = reader.GetBoolean(10);
                            index.IsIncludeColumn = reader.GetBoolean(11);

                            index.IncludedColumns = new List<SqlServerColumn>();
                            index.MemberColumns = new List<SqlServerColumn>();

                            indexList.Add(index);

                        }

                        var table = tableList.FirstOrDefault(t => t.Id == objectId);

                        if (table != null)
                        {
                            var columnId = reader.GetInt32(5);
                            var column = table.Columns.FirstOrDefault(c => c.ColumnId == columnId);
                            
                            if (!isIncludedColumn && index.MemberColumns.All(c => c.ColumnId != columnId))
                                index.MemberColumns.Add(column);

                            if (isIncludedColumn && index.IncludedColumns.All(c => c.ColumnId != columnId))
                                index.IncludedColumns.Add(column);
                        }
                    }
                }

                foreach (var index in indexList)
                {
                    var memberColumnIdentifier = index.SqlServerEntityName;

                    foreach (var memberColumn in index.MemberColumns)
                        memberColumnIdentifier += $"_{(index.IsPrimaryKey ? "PK" : "IX")}_{memberColumn.Name}";

                    index.MemberColumnIdentifier = memberColumnIdentifier;
                }

                return indexList.GroupBy(i => i.MemberColumnIdentifier).Select(i => i.First()).ToList();
            }
            finally
            {
                sqlService.Dispose();
            }
        }

        #endregion

        #region foreign keys

        /// <summary>
        /// Get foreign keys for the tables.
        /// </summary>
        /// <param name="tableList">The list of tables to get foreign keys for.</param>
        private List<SqlServerForeignKey> GetForeignKeys(List<SqlServerTable> tableList)
        {
            var sqlService = new SqlService();
            sqlService.ConnectionString = this.ConnectionString;
            sqlService.AutoCloseConnection = true;

            try
            {
                var foreignKeyList = new List<SqlServerForeignKey>();
                var whereClause = string.Empty;

                // limit the sys.foreign_key_columns query to just those table ids being modeled
                if (tableList.Any())
                {
                    var idListString = string.Join(",", tableList.Select(t => t.Id));
                    whereClause = $"[parent_object_id] IN ({idListString})";
                }

                sqlService.AddParameter("@PAGE_INDEX", SqlDbType.Int, 0);
                sqlService.AddParameter("@PAGE_SIZE", SqlDbType.Int, int.MaxValue);
                sqlService.AddParameter("@WHERE_CLAUSE", SqlDbType.VarChar, whereClause);
                sqlService.AddParameter("@ORDER_BY_CLAUSE", SqlDbType.VarChar, string.Empty);
                sqlService.AddOutputParameter("@RECORD_COUNT", SqlDbType.Int);

                using (var reader = sqlService.ExecuteStoredProcedureReader("SYS_FOREIGN_KEY_COLUMNS_SELECT"))
                {
                    while (reader.Read())
                    {
                        var foreignKeyId = reader.GetInt32(0);

                        var foreignKey = foreignKeyList.FirstOrDefault(f => f.ForeignKeyId == foreignKeyId);

                        if (foreignKey == null)
                        {
                            foreignKey = new SqlServerForeignKey();

                            foreignKey.ForeignKeyId = reader.GetInt32(0);
                            foreignKey.Name = reader.GetString(1);
                            foreignKey.ForeignKeyEntityId = reader.GetInt32(2);
                            foreignKey.ForeignKeyEntityName = reader.GetString(3);
                            foreignKey.PrimaryKeyEntityId = reader.GetInt32(7);
                            foreignKey.PrimaryKeyEntityName = reader.GetString(8);

                            foreignKey.Relationships = new List<SqlServerForeignKeyRelationship>();

                            foreignKeyList.Add(foreignKey);
                        }

                        SqlServerColumn foreignKeyColumn = null;
                        var foreignKeyColumnId = reader.GetInt32(4);
                        var primaryKeyColumnId = reader.GetInt32(9);

                        var relationship = foreignKey.Relationships.FirstOrDefault(r => r.ForeignKeyColumn != null && r.ForeignKeyColumn.ColumnId == foreignKeyColumnId && r.PrimaryKeyColumn.ColumnId == primaryKeyColumnId);

                        if (relationship == null)
                        {
                            relationship = new SqlServerForeignKeyRelationship();

                            // look for the foreign key column in the model and set it in the relationship
                            var foreignKeyTable = tableList.FirstOrDefault(t => t.Id == foreignKey.ForeignKeyEntityId);

                            if (foreignKeyTable != null)
                            {
                                foreignKeyColumn = foreignKeyTable.Columns.FirstOrDefault(c => c.ColumnId == foreignKeyColumnId);

                                if (foreignKeyColumn != null)
                                {
                                    foreignKeyColumn.IsForeignKey = true;
                                    relationship.ForeignKeyColumn = foreignKeyColumn;
                                }
                            }

                            // look for the primary key column in the model and set it in the relationship
                            var primaryKeyTable = tableList.FirstOrDefault(t => t.Id == foreignKey.PrimaryKeyEntityId);

                            if (primaryKeyTable != null)
                            {
                                var primaryKeyColumn = primaryKeyTable.Columns.FirstOrDefault(c => c.ColumnId == primaryKeyColumnId);
                                relationship.PrimaryKeyColumn = primaryKeyColumn;
                            }
                            // if the primary key table isn't modeled, construct the info manually
                            else
                            {
                                var primaryKeyColumn = new SqlServerColumn();
                                primaryKeyColumn.ColumnId = primaryKeyColumnId;
                                primaryKeyColumn.Name = reader.GetString(10);
                                primaryKeyColumn.DataType = (SqlServerDataTypeCode)reader.GetInt32(11);
                                primaryKeyColumn.SqlServerEntityId = foreignKey.PrimaryKeyEntityId;
                                primaryKeyColumn.SqlServerEntityName = foreignKey.PrimaryKeyEntityName;
                                primaryKeyColumn.IsPrimaryKey = true;
                                relationship.PrimaryKeyColumn = primaryKeyColumn;
                            }

                            foreignKey.Relationships.Add(relationship);
                        }
                    }
                }

                return foreignKeyList;
            }
            finally
            {
                sqlService.Dispose();
            }
        }

        #endregion foreign keys

        #region extended properties

        /// <summary>
        /// Get the list of extended properties for each table.
        /// </summary>
        /// <param name="extendedPropertyType"></param>
        /// <param name="idList">The list of object ids to get extended properties for.</param>
        private List<SqlServerExtendedProperty> GetExtendedProperties(SqlServerExtendedPropertyTypeCode extendedPropertyType, List<int> idList)
        {
            var sqlService = new SqlService();
            sqlService.ConnectionString = this.ConnectionString;
            sqlService.AutoCloseConnection = true;

            try
            {
                var extendedPropertyList = new List<SqlServerExtendedProperty>();
                var whereClause = string.Empty;
                
                // sys.extended_properties has a major id that equals the table id
                // and a minor id that references the column id so based on type
                // we need to get the right minor_id values so we can get all of them.
                switch (extendedPropertyType)
                {
                    case SqlServerExtendedPropertyTypeCode.Column:
                    {
                        whereClause = "[minor_id] > 0";
                        break;
                    }
                    case SqlServerExtendedPropertyTypeCode.StoredProcedure:
                    case SqlServerExtendedPropertyTypeCode.Table:
                    case SqlServerExtendedPropertyTypeCode.View:
                    {
                        whereClause = "[minor_id] = 0";
                        break;
                    }
                }

                // limit the sys.extended_properties query to just those table
                // ids being modeled via major_id
                if (idList.Any())
                {
                    var idListString = string.Join(",", idList);
                    whereClause += $" AND [major_id] IN ({idListString})";
                }

                sqlService.AddParameter("@PAGE_INDEX", SqlDbType.Int, 0);
                sqlService.AddParameter("@PAGE_SIZE", SqlDbType.Int, int.MaxValue);
                sqlService.AddParameter("@WHERE_CLAUSE", SqlDbType.VarChar, whereClause);
                sqlService.AddParameter("@ORDER_BY_CLAUSE", SqlDbType.VarChar, string.Empty);
                sqlService.AddOutputParameter("@RECORD_COUNT", SqlDbType.Int);

                using (var reader = sqlService.ExecuteStoredProcedureReader("SYS_EXTENDED_PROPERTIES_SELECT"))
                {
                    while (reader.Read())
                    {
                        var extendedProperty = new SqlServerExtendedProperty();
                        extendedProperty.MajorId = reader.GetInt32(0);
                        extendedProperty.MinorId = reader.GetInt32(1);
                        extendedProperty.Name = reader.GetString(2);
                        extendedProperty.Value = reader[3].ToString(); // this is a variant type, so force it to a string

                        extendedPropertyList.Add(extendedProperty);
                    }
                }

                return extendedPropertyList;
            }
            finally
            {
                sqlService.Dispose();
            }
        }

        #endregion extended properties

        #region stored procedures

        private List<SqlServerStoredProcedure> BuildStoredProcedures()
        {
            var storedProcedureList = GetStoredProcedures();

            //------------------------------------------------------
            // stored procedure extended properties
            //------------------------------------------------------
            var storedProcedureIdList = storedProcedureList.Select(t => t.Id).ToList();
            var extendedPropertyList = GetExtendedProperties(SqlServerExtendedPropertyTypeCode.StoredProcedure, storedProcedureIdList);

            // attach each extended property to its respective table
            foreach (var extendedProperty in extendedPropertyList)
            {
                var storedProcedure = storedProcedureList.FirstOrDefault(t => t.Id == extendedProperty.MajorId);
                storedProcedure?.ExtendedProperties.Add(extendedProperty);
            }

            return storedProcedureList;
        }

        /// <summary>
        /// Get a list of stored procedures from the database
        /// </summary>
        /// <returns>A list of SqlServerStoredProcedure that represents the sprocs in the database.</returns>
        private List<SqlServerStoredProcedure> GetStoredProcedures()
        {
            var sqlService = new SqlService();
            sqlService.ConnectionString = this.ConnectionString;
            sqlService.AutoCloseConnection = true;

            try
            {
                var storedProcedureList = new List<SqlServerStoredProcedure>();
                var whereClause = string.Empty;

                // limit the to model to particular table based on consistent name patterns, if any
                // it will pick up some false positives, but better than nothing
                if (ScopedTableNameList != null && ScopedTableNameList.Any())
                {
                    foreach (var tableName in ScopedTableNameList)
                        whereClause += (!string.IsNullOrWhiteSpace(whereClause) ? " OR " : string.Empty) + $" sys.objects.name LIKE '%{tableName}%' ";
                }

                // limit the to model to particular views based on consistent name patterns, if any
                // it will pick up some false positives, but better than nothing
                if (ScopedViewNameList != null && ScopedViewNameList.Any())
                {
                    foreach (var viewName in ScopedViewNameList)
                        whereClause += (!string.IsNullOrWhiteSpace(whereClause) ? " OR " : string.Empty) + $"OR sys.objects.name LIKE '%{viewName}%' ";
                }

                sqlService.AddParameter("@PAGE_INDEX", SqlDbType.Int, 0);
                sqlService.AddParameter("@PAGE_SIZE", SqlDbType.Int, int.MaxValue);
                sqlService.AddParameter("@WHERE_CLAUSE", SqlDbType.VarChar, whereClause);
                sqlService.AddParameter("@ORDER_BY_CLAUSE", SqlDbType.VarChar, string.Empty);
                sqlService.AddOutputParameter("@RECORD_COUNT", SqlDbType.Int);

                using (var reader = sqlService.ExecuteStoredProcedureReader("SYS_PROCEDURES_SELECT"))
                {
                    while (reader.Read())
                    {
                        var storedProcedure = new SqlServerStoredProcedure();
                        storedProcedure.Id = reader.GetInt32(0);
                        storedProcedure.Name = reader.GetString(1);
                        storedProcedure.SchemaOwner = reader.GetString(2);
                        storedProcedure.IsStartupSproc = reader.GetBoolean(3);

                        storedProcedureList.Add(storedProcedure);
                    }
                }

                return storedProcedureList;
            }
            finally
            {
                sqlService.Dispose();
            }
        }

        #endregion stored procedures

        #region type codes

        public List<TypeCode> BuildTypeCodes()
        {
            var sqlService = new SqlService();
            sqlService.ConnectionString = this.ConnectionString;
            sqlService.AutoCloseConnection = true;

            try
            {
                var typeCodeList = new List<TypeCode>();

                // get a list of type codes from the core table. these are internal type codes, 
                // not likely used for reporting
                using (var reader = sqlService.ExecuteStoredProcedureReader("TYPE_CODE_SELECT"))
                {
                    while (reader.Read())
                    {
                        var name = reader.GetString(0);

                        var ignorePrefix = IgnorePrefix.ToPascalCase().Replace("_", string.Empty);
                        name = !string.IsNullOrWhiteSpace(IgnorePrefix) && name.StartsWith(ignorePrefix) ? name.Replace(ignorePrefix, string.Empty) : name;

                        var typeCode = typeCodeList.FirstOrDefault(t => t.Name == reader.GetString(0));

                        if (typeCode == null)
                        {
                            typeCode = new TypeCode();
                            typeCodeList.Add(typeCode);
                        }

                        typeCode.Name = reader.GetString(0);

                        var typeCodeItem = new TypeCodeItem()
                        {
                            Key = reader.GetString(1),
                            Value = reader.GetByte(2),
                            DisplayName = !reader.IsDBNull(3) ? reader.GetString(3) : string.Empty,
                            ShortName = !reader.IsDBNull(4) ? reader.GetString(4) : string.Empty,
                            Description = !reader.IsDBNull(5) ? reader.GetString(5) : string.Empty
                        };

                        typeCode.TypeCodeItems.Add(typeCodeItem);
                    }
                }

                // now build a list of type codes for reporting outside of the internal ones
                var typeCodeTableList = GetEntities<SqlServerTable>(SqlServerEntityTypeCode.TypeCode);

                foreach (var typeCodeTable in typeCodeTableList)
                {
                    var typeCodeSelect = typeCodeTable.Name.Replace("_", string.Empty).All(char.IsUpper) ? $"{typeCodeTable.Name}_SELECT" : $"{typeCodeTable.Name}Select";

                    using (var reader = sqlService.ExecuteStoredProcedureReader(typeCodeSelect))
                    {
                        while (reader.Read())
                        {
                            var typeCodeName = !string.IsNullOrWhiteSpace(IgnorePrefix) && typeCodeTable.Name.Contains(IgnorePrefix) ? typeCodeTable.Name.Replace(IgnorePrefix, string.Empty).ToPascalCase() : typeCodeTable.Name.ToPascalCase();
                            var typeCode = typeCodeList.FirstOrDefault(t => t.Name == typeCodeName);

                            if (typeCode == null)
                            {
                                typeCode = new TypeCode();
                                typeCodeList.Add(typeCode);
                            }

                            typeCode.Name = typeCodeName;

                            var typeCodeItem = new TypeCodeItem()
                            {
                                Value = reader.GetFieldType(0) == typeof(byte) ? reader.GetByte(0) : reader.GetInt32(0),
                                Key = reader.GetString(1),
                                DisplayName = !reader.IsDBNull(2) ? reader.GetString(2) : string.Empty,
                                ShortName = !reader.IsDBNull(3) ? reader.GetString(3) : string.Empty,
                                Description = !reader.IsDBNull(4) ? reader.GetString(4) : string.Empty
                            };

                            typeCode.TypeCodeItems.Add(typeCodeItem);
                        }
                    }
                }

                foreach (var typeCode in typeCodeList)
                {
                    typeCode.TypeCodeItems = typeCode.TypeCodeItems.OrderBy(t => t.Value).ToList();
                }

                return typeCodeList.OrderBy(t => t.Name).ToList();
            }
            finally
            {
                sqlService.Dispose();
            }
        }

        #endregion type codes

        #region utility methods

        public string FormatEntityName(string entityName)
        {
            var formattedName = !string.IsNullOrWhiteSpace(IgnorePrefix) && entityName.Contains(IgnorePrefix) ? entityName.Replace(IgnorePrefix, string.Empty) : entityName;
            //var alphaText = formattedName.Replace("_", string.Empty);
            
            //var matches = AlphaTextRegex.Matches(formattedName);
            //var alphaText = matches.Cast<object>().Aggregate(string.Empty, (current, m) => current + m);

            formattedName = formattedName.ToPascalCase();

            return formattedName;
        }

        #endregion utility methods
    }
}
