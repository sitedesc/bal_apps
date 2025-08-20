package cosmobilis.mysql5;

import java.sql.*;
import org.json.JSONArray;
import org.json.JSONObject;

public class DatabaseWrapper {
    private Connection connection;

    public DatabaseWrapper(String url, String user, String password) throws SQLException {
        this.connection = DriverManager.getConnection(url, user, password);
    }

    public void close() throws SQLException {
        if (connection != null && !connection.isClosed()) {
            connection.close();
        }
    }

    public int executeUpdate(String sql) throws SQLException {
        Statement stmt = connection.createStatement();
        int rows = stmt.executeUpdate(sql);
        stmt.close();
        return rows;
    }

    // Nouvelle méthode : SELECT → JSON string
    public String executeQueryAsJson(String sql) throws SQLException {
        Statement stmt = connection.createStatement();
        ResultSet rs = stmt.executeQuery(sql);
        ResultSetMetaData meta = rs.getMetaData();
        int columnCount = meta.getColumnCount();

        JSONArray arr = new JSONArray();

        while (rs.next()) {
            JSONObject obj = new JSONObject();
            for (int i = 1; i <= columnCount; i++) {
                String colName = meta.getColumnLabel(i);
                Object value = rs.getObject(i);

                // Gestion spéciale pour JSON MySQL (retourne déjà un String JSON)
                if (value != null && "json".equalsIgnoreCase(meta.getColumnTypeName(i))) {
                    obj.put(colName, new JSONObject(value.toString()));
                } else {
                    obj.put(colName, value);
                }
            }
            arr.put(obj);
        }

        rs.close();
        stmt.close();
        return arr.toString(); // Retourne un tableau JSON
    }
}
