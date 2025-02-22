/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.apache.hop.databases.derby;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.apache.hop.core.database.DatabaseMeta;
import org.apache.hop.core.row.value.ValueMetaBigNumber;
import org.apache.hop.core.row.value.ValueMetaBinary;
import org.apache.hop.core.row.value.ValueMetaBoolean;
import org.apache.hop.core.row.value.ValueMetaDate;
import org.apache.hop.core.row.value.ValueMetaInteger;
import org.apache.hop.core.row.value.ValueMetaInternetAddress;
import org.apache.hop.core.row.value.ValueMetaNumber;
import org.apache.hop.core.row.value.ValueMetaString;
import org.apache.hop.core.row.value.ValueMetaTimestamp;
import org.junit.Before;
import org.junit.Test;

public class DerbyDatabaseMetaTest {
  private DerbyDatabaseMeta nativeMeta;

  @Before
  public void setupBefore() {
    nativeMeta = new DerbyDatabaseMeta();
    nativeMeta.setAccessType(DatabaseMeta.TYPE_ACCESS_NATIVE);
  }

  @Test
  public void testSettings() {
    assertArrayEquals(new int[] {DatabaseMeta.TYPE_ACCESS_NATIVE}, nativeMeta.getAccessTypeList());
    assertEquals(0, nativeMeta.getNotFoundTK(true));
    assertEquals(0, nativeMeta.getNotFoundTK(false));

    assertEquals("org.apache.derby.jdbc.EmbeddedDriver", nativeMeta.getDriverClass());
    nativeMeta.setHostname("FOOHOST");
    assertEquals("org.apache.derby.client.ClientAutoloadedDriver", nativeMeta.getDriverClass());

    assertEquals("jdbc:derby://FOO/WIBBLE", nativeMeta.getURL("FOO", "", "WIBBLE"));
    assertEquals("jdbc:derby://FOO:BAR/WIBBLE", nativeMeta.getURL("FOO", "BAR", "WIBBLE"));
    assertEquals("jdbc:derby:FOO", nativeMeta.getURL("", "", "FOO"));

    assertTrue(nativeMeta.isFetchSizeSupported());
    assertFalse(nativeMeta.isSupportsBitmapIndex());
    assertEquals(1527, nativeMeta.getDefaultDatabasePort());
    assertFalse(nativeMeta.isSupportsGetBlob());
    assertEquals(
        "http://db.apache.org/derby/papers/DerbyClientSpec.html",
        nativeMeta.getExtraOptionsHelpText());
    assertArrayEquals(
        new String[] {
          "ADD",
          "ALL",
          "ALLOCATE",
          "ALTER",
          "AND",
          "ANY",
          "ARE",
          "AS",
          "ASC",
          "ASSERTION",
          "AT",
          "AUTHORIZATION",
          "AVG",
          "BEGIN",
          "BETWEEN",
          "BIT",
          "BOOLEAN",
          "BOTH",
          "BY",
          "CALL",
          "CASCADE",
          "CASCADED",
          "CASE",
          "CAST",
          "CHAR",
          "CHARACTER",
          "CHECK",
          "CLOSE",
          "COLLATE",
          "COLLATION",
          "COLUMN",
          "COMMIT",
          "CONNECT",
          "CONNECTION",
          "CONSTRAINT",
          "CONSTRAINTS",
          "CONTINUE",
          "CONVERT",
          "CORRESPONDING",
          "COUNT",
          "CREATE",
          "CURRENT",
          "CURRENT_DATE",
          "CURRENT_TIME",
          "CURRENT_TIMESTAMP",
          "CURRENT_USER",
          "CURSOR",
          "DEALLOCATE",
          "DEC",
          "DECIMAL",
          "DECLARE",
          "DEFERRABLE",
          "DEFERRED",
          "DELETE",
          "DESC",
          "DESCRIBE",
          "DIAGNOSTICS",
          "DISCONNECT",
          "DISTINCT",
          "DOUBLE",
          "DROP",
          "ELSE",
          "END",
          "ENDEXEC",
          "ESCAPE",
          "EXCEPT",
          "EXCEPTION",
          "EXEC",
          "EXECUTE",
          "EXISTS",
          "EXPLAIN",
          "EXTERNAL",
          "FALSE",
          "FETCH",
          "FIRST",
          "FLOAT",
          "FOR",
          "FOREIGN",
          "FOUND",
          "FROM",
          "FULL",
          "FUNCTION",
          "GET",
          "GET_CURRENT_CONNECTION",
          "GLOBAL",
          "GO",
          "GOTO",
          "GRANT",
          "GROUP",
          "HAVING",
          "HOUR",
          "IDENTITY",
          "IMMEDIATE",
          "IN",
          "INDICATOR",
          "INITIALLY",
          "INNER",
          "INOUT",
          "INPUT",
          "INSENSITIVE",
          "INSERT",
          "INT",
          "INTEGER",
          "INTERSECT",
          "INTO",
          "IS",
          "ISOLATION",
          "JOIN",
          "KEY",
          "LAST",
          "LEFT",
          "LIKE",
          "LONGINT",
          "LOWER",
          "LTRIM",
          "MATCH",
          "MAX",
          "MIN",
          "MINUTE",
          "NATIONAL",
          "NATURAL",
          "NCHAR",
          "NVARCHAR",
          "NEXT",
          "NO",
          "NOT",
          "NULL",
          "NULLIF",
          "NUMERIC",
          "OF",
          "ON",
          "ONLY",
          "OPEN",
          "OPTION",
          "OR",
          "ORDER",
          "OUT",
          "OUTER",
          "OUTPUT",
          "OVERLAPS",
          "PAD",
          "PARTIAL",
          "PREPARE",
          "PRESERVE",
          "PRIMARY",
          "PRIOR",
          "PRIVILEGES",
          "PROCEDURE",
          "PUBLIC",
          "READ",
          "REAL",
          "REFERENCES",
          "RELATIVE",
          "RESTRICT",
          "REVOKE",
          "RIGHT",
          "ROLLBACK",
          "ROWS",
          "RTRIM",
          "SCHEMA",
          "SCROLL",
          "SECOND",
          "SELECT",
          "SESSION_USER",
          "SET",
          "SMALLINT",
          "SOME",
          "SPACE",
          "SQL",
          "SQLCODE",
          "SQLERROR",
          "SQLSTATE",
          "SUBSTR",
          "SUBSTRING",
          "SUM",
          "SYSTEM_USER",
          "TABLE",
          "TEMPORARY",
          "TIMEZONE_HOUR",
          "TIMEZONE_MINUTE",
          "TO",
          "TRAILING",
          "TRANSACTION",
          "TRANSLATE",
          "TRANSLATION",
          "TRUE",
          "UNION",
          "UNIQUE",
          "UNKNOWN",
          "UPDATE",
          "UPPER",
          "USER",
          "USING",
          "VALUES",
          "VARCHAR",
          "VARYING",
          "VIEW",
          "WHENEVER",
          "WHERE",
          "WITH",
          "WORK",
          "WRITE",
          "XML",
          "XMLEXISTS",
          "XMLPARSE",
          "XMLSERIALIZE",
          "YEAR"
        },
        nativeMeta.getReservedWords());
  }

