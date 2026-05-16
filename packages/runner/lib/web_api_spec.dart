import 'dart:convert';
import 'package:openapi_spec/openapi_spec.dart';

/// Helper class to generate OpenAPI 3.0 documentation for the Bot Creator Runner API.
class RunnerApiSpec {
  RunnerApiSpec({required this.version});

  final String version;

  final Map<String, PathItem> _paths = {};

  void addRoute({
    required String path,
    required String method,
    String? summary,
    String? description,
    bool requiresAuth = true,
    List<Parameter>? parameters,
    RequestBody? requestBody,
    Map<String, Response>? responses,
  }) {
    // Normalize path for OpenAPI (replace :id with {id})
    final openApiPath = path.replaceAllMapped(RegExp(r':(\w+)'), (m) => '{${m.group(1)}}');

    final operation = Operation(
      summary: summary,
      description: description,
      parameters: [
        if (requiresAuth)
          Parameter.header(
            name: 'Authorization',
            description: 'Bearer token',
            schema: Schema.string(),
          ),
        ...?parameters,
        if (path.contains(':id'))
          Parameter.path(
            name: 'id',
            schema: Schema.string(),
          ),
        if (path.contains(':pathKey'))
          Parameter.path(
            name: 'pathKey',
            schema: Schema.string(),
          ),
      ],
      requestBody: requestBody,
      responses: responses ?? {
        '200': Response(description: 'Successful response'),
        '401': Response(description: 'Unauthorized'),
        '404': Response(description: 'Not Found'),
      },
    );

    final pathItem = _paths[openApiPath] ?? PathItem();
    
    switch (method.toLowerCase()) {
      case 'get':
        _paths[openApiPath] = pathItem.copyWith(get: operation);
        break;
      case 'post':
        _paths[openApiPath] = pathItem.copyWith(post: operation);
        break;
      case 'put':
        _paths[openApiPath] = pathItem.copyWith(put: operation);
        break;
      case 'delete':
        _paths[openApiPath] = pathItem.copyWith(delete: operation);
        break;
    }
  }

  /// Helper to create a JSON request body schema.
  static RequestBody jsonRequest(Map<String, Schema> properties, {bool required = true, String? description}) {
    return RequestBody(
      description: description,
      required: required,
      content: {
        'application/json': MediaType(
          schema: Schema.object(properties: properties),
        ),
      },
    );
  }

  /// Helper to create a JSON response schema.
  static Response jsonResponse(String description, Map<String, Schema> properties) {
    return Response(
      description: description,
      content: {
        'application/json': MediaType(
          schema: Schema.object(properties: properties),
        ),
      },
    );
  }

  OpenApi build() {
    return OpenApi(
      info: Info(
        title: 'Bot Creator Runner API',
        version: version,
        description: 'REST API used by the Bot Creator app to sync/start/stop bots.',
      ),
      paths: _paths,
      components: Components(
        securitySchemes: {
          'bearerAuth': SecurityScheme.http(
            scheme: HttpSecurityScheme.bearer,
            bearerFormat: 'JWT',
          ),
        },
      ),
    );
  }

  String generateJson() {
    return jsonEncode(build().toJson());
  }

  String generateHtml() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Bot Creator Runner API - Swagger UI</title>
  <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css" />
  <link rel="icon" type="image/png" href="https://unpkg.com/swagger-ui-dist@5/favicon-32x32.png" sizes="32x32" />
  <link rel="icon" type="image/png" href="https://unpkg.com/swagger-ui-dist@5/favicon-16x16.png" sizes="16x16" />
  <style>
    html { box-sizing: border-box; overflow: -平衡-y; }
    *, *:before, *:after { box-sizing: inherit; }
    body { margin: 0; background: #fafafa; }
  </style>
</head>
<body>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js" charset="UTF-8"></script>
  <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-standalone-preset.js" charset="UTF-8"></script>
  <script>
    window.onload = function() {
      const ui = SwaggerUIBundle({
        url: "/swagger.json",
        dom_id: '#swagger-ui',
        deepLinking: true,
        presets: [
          SwaggerUIBundle.presets.apis,
          SwaggerUIStandalonePreset
        ],
        plugins: [
          SwaggerUIBundle.plugins.DownloadUrl
        ],
        layout: "BaseLayout"
      });
      window.ui = ui;
    };
  </script>
</body>
</html>
''';
  }
}
