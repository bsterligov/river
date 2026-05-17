//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DefaultApi {
  DefaultApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'GET /health' operation and returns the [Response].
  Future<Response> getHealthWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/health';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  Future<void> getHealth() async {
    final response = await getHealthWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'GET /v1/logs' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] filter:
  ///   Filter expression
  ///
  /// * [String] from:
  ///   Start time (RFC 3339)
  ///
  /// * [String] to:
  ///   End time (RFC 3339)
  ///
  /// * [int] limit:
  ///   Max rows (default 100, max 1000)
  Future<Response> getLogsWithHttpInfo({ String? filter, String? from, String? to, int? limit, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/logs';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (filter != null) {
      queryParams.addAll(_queryParams('', 'filter', filter));
    }
    if (from != null) {
      queryParams.addAll(_queryParams('', 'from', from));
    }
    if (to != null) {
      queryParams.addAll(_queryParams('', 'to', to));
    }
    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Parameters:
  ///
  /// * [String] filter:
  ///   Filter expression
  ///
  /// * [String] from:
  ///   Start time (RFC 3339)
  ///
  /// * [String] to:
  ///   End time (RFC 3339)
  ///
  /// * [int] limit:
  ///   Max rows (default 100, max 1000)
  Future<List<LogRow>?> getLogs({ String? filter, String? from, String? to, int? limit, }) async {
    final response = await getLogsWithHttpInfo( filter: filter, from: from, to: to, limit: limit, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<LogRow>') as List)
        .cast<LogRow>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /v1/logs/facets' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] filter:
  ///   Filter expression
  ///
  /// * [String] from:
  ///   Start time (RFC 3339)
  ///
  /// * [String] to:
  ///   End time (RFC 3339)
  Future<Response> getLogsFacetsWithHttpInfo({ String? filter, String? from, String? to, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/logs/facets';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (filter != null) {
      queryParams.addAll(_queryParams('', 'filter', filter));
    }
    if (from != null) {
      queryParams.addAll(_queryParams('', 'from', from));
    }
    if (to != null) {
      queryParams.addAll(_queryParams('', 'to', to));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Parameters:
  ///
  /// * [String] filter:
  ///   Filter expression
  ///
  /// * [String] from:
  ///   Start time (RFC 3339)
  ///
  /// * [String] to:
  ///   End time (RFC 3339)
  Future<List<FacetField>?> getLogsFacets({ String? filter, String? from, String? to, }) async {
    final response = await getLogsFacetsWithHttpInfo( filter: filter, from: from, to: to, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<FacetField>') as List)
        .cast<FacetField>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /v1/logs/histogram' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] filter:
  ///   Filter expression
  ///
  /// * [String] from:
  ///   Start time (RFC 3339)
  ///
  /// * [String] to:
  ///   End time (RFC 3339)
  ///
  /// * [String] step:
  ///   Bucket width (e.g. 60s, 5m); auto-selected if omitted
  Future<Response> getLogsHistogramWithHttpInfo({ String? filter, String? from, String? to, String? step, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/logs/histogram';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (filter != null) {
      queryParams.addAll(_queryParams('', 'filter', filter));
    }
    if (from != null) {
      queryParams.addAll(_queryParams('', 'from', from));
    }
    if (to != null) {
      queryParams.addAll(_queryParams('', 'to', to));
    }
    if (step != null) {
      queryParams.addAll(_queryParams('', 'step', step));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Parameters:
  ///
  /// * [String] filter:
  ///   Filter expression
  ///
  /// * [String] from:
  ///   Start time (RFC 3339)
  ///
  /// * [String] to:
  ///   End time (RFC 3339)
  ///
  /// * [String] step:
  ///   Bucket width (e.g. 60s, 5m); auto-selected if omitted
  Future<List<HistogramBucket>?> getLogsHistogram({ String? filter, String? from, String? to, String? step, }) async {
    final response = await getLogsHistogramWithHttpInfo( filter: filter, from: from, to: to, step: step, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<HistogramBucket>') as List)
        .cast<HistogramBucket>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /v1/metrics' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] filter:
  ///   Filter expression
  ///
  /// * [String] from:
  ///   Start time (RFC 3339)
  ///
  /// * [String] to:
  ///   End time (RFC 3339)
  ///
  /// * [String] step:
  ///   Query step (e.g. 60s, 5m)
  Future<Response> getMetricsWithHttpInfo({ String? filter, String? from, String? to, String? step, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/metrics';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (filter != null) {
      queryParams.addAll(_queryParams('', 'filter', filter));
    }
    if (from != null) {
      queryParams.addAll(_queryParams('', 'from', from));
    }
    if (to != null) {
      queryParams.addAll(_queryParams('', 'to', to));
    }
    if (step != null) {
      queryParams.addAll(_queryParams('', 'step', step));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Parameters:
  ///
  /// * [String] filter:
  ///   Filter expression
  ///
  /// * [String] from:
  ///   Start time (RFC 3339)
  ///
  /// * [String] to:
  ///   End time (RFC 3339)
  ///
  /// * [String] step:
  ///   Query step (e.g. 60s, 5m)
  Future<List<MetricPoint>?> getMetrics({ String? filter, String? from, String? to, String? step, }) async {
    final response = await getMetricsWithHttpInfo( filter: filter, from: from, to: to, step: step, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<MetricPoint>') as List)
        .cast<MetricPoint>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /v1/metrics/names' operation and returns the [Response].
  Future<Response> getMetricNamesWithHttpInfo() async {
    const path = r'/v1/metrics/names';
    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};
    final contentTypes = <String>[];
    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      null,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Returns a list of all metric names.
  Future<List<String>?> getMetricNames() async {
    final response = await getMetricNamesWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<String>') as List)
        .cast<String>()
        .toList(growable: false);
    }
    return null;
  }

  /// Performs an HTTP 'GET /v1/traces/{trace_id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] traceId (required):
  ///   Trace ID to retrieve
  Future<Response> getTraceWithHttpInfo(String traceId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/traces/{trace_id}'
      .replaceAll('{trace_id}', traceId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Parameters:
  ///
  /// * [String] traceId (required):
  ///   Trace ID to retrieve
  Future<List<Span>?> getTrace(String traceId,) async {
    final response = await getTraceWithHttpInfo(traceId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Span>') as List)
        .cast<Span>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /v1/traces' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] filter:
  ///   Filter expression
  ///
  /// * [String] from:
  ///   Start time (RFC 3339)
  ///
  /// * [String] to:
  ///   End time (RFC 3339)
  ///
  /// * [int] limit:
  ///   Max spans (default 100, max 1000)
  Future<Response> getTracesWithHttpInfo({ String? filter, String? from, String? to, int? limit, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/traces';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (filter != null) {
      queryParams.addAll(_queryParams('', 'filter', filter));
    }
    if (from != null) {
      queryParams.addAll(_queryParams('', 'from', from));
    }
    if (to != null) {
      queryParams.addAll(_queryParams('', 'to', to));
    }
    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Parameters:
  ///
  /// * [String] filter:
  ///   Filter expression
  ///
  /// * [String] from:
  ///   Start time (RFC 3339)
  ///
  /// * [String] to:
  ///   End time (RFC 3339)
  ///
  /// * [int] limit:
  ///   Max spans (default 100, max 1000)
  Future<List<TraceGroup>?> getTraces({ String? filter, String? from, String? to, int? limit, }) async {
    final response = await getTracesWithHttpInfo( filter: filter, from: from, to: to, limit: limit, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<TraceGroup>') as List)
        .cast<TraceGroup>()
        .toList(growable: false);

    }
    return null;
  }
}
