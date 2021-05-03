# Web Service

Web services are deployed for processes that are constantly running, like servers. Most deployments should fall into this category. You can choose to deploy a web service from your git repository or docker image registry. If your stack is dockerized, specify a `Dockerfile` you want to build with. If your stack is not dockerized, Porter automatically detects your stack and builds your application using [Cloud Native Buildpacks](https://buildpacks.io/).

You can choose to expose your application to external traffic on a custom domain - secured automatically by Porter with SSL certificates - or you can expose your application only to internal traffic (i.e. accessible only by applications within the cluster).

Additionally, see the **Advanced** tab to configure health check endpoints for zero down-time deployments or enable persistence on your deployments.