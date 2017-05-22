import oracle.jdbc.pool.OracleDataSource;

import java.io.Closeable;
import java.io.PrintStream;
import java.sql.*;
import java.util.Properties;

/**
 * Created by piotr on 22.05.2017.
 */
public class ButchersDB implements Closeable {


    /**
     * Main method
     * @param args parameter is not used
     * @throws Exception thrown whenever the DB reports an error.
     */
    public static void main(String [] args) throws Exception{



            try (
                    ButchersDB db = new ButchersDB()
            )
            {
                ColorfulStream.out.println("Before running program");
                db.select();

                db.insert();
                ColorfulStream.out.println("After insert");
                db.select();

                db.update();
                ColorfulStream.out.println("After update");
                db.select();


                db.delete();
                ColorfulStream.out.println("After delete");
                db.select();
            }
            catch (SQLException e){
                System.err.println(e);
                System.exit(1);
            }


    }


    /**
     * Default constructor. Connects to the DB.
     * @throws SQLException when connection was not successful.
     */
    public ButchersDB () throws SQLException{

        connection_ = getConnection();
        connection_.setAutoCommit(true);

        statement_ = connection_.createStatement();

    }


    /**
     * Inserts two new records to the DB
     * @throws SQLException thrown whenever the DB reports an error.
     */
    public void insert() throws SQLException{


        try (
            PreparedStatement statement = connection_.prepareStatement("INSERT INTO DEPARTMENTS VALUES (NULL, ?,?)")
        )
        {
            // "Custom1, 1"
            statement.setString(1, "Custom1");
            statement.setInt(2, 1);
            statement.executeUpdate();

            // "Custom2, 2"
            statement.setString(1, "Custom2");
            statement.setInt(2, 2);
            statement.executeUpdate();

        }
    }

    /**
     * Updates two records. Changes departments' managers.
     * @throws SQLException thrown whenever the DB reports an error.
     */
    public void update () throws SQLException {
        try (
                PreparedStatement statement = connection_.prepareStatement("UPDATE DEPARTMENTS SET MANAGER = ? WHERE ID = ?")
        )
        {
            statement.setInt(1, 1);
            statement.setInt(2, 1);
            statement.executeUpdate();

            statement.setInt(1, 1);
            statement.setInt(2, 2);
            statement.executeUpdate();

        }
    }

    /**
     * Deletes records added by {@link #insert() ButchersDB.insert()} method
     * @throws SQLException thrown whenever the DB reports an error.
     */
    public void delete () throws SQLException{
        try (
                PreparedStatement statement = connection_.prepareStatement("DELETE FROM DEPARTMENTS WHERE NAME = ?")
        )
        {
            statement.setString(1, "Custom1");
            statement.executeUpdate();

            statement.setString(1, "Custom2");
            statement.executeUpdate();
        }
    }


    /**
     * Retrieves data connected with departments from the DB.
     * @throws SQLException whenever an error occurs.
     */
    public void select() throws SQLException{

        try (
                ResultSet resultSet = statement_.executeQuery("SELECT d.ID, d.NAME, e.NAME, e.SURNAME FROM DEPARTMENTS d LEFT JOIN EMPLOYEES e ON d.MANAGER = e.ID ORDER BY d.ID");
        ) {

            while (resultSet.next()) {
                System.out.println(
                        resultSet.getString(1) + ' '
                                + resultSet.getString(2) + " is managed by "
                                + resultSet.getString(3) + ' '
                                + resultSet.getString(4)
                );
            }
        }

    }

    /**
     * Closes connection with DB.
     */
    public void close() {
        try{
            statement_.close();
            connection_.close();
        }
        catch (SQLException e){
           System.err.println(e);
           System.exit(1);
        }

    }

    private Connection getConnection() throws SQLException {


        Properties connectionProperties = new Properties();

        connectionProperties.put("user", "pzelazko");
        connectionProperties.put("password", "pzelazko");

        OracleDataSource dataSource =  new OracleDataSource();
        dataSource.setURL("jdbc:oracle:thin:@ora3.elka.pw.edu.pl:1521:ora3inf");


        return dataSource.getConnection(user, password);


    }

    private static class ColorfulStream extends PrintStream {
        public ColorfulStream(){
            super(System.out);
        }

        public void println(String string){
            super.print((char)27 + "[34m");
            super.print(string);
            super.println((char)27 + "[0m");
        }

        public static final ColorfulStream out = new ColorfulStream();

    }

    private final Connection connection_;
    private final Statement statement_;

    private static final String user = "pzelazko";
    private static final String password = user;

}
