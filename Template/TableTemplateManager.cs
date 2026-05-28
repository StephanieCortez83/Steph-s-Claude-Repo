using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ACS.Core.Extensions;
using ACS.Core.Sql;
using ACS.Core.SqlServer;
using Newtonsoft.Json;

namespace ACS.Core.Template
{
    /// <summary>
    /// A TemplateManager that is specific to database tables.
    /// </summary>
    public class TableTemplateManager : TemplateManager
    {
        #region properties

        public SqlServerModel DatabaseModel => _databaseModel ?? (_databaseModel = GetDatabaseModel());

        public List<TemplateProperty> TemplateTables => _templateTables ?? (_templateTables = GetSourceTables());

        private SqlServerModel _databaseModel;
        private List<TemplateProperty> _templateTables;

        #endregion

        #region constructor

        public TableTemplateManager(string templateBaseFilePath, string templateName) : base(templateBaseFilePath, templateName)
        {
        }

        #endregion

        #region methods

        /// <summary>
        /// Model the database tables.
        /// </summary>
        /// <returns>A SqlServerModel representation of the database.</returns>
        public SqlServerModel GetDatabaseModel()
        {
            var tableList = new List<string>();

            foreach (var templateTable in TemplateTables)
                tableList.Add(templateTable.Value);

            var sqlServerModel = new SqlServerModel
            {
                ConnectionString = ConnectionString,
                IgnorePrefix = IgnorePrefix,
                ModelViews =  false,
                ModelTypeCodes = false,
                ModelStoredProcedures = false,
                ScopedTableNameList = tableList
            };

            sqlServerModel.GenerateModel();

            return sqlServerModel;
        }
        
        /// <summary>
        /// Column name overrides are used to provide better database column names,
        /// which will translate to better .Net field name generation.
        /// </summary>
        /// <param name="tableName">The table that a column corresponds to.</param>
        /// <param name="columnName">A column name to look for.</param>
        /// <returns>A column name override, if any.</returns>
        public string GetColumnNameOverride(string tableName, string columnName)
        {
            var propertySet = GetSourceTableTemplatePropertySet(tableName);

            var columnNameOverrideProperty = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("ColumnNameOverrides", StringComparison.InvariantCultureIgnoreCase));

            if (columnNameOverrideProperty != null)
            {
                var columnNameOverrides = columnNameOverrideProperty.Value.Split(',');

                foreach (var columnNameOverride in columnNameOverrides)
                {
                    var columnNameOverridePair = columnNameOverride.Split('=');

                    if (columnNameOverridePair[0].Equals(columnName, StringComparison.InvariantCultureIgnoreCase))
                    {
                        return columnNameOverridePair[1];
                    }
                }
            }

            return columnName;
        }

        public string GetRequiredFieldCheck(SqlServerEntity table, SqlServerColumn column)
        {
            if (IsWriteColumnExclusion(table, column))
                return string.Empty;

            var entityName = table.Name.ToPascalCase();
            var propertyName = GetColumnNameOverride(table.Name, column.Name).ToPascalCase();
            var camelCaseObjectName = entityName.ToCamelCase();

            switch (column.DataType)
            {
                case SqlServerDataTypeCode.Char:
                case SqlServerDataTypeCode.NChar:
                case SqlServerDataTypeCode.NVarChar:
                case SqlServerDataTypeCode.VarChar:
                {
                    return $"if (string.IsNullOrWhiteSpace({camelCaseObjectName}.{propertyName}))";
                }
                case SqlServerDataTypeCode.BigInt:
                case SqlServerDataTypeCode.Decimal:
                case SqlServerDataTypeCode.Float:
                case SqlServerDataTypeCode.Money:
                case SqlServerDataTypeCode.SmallInt:
                case SqlServerDataTypeCode.Int:
                case SqlServerDataTypeCode.TinyInt:
                {
                    if (column.IsForeignKey)
                        return column.IsNullable ? $"if ({camelCaseObjectName}.{propertyName} == null || {camelCaseObjectName}.{propertyName} <= 0)" : $"if ({camelCaseObjectName}.{propertyName} <= 0)";

                    var dotNetType = ToDotNetDataType(column);

                    return column.IsNullable ? $"if ({camelCaseObjectName}.{propertyName} == null || {camelCaseObjectName}.{propertyName} <= {GetDefaultDataValue(dotNetType)})" : $"if ({camelCaseObjectName}.{propertyName} <= {GetDefaultDataValue(dotNetType)})";
                }
                case SqlServerDataTypeCode.DateTime:
                case SqlServerDataTypeCode.DateTime2:
                {
                    var dotNetType = ToDotNetDataType(column);

                    return $"if ({camelCaseObjectName}.{propertyName} <= {GetDefaultDataValue(dotNetType)})";
                }
                default:
                {
                    return column.IsNullable ? $"if ({camelCaseObjectName}.{propertyName} == null)" : string.Empty;
                }
            }
        }

        #endregion
    }
}
