using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ACS.Core.SqlServer;

namespace ACS.Core.Template
{
    public class TypeCodeTemplateManager : TemplateManager
    {
        #region properties

        public SqlServerModel DatabaseModel => _databaseModel ?? (_databaseModel = GetDatabaseModel());

        public List<TemplateProperty> TemplateTables => _templateTables ?? (_templateTables = GetSourceTables());

        private SqlServerModel _databaseModel;
        private List<TemplateProperty> _templateTables;

        #endregion

        #region constructor

        public TypeCodeTemplateManager(string templateBaseFilePath, string templateName) : base(templateBaseFilePath, templateName)
        {
        }

        #endregion

        #region methods

        /// <summary>
        /// Model the type code database tables.
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
                ModelTables = false,
                ModelViews = false,
                ModelTypeCodes = true,
                ModelStoredProcedures = false,
                ScopedTypeCodeTableNameList = tableList
            };

            sqlServerModel.GenerateModel();

            return sqlServerModel;
        }

        #endregion
    }
}
