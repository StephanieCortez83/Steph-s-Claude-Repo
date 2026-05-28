using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Sql
{
    public class SqlServiceException : SystemException
    {
        #region internals

        private readonly SqlException _sqlException;

        #endregion

        #region interface

        public byte Class => _sqlException.Class;

        public SqlErrorCollection Errors => _sqlException.Errors;

        public int LineNumber => _sqlException.LineNumber;

        public override string Message => _sqlException.Message;

        public int Number => _sqlException.Number;

        public string Procedure => _sqlException.Procedure;

        public string Server => _sqlException.Server;

        public override string Source => _sqlException.Source;

        public byte State => _sqlException.State;

        public SqlParameterCollection Parameters { get; }

        #endregion

        #region constructor

        public SqlServiceException(SqlException e, SqlParameterCollection sqlParameters)
        {
            _sqlException = e;
            Parameters = sqlParameters;
        }

        #endregion
    }
}