  @Test
  public void testSqlStatements() {
    assertEquals("DELETE FROM FOO", nativeMeta.getTruncateTableStatement("FOO"));

    assertEquals(
        "ALTER TABLE FOO ADD BAR TIMESTAMP",
        nativeMeta.getAddColumnStatement("FOO", new ValueMetaDate("BAR"), "", false, "", false));
    assertEquals(
        "ALTER TABLE FOO ADD BAR TIMESTAMP",
        nativeMeta.getAddColumnStatement(
            "FOO", new ValueMetaTimestamp("BAR"), "", false, "", false));

    assertEquals(
        "ALTER TABLE FOO ADD BAR CHAR(1)",
        nativeMeta.getAddColumnStatement("FOO", new ValueMetaBoolean("BAR"), "", false, "", false));

    assertEquals(
        "ALTER TABLE FOO ADD BAR DOUBLE",
        nativeMeta.getAddColumnStatement(
            "FOO", new ValueMetaNumber("BAR", 10, 0), "", false, "", false));

    assertEquals(
        "ALTER TABLE FOO ADD BAR DECIMAL(10,16)",
        nativeMeta.getAddColumnStatement(
            "FOO", new ValueMetaBigNumber("BAR", 10, 0), "", false, "", false));

    assertEquals(
        "ALTER TABLE FOO ADD BAR BIGINT",
        nativeMeta.getAddColumnStatement(
            "FOO", new ValueMetaInteger("BAR", 10, 0), "", false, "", false));

    assertEquals(
        "ALTER TABLE FOO ADD BAR TINYINT",
        nativeMeta.getAddColumnStatement(
            "FOO", new ValueMetaInteger("BAR", 2, 0), "", false, "", false));

    assertEquals(
        "ALTER TABLE FOO ADD BAR DOUBLE",
        nativeMeta.getAddColumnStatement(
            "FOO", new ValueMetaNumber("BAR", 5, 0), "", false, "", false));

    assertEquals(
        "ALTER TABLE FOO ADD BAR DOUBLE",
        nativeMeta.getAddColumnStatement(
            "FOO", new ValueMetaNumber("BAR", 10, 3), "", false, "", false));

    assertEquals(
        "ALTER TABLE FOO ADD BAR DECIMAL(10,3)",
        nativeMeta.getAddColumnStatement(
            "FOO", new ValueMetaBigNumber("BAR", 10, 3), "", false, "", false));

    assertEquals(
        "ALTER TABLE FOO ADD BAR DECIMAL(21,4)",
        nativeMeta.getAddColumnStatement(
            "FOO", new ValueMetaBigNumber("BAR", 21, 4), "", false, "", false));

    assertEquals(
        "ALTER TABLE FOO ADD BAR CLOB",
        nativeMeta.getAddColumnStatement(
            "FOO",
            new ValueMetaString("BAR", nativeMeta.getMaxVARCHARLength() + 2, 0),
            "",
            false,
            "",
            false));

    assertEquals(
        "ALTER TABLE FOO ADD BAR BLOB",
        nativeMeta.getAddColumnStatement(
            "FOO",
            new ValueMetaBinary("BAR", nativeMeta.getMaxVARCHARLength() + 2, 0),
            "",
            false,
            "",
            false));

    assertEquals(
        "ALTER TABLE FOO ADD BAR BLOB",
        nativeMeta.getAddColumnStatement("FOO", new ValueMetaBinary("BAR"), "", false, "", false));

    assertEquals(
        "ALTER TABLE FOO ADD BAR BLOB",
        nativeMeta.getAddColumnStatement(
            "FOO", new ValueMetaBinary("BAR", 200, 0), "", false, "", false));

    assertEquals(
        "ALTER TABLE FOO ADD BAR VARCHAR(15)",
        nativeMeta.getAddColumnStatement(
            "FOO", new ValueMetaString("BAR", 15, 0), "", false, "", false));

    assertEquals(
        "ALTER TABLE FOO ADD BAR DOUBLE",
        nativeMeta.getAddColumnStatement(
            "FOO", new ValueMetaNumber("BAR", 10, -7), "", false, "", false));

    assertEquals(
        "ALTER TABLE FOO ADD BAR DECIMAL(22,7)",
        nativeMeta.getAddColumnStatement(
            "FOO", new ValueMetaBigNumber("BAR", 22, 7), "", false, "", false));
    assertEquals(
        "ALTER TABLE FOO ADD BAR DOUBLE",
        nativeMeta.getAddColumnStatement(
            "FOO", new ValueMetaNumber("BAR", -10, 7), "", false, "", false));
    assertEquals(
        "ALTER TABLE FOO ADD BAR DOUBLE",
        nativeMeta.getAddColumnStatement(
            "FOO", new ValueMetaNumber("BAR", 5, 7), "", false, "", false));
    assertEquals(
        "ALTER TABLE FOO ADD BAR UNKNOWN",
        nativeMeta.getAddColumnStatement(
            "FOO", new ValueMetaInternetAddress("BAR"), "", false, "", false));

    assertEquals(
        "ALTER TABLE FOO ADD BAR BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 0, INCREMENT BY 1)",
        nativeMeta.getAddColumnStatement(
            "FOO", new ValueMetaInteger("BAR"), "BAR", true, "", false));

    assertEquals(
        "ALTER TABLE FOO ADD BAR BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 0, INCREMENT BY 1)",
        nativeMeta.getAddColumnStatement(
            "FOO", new ValueMetaNumber("BAR", 26, 8), "BAR", true, "", false));

    String lineSep = System.getProperty("line.separator");

    assertEquals(
        "ALTER TABLE FOO DROP BAR" + lineSep,
        nativeMeta.getDropColumnStatement(
            "FOO", new ValueMetaString("BAR", 15, 0), "", false, "", true));

    assertEquals(
        "ALTER TABLE FOO ALTER BAR VARCHAR(15)",
        nativeMeta.getModifyColumnStatement(
            "FOO", new ValueMetaString("BAR", 15, 0), "", false, "", true));

    assertEquals(
        "insert into FOO(FOOVERSION) values (1)",
        nativeMeta.getSqlInsertAutoIncUnknownDimensionRow("FOO", "FOOKEY", "FOOVERSION"));
  }
}
