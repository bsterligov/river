# openapi.api.DefaultApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getHealth**](DefaultApi.md#gethealth) | **GET** /health | 
[**getLogs**](DefaultApi.md#getlogs) | **GET** /v1/logs | 
[**getMetrics**](DefaultApi.md#getmetrics) | **GET** /v1/metrics | 
[**getTrace**](DefaultApi.md#gettrace) | **GET** /v1/traces/{trace_id} | 
[**getTraces**](DefaultApi.md#gettraces) | **GET** /v1/traces | 


# **getHealth**
> getHealth()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DefaultApi();

try {
    api_instance.getHealth();
} catch (e) {
    print('Exception when calling DefaultApi->getHealth: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getLogs**
> List<LogRow> getLogs(filter, from, to, limit)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DefaultApi();
final filter = filter_example; // String | Filter expression
final from = from_example; // String | Start time (RFC 3339)
final to = to_example; // String | End time (RFC 3339)
final limit = 56; // int | Max rows (default 100, max 1000)

try {
    final result = api_instance.getLogs(filter, from, to, limit);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getLogs: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **filter** | **String**| Filter expression | [optional] 
 **from** | **String**| Start time (RFC 3339) | [optional] 
 **to** | **String**| End time (RFC 3339) | [optional] 
 **limit** | **int**| Max rows (default 100, max 1000) | [optional] 

### Return type

[**List<LogRow>**](LogRow.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMetrics**
> List<MetricPoint> getMetrics(filter, from, to, step)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DefaultApi();
final filter = filter_example; // String | Filter expression
final from = from_example; // String | Start time (RFC 3339)
final to = to_example; // String | End time (RFC 3339)
final step = step_example; // String | Query step (e.g. 60s, 5m)

try {
    final result = api_instance.getMetrics(filter, from, to, step);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getMetrics: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **filter** | **String**| Filter expression | [optional] 
 **from** | **String**| Start time (RFC 3339) | [optional] 
 **to** | **String**| End time (RFC 3339) | [optional] 
 **step** | **String**| Query step (e.g. 60s, 5m) | [optional] 

### Return type

[**List<MetricPoint>**](MetricPoint.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getTrace**
> List<Span> getTrace(traceId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DefaultApi();
final traceId = traceId_example; // String | Trace ID to retrieve

try {
    final result = api_instance.getTrace(traceId);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getTrace: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **traceId** | **String**| Trace ID to retrieve | 

### Return type

[**List<Span>**](Span.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getTraces**
> List<TraceGroup> getTraces(filter, from, to, limit)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DefaultApi();
final filter = filter_example; // String | Filter expression
final from = from_example; // String | Start time (RFC 3339)
final to = to_example; // String | End time (RFC 3339)
final limit = 56; // int | Max spans (default 100, max 1000)

try {
    final result = api_instance.getTraces(filter, from, to, limit);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getTraces: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **filter** | **String**| Filter expression | [optional] 
 **from** | **String**| Start time (RFC 3339) | [optional] 
 **to** | **String**| End time (RFC 3339) | [optional] 
 **limit** | **int**| Max spans (default 100, max 1000) | [optional] 

### Return type

[**List<TraceGroup>**](TraceGroup.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

