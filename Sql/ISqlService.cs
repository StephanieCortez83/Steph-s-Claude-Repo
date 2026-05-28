using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace ACS.Core.Sql
{
    public interface ISqlService
    {
        #region properties

        bool AutoCloseConnection { get; set; }

        string ConnectionString { get; set; }

        SqlConnection Connection { get; set; }

        List<SqlParameter> Parameters { get; }

        SqlTransaction Transaction { get; set; }

        #endregion

        #region methods

        #region connection methods

        void Connect();

        void Disconnect();

        void Dispose();
        
        #endregion connection methods

        #region transaction methods

        void BeginTransaction();

        void CommitTransaction();

        void RollbackTransaction();

        #endregion transaction methods

        #region parameter methods

        SqlParameter AddParameter(string name, SqlDbType type, object value);

        SqlParameter AddOutputParameter(string name, SqlDbType type);

        void Reset();

        object GetParameterValue(string parameterName);

        #endregion

        #region datareader methods

        /// <summary>
        /// Executes a SQL query against the current connection.
        /// </summary>
        /// <param name="sql">A prepared SQL statement to execute.</param>
        /// <returns>A SqlDataReader.</returns>
        SqlDataReader ExecuteSqlReader(string sql);

        /// <summary>
        /// Executes a SQL query against the current connection.
        /// </summary>
        /// <param name="sql">A prepared SQL statement to execute.</param>
        /// <returns>A SqlDataReader.</returns>
        SqlDataReader ExecuteSqlReader(string sql, out SqlCommand sqlCommand);

        /// <summary>
        /// Executes the named stored procedure against the current connection.
        /// </summary>
        /// <param name="procedureName">A string containing the name of the stored procedure to execute.</param>
        /// <returns>A SqlDataReader.</returns>
        SqlDataReader ExecuteStoredProcedureReader(string procedureName);

        #endregion

        #region non query methods

        /// <summary>
        /// Executes the named stored procedure against the current connection.
        /// </summary>
        /// <param name="procedureName">A string containing the name of the stored procedure to execute.</param>
        /// <returns> The number of affected rows by the operation. </returns>
        int ExecuteStoredProcedure(string procedureName);

        #endregion

        #endregion
    }
}
