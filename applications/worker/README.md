# Worker

Workers are used to deploy constantly running processes that are exposed to neither external nor internal traffic. Workers have no URLs or ports - it's best suited for background processes, queuing systems, etc.

You can enable persistence on background workers by mounting external storage onto the file system of the worker. See the **Advanced** tab to configure persistence storage.