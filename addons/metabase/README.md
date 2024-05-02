Metabase is an open source business intelligence tool. It lets you ask questions about your data, and displays answers in formats that make sense, whether that’s a bar graph or a detailed table.

Your questions can be saved for later, making it easy to come back to them, or you can group questions into great looking dashboards. Metabase also makes it easy to share questions and dashboards with the rest of your team.

## Prerequisites
Please note that the Metabase addon uses an ephemeral in-memory database which is **not** recommended for production workloads. We recommend connecting Metabase to en external database which will ensure your dashbaords and metadata is accessible even if Metabase is restarted. In order to configure an external database, please use the following environment variables in the `Environment` section of the addon(in the next step):

1. `MB_DB_TYPE`
2. `MB_DB_DBNAME` 
3. `MB_DB_PORT`
4. `MB_DB_USER`
5. `MB_DB_PASS`
6. `MB_DB_HOST` 
