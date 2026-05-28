using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ACS.Core.Extensions;
using ACS.Core.Sql;
using ACS.Core.SqlServer;

namespace ACS.Core.Template
{
    public class SqlTemplateManager : TemplateManager
    {
        #region properties

        public SqlServerModel DatabaseModel => _databaseModel ?? (_databaseModel = GetDatabaseModel());

        public List<TemplateProperty> TemplateTables => _templateTables ?? (_templateTables = GetSourceTables());

        private SqlServerModel _databaseModel;
        private List<TemplateProperty> _templateTables;

        #endregion

        #region constructor

        public SqlTemplateManager(string templateBaseFilePath, string templateName) : base(templateBaseFilePath, templateName)
        {
        }

        #endregion

        #region property set methods

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
                ModelTables = true,
                ModelViews = true,
                ModelTypeCodes = false,
                ModelStoredProcedures = true,
                ScopedTableNameList = tableList
            };

            sqlServerModel.GenerateModel();

            return sqlServerModel;
        }

        /// <summary>
        /// Used to determine the default order by column for select sprocs. If
        /// none is specified, it will default to the primary key
        /// </summary>
        /// <param name="tableName">The table to find the default order by column for.</param>
        /// <returns>The default column to order by.</returns>
        public string GetDefaultOrderByColumn(string tableName)
        {
            var propertySet = GetSourceTableTemplatePropertySet(tableName);

            var defaultOrderByColumnPropertySet = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("DefaultOrderByColumn", StringComparison.InvariantCultureIgnoreCase));

            if (defaultOrderByColumnPropertySet != null)
            {
                var orderByColumns = defaultOrderByColumnPropertySet.Value.Split(',');

                var formattedOrderByColumns = orderByColumns.Select(orderByColumn => $"[{tableName}].[{orderByColumn}]").ToList();

                return string.Join(",", formattedOrderByColumns);
            }

            return $"[{tableName}].[{tableName}_ID]";
        }

        /// <summary>
        /// Used to determine which columns should have GETDATE() used as value
        /// assignment during write operations.
        /// </summary>
        /// <param name="tableName">The table to examine columns for.</param>
        /// <returns>A list of columns to use GETDATE() for the value assignment.</returns>
        public List<string> GetUpdateGetDateWriteColumns(string tableName)
        {
            var propertySet = GetSourceTableTemplatePropertySet(tableName);
            var getDateWriteColumnList = new List<string>();

            var getDateWriteColumnListProperty = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("UpdateGetDateColumnWriteList", StringComparison.InvariantCultureIgnoreCase));

            if (getDateWriteColumnListProperty != null)
            {
                var getDateWriteColumns = getDateWriteColumnListProperty.Value.Split(',');

                if (getDateWriteColumns.Any())
                    getDateWriteColumnList = getDateWriteColumns.ToList();
            }

            return getDateWriteColumnList;
        }

        /// <summary>
        /// Used to determine if drop statements should be added to the sproc generation
        /// </summary>
        /// <param name="entity">The table to check for drop statement generation.</param>
        /// <returns>True if a drop statement sproc should be generated for each sproc.</returns>
        public bool GenerateDrop(SqlServerEntity entity)
        {
            var propertySet = GetSourceTableTemplatePropertySet(entity.Name);

            var generateDropProperty = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("GenerateDrop", StringComparison.InvariantCultureIgnoreCase));

            if (generateDropProperty != null)
            {
                var success = bool.TryParse(generateDropProperty.Value, out var generateDrop);

                if (success)
                    return generateDrop;
            }

            return true;
        }

        #endregion

        #region code generation formatting methods

        /// <summary>
        /// Generate a SQL statement string of SQL parameters for a given table.
        /// </summary>
        /// <param name="table">The table that contains the columns to use as parameters.</param>
        /// <param name="linePrefix">A formatting string to prefix each line with, ex. a tab.</param>
        /// <returns>A string of SQL parameters.</returns>
        public string GetTableParameterList(SqlServerTable table, string linePrefix)
        {
            return GetTableParameterList(table, new List<SqlServerColumn>(), linePrefix);
        }

        /// <summary>
        /// Generate a SQL statement string of SQL parameters for a given table.
        /// </summary>
        /// <param name="table">The table that contains the columns to use as parameters.</param>
        /// <param name="outputColumn">An column that should be assigned as OUTPUT parameter at the end.</param>
        /// <param name="linePrefix">A formatting string to prefix each line with, ex. a tab.</param>
        /// <returns>A string of SQL parameters.</returns>
        public string GetTableParameterList(SqlServerTable table, SqlServerColumn outputColumn, string linePrefix)
        {
            var outputColumns = new List<SqlServerColumn>();
            outputColumns.Add(outputColumn);

            return GetTableParameterList(table, outputColumns, linePrefix);
        }

        /// <summary>
        /// Generate a SQL statement string of SQL parameters for a given table.
        /// </summary>
        /// <param name="table">The table that contains the columns to use as parameters.</param>
        /// <param name="outputColumns">Any columns that should be assigned as OUTPUT parameters at the end.</param>
        /// <param name="linePrefix">A formatting string to prefix each line with, ex. a tab.</param>
        /// <returns>A string of SQL parameters.</returns>
        public string GetTableParameterList(SqlServerTable table, List<SqlServerColumn> outputColumns, string linePrefix)
        {
            var parameterList = string.Empty;
            var i = 0;

            foreach (var column in table.Columns)
            {
                if (!IsWriteColumnExclusion(table, column) && outputColumns.All(o => o.ColumnId != column.ColumnId))
                {
                    parameterList += linePrefix + (i > 0 ? "," : " ") + $"{GetSqlParameter(column)}\r\n";
                    i++;
                }
            }

            foreach (var outputColumn in outputColumns)
            {
                parameterList += linePrefix + (i > 0 ? "," : " ") + $"{GetSqlParameter(outputColumn, true)}\r\n";
            }

            parameterList = TrimTrailingCarriageReturn(parameterList);

            return parameterList;
        }

        /// <summary>
        /// Generate a SQL statement string of SQL parameters for a given list of columns to be
        /// used in a stored procedure
        /// </summary>
        /// <param name="columnList">A list of SqlServerColumn to generate a parameter list for.</param>
        /// <param name="linePrefix">A formatting string to prefix each line with, ex. a tab.</param>
        /// <returns>A string of SQL parameters.</returns>
        public string GetColumnListParameters(List<SqlServerColumn> columnList, string linePrefix)
        {
            var parameterList = string.Empty;
            var i = 0;

            foreach (var column in columnList)
            {
                parameterList += linePrefix + (i > 0 ? "," : " ") + $"{GetSqlParameter(column)}\r\n";
                i++;
            }

            parameterList = TrimTrailingCarriageReturn(parameterList);

            return parameterList;
        }

        /// <summary>
        /// Given a SqlServerColumn, build a SqlParameter
        /// </summary>
        /// <param name="column">The column to build a parameter for.</param>
        /// <returns>The sql parameter text.</returns>
        public string GetSqlParameter(SqlServerColumn column, bool isOutput = false)
        {
            var parameter = string.Empty;

            switch (column.DataType)
            {
                case SqlServerDataTypeCode.Char:
                case SqlServerDataTypeCode.NChar:
                case SqlServerDataTypeCode.NVarChar:
                case SqlServerDataTypeCode.VarChar:
                {
                    var maxlength = column.MaxLength == -1 ? "MAX" : column.MaxLength.ToString();
                    parameter = $"{column.DataType.GetDisplayShortName()}({maxlength})";
                    break;
                }
                case SqlServerDataTypeCode.Decimal:
                case SqlServerDataTypeCode.Numeric:
                {
                    parameter = $"{column.DataType.GetDisplayShortName()}({column.Precision},{column.Scale})";
                    break;
                    }
                default:
                {
                    parameter = column.DataType.GetDisplayShortName();
                    break;
                }
            }

            if (isOutput)
                parameter = $"{parameter} OUTPUT";

            if (column.IsNullable)
                parameter = $"{parameter} = NULL";

            parameter = $"@{column.Name} {parameter}";

            return parameter;
        }

        /// <summary>
        /// Generate a SQL column insert list to be used in the column list of an Insert predicate,
        /// ignoring primary keys and anything belonging to the WriteColumnExclusions property set. 
        /// </summary>
        /// <param name="table">The table to generate the SQL column list from.</param>
        /// <param name="linePrefix">A formatting string to prefix each line with, ex. a tab.</param>
        /// <returns>A SQL column insert column string.</returns>
        public string GetInsertList(SqlServerTable table, string linePrefix)
        {
            var insertList = string.Empty;
            var i = 0;

            foreach (var column in table.Columns)
            {

                // if it's not a primary key/identity and it's not excluded, write out 
                // the parameters for the incoming columns
                if (!IsWriteColumnExclusion(table, column) && !column.IsPrimaryKey)
                {
                    insertList += linePrefix + (i > 0 ? "," : " ") + $"[{column.Name}]\r\n";
                    i++;
                }
            }

            insertList = TrimTrailingCarriageReturn(insertList);

            return insertList;
        }

        /// <summary>
        /// Generate a SQL column insert list to be used in an Insert Values predicate,
        /// ignoring primary keys and anything belonging to the WriteColumnExclusions property set. 
        /// </summary>
        /// <param name="table">The table to generate the SQL column list from.</param>
        /// <param name="linePrefix">A formatting string to prefix each line with, ex. a tab.</param>
        /// <returns>A SQL column insert value string.</returns>
        public string GetInsertValueList(SqlServerTable table, string linePrefix)
        {
            var insertList = string.Empty;
            var i = 0;

            foreach (var column in table.Columns)
            {
                // if it's not a primary key/identity and it's not excluded, write out 
                // the parameters for the incoming values
                if (!IsWriteColumnExclusion(table, column) && !column.IsPrimaryKey)
                {
                    var columnValue = $"@{column.Name}";
                    insertList += linePrefix + (i > 0 ? "," : " ") + $"{columnValue}\r\n";

                    i++;
                }
            }

            insertList = TrimTrailingCarriageReturn(insertList);

            return insertList;
        }

        /// <summary>
        /// Generate a SQL column update list, ignoring primary keys and anything belonging to the
        /// WriteColumnExclusions property set. Any column specified in the UpdateGetDateColumnWriteList
        /// property set will be assigned GETDATE() rather than a parameter value.
        /// </summary>
        /// <param name="table">The table to generate the SQL column list from.</param>
        /// <param name="linePrefix">A formatting string to prefix each line with, ex. a tab.</param>
        /// <returns>A SQL column select string.</returns>
        public string GetUpdateColumnList(SqlServerTable table, string linePrefix)
        {
            var updateList = string.Empty;
            var getDateWriteColumns = GetUpdateGetDateWriteColumns(table.Name);
            var i = 0;

            foreach (var column in table.Columns)
            {
                var isGetDateWriteColumn = getDateWriteColumns.Any(c => c.Equals(column.Name, StringComparison.InvariantCultureIgnoreCase));

                if (!column.IsPrimaryKey && !IsWriteColumnExclusion(table, column) || isGetDateWriteColumn)
                {
                    var columnValue = isGetDateWriteColumn ? "GETDATE()" : $"@{column.Name}";
                    updateList += linePrefix + (i > 0 ? "," : " ") + $"[{column.Name}] = {columnValue}\r\n";

                    i++;
                }
            }

            updateList = TrimTrailingCarriageReturn(updateList);

            return updateList;
        }

        /// <summary>
        /// Generate a SQL column select list.
        /// </summary>
        /// <param name="table">The table to generate the SQL column list from.</param>
        /// <param name="linePrefix">A formatting string to prefix each line with, ex. a tab.</param>
        /// <returns>A SQL column select string.</returns>
        public string GetSelectList(SqlServerTable table, string linePrefix)
        {
            var selectList = string.Empty;
            var i = 0;

            foreach (var column in table.Columns)
            {
                selectList += linePrefix + (i > 0 ? "," : " ") + $"[{table.Name}].[{column.Name}]\r\n";
                    i++;
            }

            selectList = TrimTrailingCarriageReturn(selectList);

            return selectList;
        }

        /// <summary>
        /// Generate a where clause predicate for a list of SqlServerColumns.
        /// </summary>
        /// <param name="columns">A list of SqlServerColumns to add to a Where predicate.</param>
        /// <param name="linePrefix">A string (often a text formatting indicator like a carriage return) to prefix each line with.</param>
        /// <param name="isDynamicSql">Indicate if it's dynamic SQL generation, which will change the formatting.</param>
        /// <returns>A generated Where clause predicate.</returns>
        public string GetWhereClause(List<SqlServerColumn> columns, string linePrefix = "", bool isDynamicSql = false)
        {
            var whereClause = string.Empty;
            var i = 0;

            foreach (var column in columns)
            {
                if (isDynamicSql)
                {
                    whereClause += (string.IsNullOrWhiteSpace(whereClause) ? linePrefix : "\r\n" + linePrefix + "           '  AND ") + $"[{column.SqlServerEntityName}].[{column.Name}] = '";

                    switch (column.DataType)
                    {
                        case SqlServerDataTypeCode.BigInt:
                        {
                            whereClause += $" + CAST(@{column.Name} AS VARCHAR(20))" + (i == columns.Count - 2 ? " + " : string.Empty);
                            break;
                            }
                        case SqlServerDataTypeCode.Int:
                        {
                            whereClause += $" + CAST(@{column.Name} AS VARCHAR(10))" + (i == columns.Count - 2 ? " + " : string.Empty);
                            break;
                        }
                        case SqlServerDataTypeCode.TinyInt:
                        {
                            whereClause += $" + CAST(@{column.Name} AS VARCHAR(3))" + (i == columns.Count - 2 ? " + " : string.Empty);
                            break;
                        }
                        default:
                        {
                            whereClause += $" + @{column.Name}" + (i == columns.Count - 2 ? " + " : string.Empty);
                            break;
                        }
                    }

                }
                else whereClause += (string.IsNullOrWhiteSpace(whereClause) ? linePrefix : "\r\n" + linePrefix + "AND ") + $"[{column.SqlServerEntityName}].[{column.Name}] = @{column.Name}";

                i++;
            }
            return whereClause;
        }

        #endregion code generation formatting methods

        #region utility methods
        
        /// <summary>
        /// Remove the trailing carriage return on a SQL string.
        /// </summary>
        /// <param name="value">The string to trim.</param>
        /// <returns>A string value minus the ending carriage return.</returns>
        public string TrimTrailingCarriageReturn(string value)
        {
            if (value.EndsWith("\r\n"))
                value = value.Substring(0, value.Length - 2);

            return value;
        }

        #endregion utility methods
    }
}
