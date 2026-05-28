using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace ACS.Core.Sql
{
    public class SqlService : ISqlService, IDisposable
    {
        #region properties

        public bool AutoCloseConnection { get; set; }

        public int CommandTimeout { get; set; }

        public bool ConvertEmptyValuesToDbNull { get; set; } = true;

        public bool ConvertMinValuesToDbNull { get; set; } = true;

        public bool ConvertMaxValuesToDbNull { get; set; }

        public SqlConnection Connection
        {
            get => _connection;
            set
            {
                _connection = value;
                this.ConnectionString = _connection != null ? _connection.ConnectionString : string.Empty;
            }
        }

        public string ConnectionString { get; set; }

        public bool IsSingleRow { get; set; }

        public List<SqlParameter> Parameters => _parameters;

        public SqlTransaction Transaction { get; set; }

        private SqlConnection _connection;
        private List<SqlParameter> _parameters = new List<SqlParameter>();

        #endregion properties

        #region constructors

        public SqlService()
        {
            ConvertMaxValuesToDbNull = false;
        }

        public SqlService(string connectionString)
        {
            this.ConnectionString = connectionString;
            ConvertMaxValuesToDbNull = false;
        }

        #endregion constructors

        #region connection methods

        /// <summary>
        /// Connect to the database using the given ConnectionString.
        /// </summary>
        public void Connect()
        {
            try
            {
                if (_connection != null)
                {
                    if (_connection.State != ConnectionState.Open)
                        _connection.Open();
                }
                else
                {
                    if (!string.IsNullOrWhiteSpace(ConnectionString))
                    {
                        _connection = new SqlConnection(ConnectionString);
                        _connection.Open();
                    }
                    else
                    {
                        throw new InvalidOperationException("You must set a connection object or specify a connection string before calling Connect.");
                    }
                }
            }
            catch (Exception e)
            {
                try
                {
                    System.Diagnostics.EventLog.WriteEntry("SqlService", "Failure while opening sql connection: " + Connection.ConnectionString, System.Diagnostics.EventLogEntryType.Error);
                }
                catch
                { }
                throw e;
            }
        }

        /// <summary>
        /// Disconnect from the database, dispose of the connection and dispose any transaction.
        /// </summary>
        public void Disconnect()
        {
            if (Connection != null && Connection.State != ConnectionState.Closed)
                Connection.Close();

            Connection?.Dispose();

            Transaction?.Dispose();

            Transaction = null;
            Connection = null;
        }

        #endregion connection methods

        #region parameter methods

        /// <summary>
        /// Adds a SqlParameter to the SqlService object.
        /// </summary>
        /// <param name="name">A string containing the name of the parameter.</param>
        /// <param name="type">The SqlDbType for the parameter.</param>
        /// <param name="value">The value of the parameter.</param>
        //[DebuggerStepThrough]
        public SqlParameter AddParameter(string name, SqlDbType type, object value)
        {
            var sqlParameter = new SqlParameter
            {
                Direction = ParameterDirection.Input, 
                ParameterName = name, 
                SqlDbType = type, 
                Value = this.PrepareSqlValue(value)
            };

            _parameters.Add(sqlParameter);

            return sqlParameter;
        }

        /// <summary>
        /// Adds a SqlParameter to the SqlService object.
        /// </summary>
        /// <param name="name">A string containing the name of the parameter.</param>
        /// <param name="type">The SqlDbType for the parameter.</param>
        /// <param name="value">The value of the parameter.</param>
        /// <param name="direction">The parameter direction: Input, Output, InputOutput</param>
        //[DebuggerStepThrough]
        public SqlParameter AddParameter(string name, SqlDbType type, object value, ParameterDirection direction)
        {
            var sqlParameter = new SqlParameter
            {
                Direction = direction, 
                ParameterName = name, 
                SqlDbType = type, 
                Value = this.PrepareSqlValue(value)
            };

            _parameters.Add(sqlParameter);

            return sqlParameter;
        }

        /// <summary>
        /// Adds a SqlParameter to the SqlService object.
        /// </summary>
        /// <param name="name">A string containing the name of the parameter.</param>
        /// <param name="type">The SqlDbType for the parameter.</param>
        /// <param name="value">The value of the parameter.</param>
        /// <param name="size">The column length for the parameter.</param>
        /// <param name="direction">The parameter direction: Input, Output, InputOutput, ReturnValue</param>
        public SqlParameter AddParameter(string name, SqlDbType type, object value, int size, ParameterDirection direction)
        {
            var sqlParameter = new SqlParameter
            {
                Direction = direction,
                ParameterName = name,
                SqlDbType = type,
                Size = size,
                Value = this.PrepareSqlValue(value)
            };

            _parameters.Add(sqlParameter);

            return sqlParameter;
        }

        /// <summary>
        /// Adds an Output SqlParameter to the SqlService object.
        /// </summary>
        /// <param name="name">A string containing the name of the parameter.</param>
        /// <param name="type">The SqlDbType for the parameter.</param>
        public SqlParameter AddOutputParameter(string name, SqlDbType type)
        {
            var sqlParameter = new SqlParameter
            {
                Direction = ParameterDirection.Output, 
                ParameterName = name, 
                SqlDbType = type
            };

            _parameters.Add(sqlParameter);

            return sqlParameter;
        }

        /// <summary>
        /// Copy the internal parameter collection to a SqlCommand.
        /// </summary>
        /// <param name="command">The SqlCommand to copy parameters to.</param>
        private void CopyParameters(SqlCommand command)
        {
            foreach (var parameter in _parameters)
            {
                command.Parameters.Add(parameter);
            }
        }

        /// <summary>
        /// Reset the SqlService object, clearing any parameters.
        /// </summary>
        public void Reset()
        {
            Parameters?.Clear();
        }

        /// <summary>
        /// Based on the .net type, determine whether to use the incoming value
        /// or detect a default value and return a DBNull.
        /// </summary>
        /// <param name="value">The value to prepare.</param>
        /// <param name="convertZeroToDbNull">If set to true, zeroes will be converted to DBNull.</param>
        /// <returns>The prepared value.</returns>
        private object PrepareSqlValue(object value, bool convertZeroToDbNull = false)
        {
            if (value == null) return DBNull.Value;

            switch (value.GetType().ToString())
            {
                case "System.String":
                {
                    if (this.ConvertEmptyValuesToDbNull && (string) value == string.Empty)
                    {
                        return DBNull.Value;
                    }

                    return (string) value;
                }
                case "System.Guid":
                {
                    if (this.ConvertEmptyValuesToDbNull && (Guid) value == Guid.Empty)
                    {
                        return DBNull.Value;
                    }

                    return value;
                }
                case "System.DateTime":
                {
                    if ((this.ConvertMinValuesToDbNull && (DateTime) value == DateTime.MinValue)
                        || (this.ConvertMaxValuesToDbNull && (DateTime) value == DateTime.MaxValue))
                    {
                        return DBNull.Value;
                    }

                    return value;
                }
                case "System.Int16":
                {
                    if ((this.ConvertMinValuesToDbNull && (Int16) value == Int16.MinValue)
                        || (this.ConvertMaxValuesToDbNull && (Int16) value == Int16.MaxValue)
                        || (convertZeroToDbNull && (Int16) value == 0))
                    {
                        return DBNull.Value;
                    }

                    return value;
                }
                case "System.Int32":
                {
                    if ((this.ConvertMinValuesToDbNull && (Int32) value == Int32.MinValue)
                        || (this.ConvertMaxValuesToDbNull && (Int32) value == Int32.MaxValue)
                        || (convertZeroToDbNull && (Int32) value == 0))
                    {
                        return DBNull.Value;
                    }

                    return value;
                }
                case "System.Int64":
                {
                    if ((this.ConvertMinValuesToDbNull && (Int64) value == Int64.MinValue)
                        || (this.ConvertMaxValuesToDbNull && (Int64) value == Int64.MaxValue)
                        || (convertZeroToDbNull && (Int64) value == 0))
                    {
                        return DBNull.Value;
                    }

                    return value;
                }
                case "System.Single":
                {
                    if ((this.ConvertMinValuesToDbNull && (Single) value == Single.MinValue)
                        || (this.ConvertMaxValuesToDbNull && (Single) value == Single.MaxValue)
                        || (convertZeroToDbNull && (Single) value == 0))
                    {
                        return DBNull.Value;
                    }

                    return value;
                }
                case "System.Double":
                {
                    if ((this.ConvertMinValuesToDbNull && (Double) value == Double.MinValue)
                        || (this.ConvertMaxValuesToDbNull && (Double) value == Double.MaxValue)
                        || (convertZeroToDbNull && (Double) value == 0))
                    {
                        return DBNull.Value;
                    }

                    return value;
                }
                case "System.Decimal":
                {
                    if ((this.ConvertMinValuesToDbNull && (Decimal) value == Decimal.MinValue)
                        || (this.ConvertMaxValuesToDbNull && (Decimal) value == Decimal.MaxValue)
                        || (convertZeroToDbNull && (Decimal) value == 0))
                    {
                        return DBNull.Value;
                    }

                    return value;
                }
                default:
                    return value;
            }
        }

        public object GetParameterValue(string parameterName)
        {
            object returnValue = null;
            foreach (SqlParameter parameter in this.Parameters)
            {
                if (!parameter.ParameterName.Equals(parameterName))
                    continue;

                returnValue = parameter.Value;
                break;
            }
            return returnValue;
        }

        #endregion parameter methods

        #region transaction methods

        /// <summary>
        /// Begin a database transaction. You must connect to the database before a transaction can begin.
        /// </summary>
        public void BeginTransaction()
        {
            if (Connection != null)
            {
                Transaction = Connection.BeginTransaction();
            }
            else
            {
                throw new InvalidOperationException("You must have a valid connection object before calling BeginTransaction.");
            }
        }

        /// <summary>
        /// Commit an existing database transaction. You must have called BeginTransaction before you can commit one.
        /// </summary>
        public void CommitTransaction()
        {
            if (Transaction != null)
            {
                try
                {
                    Transaction.Commit();
                }
                catch
                {
                }
            }
            else
            {
                throw new InvalidOperationException("You must call BeginTransaction before calling CommitTransaction.");
            }
        }

        /// <summary>
        /// Rollback an existing database transaction. You must have called BeginTransaction before you can rollback one.
        /// </summary>
        public void RollbackTransaction()
        {
            if (Transaction != null)
            {
                try
                {
                    Transaction.Rollback();
                }
                catch
                {
                }
            }
            else
            {
                throw new InvalidOperationException("You must call BeginTransaction before calling RollbackTransaction.");
            }
        }

        #endregion transaction methods

        #region execute datatable

        public DataTable ExecuteDataTable(string sql, CommandType commandType, List<SqlParameter> parameters)
        {
            if (parameters != null)
                _parameters.AddRange(parameters);

            var sqlCommand = new SqlCommand();
            var sqlDataAdapter = new SqlDataAdapter();
            var dataTable = new DataTable();

            try
            {
                this.Connect();

                sqlCommand.CommandText = sql;
                sqlCommand.CommandTimeout = this.CommandTimeout;
                sqlCommand.CommandType = commandType;
                sqlCommand.Connection = Connection;

                if (Transaction != null)
                    sqlCommand.Transaction = Transaction;

                sqlDataAdapter.SelectCommand = sqlCommand;
                sqlDataAdapter.Fill(dataTable);

                //Parameters = sqlCommand.Parameters;

                return dataTable;
            }
            finally
            {
                sqlCommand.Dispose();
                sqlDataAdapter.Dispose();
                dataTable.Dispose();

                if (this.AutoCloseConnection)
                    this.Disconnect();
            }
        }

        public DataTable ExecuteStoredProcedureDataTable(string sql)
        {
            var sqlCommand = new SqlCommand();
            var sqlDataAdapter = new SqlDataAdapter();
            var dataTable = new DataTable();

            try
            {
                this.Connect();

                sqlCommand.CommandText = sql;
                sqlCommand.CommandTimeout = this.CommandTimeout;
                sqlCommand.CommandType = CommandType.StoredProcedure;
                sqlCommand.Connection = Connection;

                if (Transaction != null)
                    sqlCommand.Transaction = Transaction;

                this.CopyParameters(sqlCommand);

                sqlDataAdapter.SelectCommand = sqlCommand;
                sqlDataAdapter.Fill(dataTable);

                //Parameters = sqlCommand.Parameters;

                return dataTable;
            }
            finally
            {
                sqlCommand.Dispose();
                sqlDataAdapter.Dispose();
                dataTable.Dispose();

                if (this.AutoCloseConnection)
                    this.Disconnect();
            }
        }

        #endregion execute datatable

        #region execute datareader

        /// <summary>
        /// Executes a SQL query against the current connection.
        /// </summary>
        /// <param name="sql">A prepared SQL statement to execute.</param>
        /// <returns>A SqlDataReader.</returns>
        public SqlDataReader ExecuteSqlReader(string sql)
        {
            var sqlCommand = new SqlCommand();

            try
            {
                this.Connect();

                sqlCommand.CommandTimeout = this.CommandTimeout;
                sqlCommand.CommandText = sql;
                sqlCommand.Connection = _connection;
                sqlCommand.CommandType = CommandType.Text;

                if (Transaction != null)
                    sqlCommand.Transaction = Transaction;

                this.CopyParameters(sqlCommand);

                var behavior = CommandBehavior.Default;

                if (this.AutoCloseConnection) behavior = behavior | CommandBehavior.CloseConnection;
                if (IsSingleRow) behavior = behavior | CommandBehavior.SingleRow;

                var reader = sqlCommand.ExecuteReader(behavior);

                //Parameters = sqlCommand.Parameters;

                return reader;
            }
            catch (SqlException e)
            {
                if (this.AutoCloseConnection)
                    this.Disconnect();

                throw new SqlServiceException(e, sqlCommand.Parameters);
            }
            catch (Exception)
            {
                if (this.AutoCloseConnection)
                    this.Disconnect();

                throw;
            }
            finally
            {
                sqlCommand.Dispose();
            }
        }

        /// <summary>
        /// Executes a SQL query against the current connection.
        /// </summary>
        /// <param name="sql">A prepared SQL statement to execute.</param>
        /// <returns>A SqlDataReader.</returns>
        public SqlDataReader ExecuteSqlReader(string sql, out SqlCommand sqlCommand)
        {
            using (sqlCommand = new SqlCommand())  // No try on this as this would definitely be an ELMAH level error and best handled in the upper code levels as such
            {
                try
                {
                    this.Connect();

                    sqlCommand.CommandTimeout = this.CommandTimeout;
                    sqlCommand.CommandText = sql;
                    sqlCommand.Connection = _connection;
                    sqlCommand.CommandType = CommandType.Text;

                    if (Transaction != null)
                        sqlCommand.Transaction = Transaction;

                    this.CopyParameters(sqlCommand);

                    var behavior = CommandBehavior.Default;

                    if (this.AutoCloseConnection) behavior = behavior | CommandBehavior.CloseConnection;
                    if (IsSingleRow) behavior = behavior | CommandBehavior.SingleRow;

                    var reader = sqlCommand.ExecuteReader(behavior);

                    return reader;
                }
                catch (SqlException e)
                {
                    if (this.AutoCloseConnection)
                        this.Disconnect();

                    throw new SqlServiceException(e, sqlCommand.Parameters);
                }
                catch (Exception)
                {
                    if (this.AutoCloseConnection)
                        this.Disconnect();

                    throw;
                }
            }
        }

        /// <summary>
        /// Executes the named stored procedure against the current connection.
        /// </summary>
        /// <param name="procedureName">A string containing the name of the stored procedure to execute.</param>
        /// <returns>A SqlDataReader.</returns>
        public SqlDataReader ExecuteStoredProcedureReader(string procedureName)
        {
            var sqlCommand = new SqlCommand();

            try
            {
                this.Connect();

                sqlCommand.CommandTimeout = this.CommandTimeout;
                sqlCommand.CommandText = procedureName;
                sqlCommand.CommandType = CommandType.StoredProcedure;
                sqlCommand.Connection = _connection;

                if (Transaction != null)
                    sqlCommand.Transaction = Transaction;

                this.CopyParameters(sqlCommand);

                var behavior = CommandBehavior.Default;

                if (this.AutoCloseConnection) 
                    behavior = behavior | CommandBehavior.CloseConnection;

                if (IsSingleRow) 
                    behavior = behavior | CommandBehavior.SingleRow;

                var reader = sqlCommand.ExecuteReader(behavior);

                //Parameters = sqlCommand.Parameters;

                return reader;
            }
            catch (SqlException e)
            {
                if (this.AutoCloseConnection)
                    this.Disconnect();

                throw new SqlServiceException(e, sqlCommand.Parameters);
            }
            catch (Exception)
            {
                if (this.AutoCloseConnection)
                    this.Disconnect();

                throw;
            }
            finally
            {
                sqlCommand.Dispose();
            }
        }

        #endregion execute datareader

        #region execute stored procedure

        /// <summary>
        /// Executes the named stored procedure against the current connection.
        /// </summary>
        /// <param name="procedureName">A string containing the name of the stored procedure to execute.</param>
        /// <returns> The number of affected rows by the operation. </returns>
        public int ExecuteStoredProcedure(string procedureName)
        {
            var cmd = new SqlCommand();

            try
            {
                this.Connect();

                cmd.CommandTimeout = this.CommandTimeout;
                cmd.CommandText = procedureName;
                cmd.Connection = _connection;
                cmd.CommandType = CommandType.StoredProcedure;

                if (Transaction != null)
                    cmd.Transaction = Transaction;

                this.CopyParameters(cmd);

                return cmd.ExecuteNonQuery();
            }
            catch (SqlException e)
            {
                if (this.AutoCloseConnection)
                    this.Disconnect();

                throw new SqlServiceException(e, cmd.Parameters);
            }
            catch (Exception)
            {
                if (this.AutoCloseConnection)
                    this.Disconnect();

                throw;
            }
            finally
            {
                cmd.Dispose();

                if (this.AutoCloseConnection)
                    this.Disconnect();
            }
        }

        #endregion

        #region idisposable members

        /// <summary>
        /// Dispose of the connection and any transaction.
        /// </summary>
        public void Dispose()
        {
            Disconnect();
        }

        #endregion Idisposable members
    }
}
