package cosmobilis.mysql5;

import java.sql.*;
import java.util.concurrent.*;
import java.util.logging.LogManager;
import java.util.logging.Level;
import java.io.InputStream;
import java.util.Properties;
import org.json.JSONArray;
import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DatabaseWrapper {

    // Bloc static pour forcer la configuration JUL
static {
    try (InputStream is = DatabaseWrapper.class.getResourceAsStream("/logging.properties")) {
        if (is != null) {
            LogManager.getLogManager().readConfiguration(is);
            // Force le niveau du handler à FINEST (équivalent DEBUG)
            java.util.logging.ConsoleHandler handler = new java.util.logging.ConsoleHandler();
            //for debug log level:
            //handler.setLevel(java.util.logging.Level.FINEST);  // FINEST = DEBUG
            handler.setLevel(java.util.logging.Level.INFO);
            java.util.logging.Logger rootLogger = java.util.logging.LogManager.getLogManager().getLogger("");
            rootLogger.addHandler(handler);
            //for debug log level:
            //rootLogger.setLevel(java.util.logging.Level.FINEST);  // FINEST = DEBUG
            rootLogger.setLevel(java.util.logging.Level.INFO);
        } else {
            System.err.println("⚠️ Fichier logging.properties non trouvé.");
        }
    } catch (Exception e) {
        System.err.println("⚠️ Erreur lors du chargement des logs: " + e.getMessage());
    }
}


    private static final Logger log = LoggerFactory.getLogger(DatabaseWrapper.class);

    private static final int POOL_SIZE = 50;             // nb max de connexions
    private static final long TIMEOUT_SEC = 10;          // délai max d’attente
    private static final long VALIDATION_TIMEOUT_SEC = 2; // test rapide de validité
    private static final long HEARTBEAT_INTERVAL_SEC = 300; // 5 minutes

    private static BlockingQueue<Connection> pool;
    private static volatile boolean initialized = false;

    // Instance : on garde l’URL + identifiants
    private final String url;
    private final String user;
    private final String password;


    // Initialisation du pool
    private static synchronized void initPool(String url, String user, String password) throws SQLException {
        if (initialized) return;

        pool = new ArrayBlockingQueue<>(POOL_SIZE);
        for (int i = 0; i < POOL_SIZE; i++) {
            pool.add(newConnection(url, user, password));
        }
        initialized = true;

        log.info("✅ Pool MySQL initialisé avec {} connexions", POOL_SIZE);

        // Shutdown hook
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            try {
                closePool();
            } catch (SQLException e) {
                log.error("❌ Erreur à la fermeture du pool", e);
            }
        }));

        // Thread de maintenance (heartbeat SELECT 1)
        Executors.newSingleThreadScheduledExecutor().scheduleAtFixedRate(() -> {
            try {
                log.debug("▶️ Heartbeat : test des connexions du pool");
                for (Connection conn : pool) {
                    if (conn == null || conn.isClosed() || !conn.isValid((int) VALIDATION_TIMEOUT_SEC)) {
                        log.warn("⚠️ Connexion invalide détectée → recréation");
                        pool.remove(conn);
                        pool.offer(newConnection(url, user, password));
                    }
                }
            } catch (Exception e) {
                log.error("❌ Erreur dans le heartbeat", e);
            }
        }, HEARTBEAT_INTERVAL_SEC, HEARTBEAT_INTERVAL_SEC, TimeUnit.SECONDS);
    }

    private static Connection newConnection(String url, String user, String password) throws SQLException {
        // On force quelques propriétés utiles
        String jdbcUrl = url.contains("?") ? url + "&tcpKeepAlive=true&autoReconnect=true&connectTimeout=5000&socketTimeout=30000"
                                           : url + "?tcpKeepAlive=true&autoReconnect=true&connectTimeout=5000&socketTimeout=30000";
        Connection conn = DriverManager.getConnection(jdbcUrl, user, password);
        log.debug("🔗 Nouvelle connexion créée");
        return conn;
    }

    public DatabaseWrapper(String url, String user, String password) throws SQLException {
        this.url = url;
        this.user = user;
        this.password = password;
        initPool(url, user, password);
    }

    // Récupère une connexion
    private Connection borrowConnection() throws SQLException {
        try {
            Connection conn = pool.poll(TIMEOUT_SEC, TimeUnit.SECONDS);
            if (conn == null) {
                log.error("❌ Pool vide après {}s d’attente", TIMEOUT_SEC);
                throw new SQLException("Aucune connexion disponible après " + TIMEOUT_SEC + "s");
            }

            if (conn.isClosed() || !conn.isValid((int) VALIDATION_TIMEOUT_SEC)) {
                log.warn("⚠️ Connexion non valide → recréation");
                conn = newConnection(url, user, password);
            }

            log.debug("➡️ Connexion empruntée (pool restant: {}/{})", pool.size(), POOL_SIZE);
            return conn;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new SQLException("Interrompu en attendant une connexion", e);
        }
    }

    // Rend une connexion
    private void returnConnection(Connection conn) {
        if (conn != null) {
            if (!pool.offer(conn)) {
                log.warn("⚠️ Impossible de remettre la connexion (pool plein ?)");
                try {
                    conn.close();
                } catch (SQLException e) {
                    log.error("❌ Erreur en fermant la connexion rejetée", e);
                }
            } else {
                log.debug("⬅️ Connexion restituée (pool: {}/{})", pool.size(), POOL_SIZE);
            }
        }
    }

    // Ferme toutes les connexions
    public static void closePool() throws SQLException {
        if (pool != null) {
            for (Connection conn : pool) {
                if (conn != null && !conn.isClosed()) {
                    conn.close();
                }
            }
            pool.clear();
            log.info("✅ Pool fermé proprement");
        }
    }

    public void close() {
        // volontairement vide → pool gère
    }

    // UPDATE
    public int executeUpdate(String sql) throws SQLException {
        Connection conn = borrowConnection();
        try (Statement stmt = conn.createStatement()) {
            log.debug("📝 Exécution update: {}", sql);
            return stmt.executeUpdate(sql);
        } finally {
            returnConnection(conn);
        }
    }

    // QUERY → JSON
    public String executeQueryAsJson(String sql) throws SQLException {
        Connection conn = borrowConnection();
        try (Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            log.debug("🔍 Exécution query: {}", sql);

            ResultSetMetaData meta = rs.getMetaData();
            int columnCount = meta.getColumnCount();
            JSONArray arr = new JSONArray();

            while (rs.next()) {
                JSONObject obj = new JSONObject();
                for (int i = 1; i <= columnCount; i++) {
                    String colName = meta.getColumnLabel(i);
                    Object value = rs.getObject(i);

                    if (value != null && "json".equalsIgnoreCase(meta.getColumnTypeName(i))) {
                        obj.put(colName, new JSONObject(value.toString()));
                    } else {
                        obj.put(colName, value);
                    }
                }
                arr.put(obj);
            }
            return arr.toString();

        } finally {
            returnConnection(conn);
        }
    }
}