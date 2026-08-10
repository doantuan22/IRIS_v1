/// Client gọi NVIDIA NIM API để embed văn bản (câu hỏi, chunk hồ sơ/tham
/// khảo) thành vector, dùng cho vector search local.
///
/// TODO: POST tới ApiConfig.nvidiaEmbeddingEndpoint với header
/// Authorization: Bearer ${ApiConfig.nvidiaApiKey}, body { model, input,
/// input_type: 'query' }, rồi parse response về `List<double>`.
class NvidiaApiClient {
  Future<List<double>> embed(String text) async {
    throw UnimplementedError('TODO: gọi NVIDIA embedding API và parse response');
  }
}
