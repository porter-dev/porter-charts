# HTTPS Issuer

This is a chart that deploys a ClusterIssuer that issues https certificates per ingress using cert-manager and lets-encrypt.

Please make sure you have set the A record in your DNS provider that points to the IP address of your load balancer. Note that DNS propagation takes about 15 minutes on average.
We recommend that you deploy this chart after ensuring that DNS has been properly propagated. Once the HTTPS issuer has been deployed, you may use the Docker template to deploy any image on custom domain, secured with HTTPS.

If you have any questions about this template you can reach us at [contact@getporter.dev](mailto:contact@getporter.dev).
