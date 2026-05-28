using System;
using System.Collections;
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
    /// A TemplateManager that is specific to database views.
    /// </summary>
    public class ViewTemplateManager : TemplateManager
    {
        #region properties

        public SqlServerModel DatabaseModel => _databaseModel ?? (_databaseModel = GetDatabaseModel());

        public List<TemplateProperty> TemplateViews => _templateViews ?? (_templateViews = GetSourceViews());

        private SqlServerModel _databaseModel;
        private List<TemplateProperty> _templateViews;

        #endregion

        #region constructor

        public ViewTemplateManager(string templateBaseFilePath, string templateName) : base(templateBaseFilePath, templateName)
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
            var viewList = new List<string>();

            foreach (var templateView in TemplateViews)
                viewList.Add(templateView.Value);

            var sqlServerModel = new SqlServerModel
            {
                ConnectionString = ConnectionString,
                IgnorePrefix = IgnorePrefix,
                ModelTables = false,
                ModelViews =  true,
                ModelTypeCodes = false,
                ModelStoredProcedures = false,
                ScopedViewNameList = viewList
            };

            sqlServerModel.GenerateModel();

            return sqlServerModel;
        }

        /// <summary>
        /// Column name overrides are used to provide better database column names,
        /// which will translate to better .Net field name generation.
        /// </summary>
        /// <param name="viewName">The view that a column corresponds to.</param>
        /// <param name="columnName">A column name to look for.</param>
        /// <returns>A column name override, if any.</returns>
        public string GetColumnNameOverride(string viewName, string columnName)
        {
            var propertySet = GetSourceViewTemplatePropertySet(viewName);

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

        /// <summary>
        /// Translate SQL Server data types to .Net data types.
        /// </summary>
        /// <param name="column">The the column to translate.</param>
        /// <returns>The .Net data type that corresponds to the SQL Server data type.</returns>
        public new string ToDotNetDataType(SqlServerColumn column)
        {
            var columnName = column.Name;
            var typeCodeOverrides = GetTypeCodeOverrides(column.SqlServerEntityName);

            if (typeCodeOverrides.ContainsKey(column.Name))
                columnName = typeCodeOverrides[column.Name].ToString();

            if (columnName.EndsWith("TYPE_CODE") || columnName.EndsWith("TypeCode")) return columnName.ToPascalCase();

            switch (column.DataType)
            {
                case SqlServerDataTypeCode.BigInt:
                {
                    return DotNetDataTypeCode.Int64.GetDisplayShortName();
                }

                case SqlServerDataTypeCode.Binary:
                case SqlServerDataTypeCode.Image:
                case SqlServerDataTypeCode.VarBinary:
                {
                    return DotNetDataTypeCode.ByteArray.GetDisplayShortName();
                }

                case SqlServerDataTypeCode.Bit:
                {
                    return DotNetDataTypeCode.Boolean.GetDisplayShortName();
                }

                case SqlServerDataTypeCode.Char:
                {
                    return DotNetDataTypeCode.Char.GetDisplayShortName();
                }

                case SqlServerDataTypeCode.DateTime:
                case SqlServerDataTypeCode.DateTime2:
                case SqlServerDataTypeCode.SmallDateTime:
                {
                    return DotNetDataTypeCode.DateTime.GetDisplayShortName();
                }

                case SqlServerDataTypeCode.Decimal:
                case SqlServerDataTypeCode.Money:
                case SqlServerDataTypeCode.Numeric:
                {
                    return DotNetDataTypeCode.Decimal.GetDisplayShortName();
                }

                case SqlServerDataTypeCode.Float:
                {
                    return DotNetDataTypeCode.Double.GetDisplayShortName();
                }

                case SqlServerDataTypeCode.Int:
                {
                    return DotNetDataTypeCode.Int.GetDisplayShortName();
                }

                case SqlServerDataTypeCode.NChar:
                case SqlServerDataTypeCode.NVarChar:
                case SqlServerDataTypeCode.Text:
                case SqlServerDataTypeCode.VarChar:
                case SqlServerDataTypeCode.Xml:
                {
                    return DotNetDataTypeCode.String.GetDisplayShortName();
                }

                case SqlServerDataTypeCode.Real:
                {
                    return DotNetDataTypeCode.Single.GetDisplayShortName();
                }

                case SqlServerDataTypeCode.SmallInt:
                {
                    return DotNetDataTypeCode.Int16.GetDisplayShortName();
                }

                case SqlServerDataTypeCode.TinyInt:
                {
                    return DotNetDataTypeCode.Byte.GetDisplayShortName();
                }

                case SqlServerDataTypeCode.UniqueIdentifier:
                {
                    return DotNetDataTypeCode.Guid.GetDisplayShortName();
                }

                default:
                    return null;
            }
        }

        /// <summary>
        /// Get the SqlReader method used to extract data from a reader.
        /// </summary>
        /// <param name="column">The SqlServerColumn to translate into a Sql read method.</param>
        /// <returns>The SqlReader method.</returns>
        public new string GetSqlReaderMethod(SqlServerColumn column)
        {
            var statement = string.Empty;

            if (column.Name.EndsWith("TYPE_CODE"))
            {
                var columnName = column.Name.ToPascalCase();
                var typeName = columnName;

                var typeCodeOverrides = GetTypeCodeOverrides(column.SqlServerEntityName);

                if (typeCodeOverrides.ContainsKey(column.Name))
                    typeName = typeCodeOverrides[column.Name].ToString().ToPascalCase();

                statement += column.IsNullable ? $"({typeName}?)" : $"({columnName})";
            }

            var dotNetDataTypeName = ToDotNetDataType(column);
            statement += "reader.";

            var success = EnumExtensions.TryParseByShortName(dotNetDataTypeName, out DotNetDataTypeCode dotNetDataType);

            if (dotNetDataTypeName.EndsWith("TypeCode"))
                dotNetDataType = DotNetDataTypeCode.Byte;

            switch (dotNetDataType)
            {
                case DotNetDataTypeCode.Boolean:
                {
                    statement += "GetBoolean";
                    break;
                }

                case DotNetDataTypeCode.Byte:
                {
                    statement += "GetByte";
                    break;
                }

                case DotNetDataTypeCode.DateTime:
                {
                    statement += "GetDateTime";
                    break;
                }

                case DotNetDataTypeCode.Decimal:
                {
                    statement += "GetDecimal";
                    break;
                }

                case DotNetDataTypeCode.Double:
                {
                    statement += "GetDouble";
                    break;
                }

                case DotNetDataTypeCode.Guid:
                {
                    statement += "GetGuid";
                    break;
                }

                case DotNetDataTypeCode.Int:
                {
                    statement += "GetInt32";
                    break;
                }

                case DotNetDataTypeCode.Int16:
                {
                    statement += "GetShort";
                    break;
                }

                case DotNetDataTypeCode.Int64:
                {
                    statement += "GetInt64";
                    break;
                }

                case DotNetDataTypeCode.String:
                {
                    statement += "GetString";
                    break;
                }

                default:
                {
                    statement += string.Empty;
                    break;
                }
            }

            return statement;
        }

        public new Hashtable GetTypeCodeOverrides(string entityName)
        {
            var propertySet = GetSourceViewTemplatePropertySet(entityName);
            var typeOverrideList = new Hashtable();

            var typeOverrideListProperty = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("TypeCodeOverrideList", StringComparison.InvariantCultureIgnoreCase));

            if (typeOverrideListProperty != null)
            {
                var typeOverrides = typeOverrideListProperty.Value.Split(',');

                if (typeOverrides.Any())
                {
                    foreach (var typeOverride in typeOverrides)
                    {
                        var typeOverridePair = typeOverride.Split('=');

                        if (typeOverridePair.Any())
                        {
                            if (!typeOverrideList.ContainsKey(typeOverridePair[0]))
                                typeOverrideList.Add(typeOverridePair[0], typeOverridePair[1]);
                        }
                    }
                }
            }

            return typeOverrideList;
        }

        #endregion
    }
}
