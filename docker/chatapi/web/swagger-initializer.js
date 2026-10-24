window.onload = function() {
  // Contrat servi par l'API elle-même, même origine : aucune URL en dur, l'instance (dev, prod) fixe les serveurs.
  window.ui = SwaggerUIBundle({
    url: "/openapi_dev",
    dom_id: '#swagger-ui',
    deepLinking: true,
    presets: [SwaggerUIBundle.presets.apis, SwaggerUIStandalonePreset],
    plugins: [SwaggerUIBundle.plugins.DownloadUrl],
    layout: "StandaloneLayout",
    requestInterceptor: (req) => { req.timeout = 300000; return req; }  // 5 min : un scénario peut être long
  });
};
