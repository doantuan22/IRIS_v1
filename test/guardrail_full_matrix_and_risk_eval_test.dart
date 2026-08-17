// ============================================================================
// BÀI TEST XÁC THỰC TOÀN BỘ 12 CÂU HỎI NHÓM 1-3 & ĐÁNH GIÁ RỦI RO TỪ KHÓA
// ============================================================================

// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/domain/models/profile_chunk.dart';
import 'package:iris_app/domain/models/scored_chunk.dart';
import 'package:iris_app/domain/services/guardrail_service.dart';

void main() {
  final guardrailService = GuardrailService();

  group('YÊU CẦU 1: Xác thực Toàn bộ 12 câu hỏi Nhóm 1, 2, 3 (Ngưỡng 0.72 + Lớp từ khóa)', () {
    final matrix = [
      // NHÓM 1: Ngoài Domain
      (
        group: '1. Ngoài Domain',
        query: 'Hôm nay thời tiết ở Hà Nội thế nào?',
        cosine: 0.5643,
      ),
      (
        group: '1. Ngoài Domain',
        query: 'Làm thế nào để học lập trình Flutter hiệu quả?',
        cosine: 0.5265,
      ),
      (
        group: '1. Ngoài Domain',
        query: 'Thủ đô của nước Pháp là thành phố nào?',
        cosine: 0.6661,
      ),
      (
        group: '1. Ngoài Domain',
        query: 'Giá xăng dầu trong nước hiện tại là bao nhiêu?',
        cosine: 0.7386, // Outlier
      ),

      // NHÓM 2: Về trẻ - Ngoài mô tả
      (
        group: '2. Về trẻ - Ngoài mô tả',
        query: 'Bé có thích xem phim hoạt hình siêu nhân trên tivi không?',
        cosine: 0.6375,
      ),
      (
        group: '2. Về trẻ - Ngoài mô tả',
        query: 'Bé nhà tôi có thích vẽ tranh và phối màu sắc không?',
        cosine: 0.6821,
      ),
      (
        group: '2. Về trẻ - Ngoài mô tả',
        query: 'Bé có bị dị ứng thời tiết hay phấn hoa không?',
        cosine: 0.6886,
      ),
      (
        group: '2. Về trẻ - Ngoài mô tả',
        query: 'Con tôi thích ăn loại kẹo ngọt và đồ uống gì nhất?',
        cosine: 0.7108,
      ),

      // NHÓM 3: Liên quan mờ nhạt
      (
        group: '3. Liên quan mờ nhạt',
        query: 'Con tôi ban đêm có hay khóc thét không?',
        cosine: 0.6629,
      ),
      (
        group: '3. Liên quan mờ nhạt',
        query: 'Bé có sợ tiếng ồn lớn ngoài đường không?',
        cosine: 0.6552,
      ),
      (
        group: '3. Liên quan mờ nhạt',
        query: 'Bé có chơi hòa đồng ở lớp mầm non không?',
        cosine: 0.6650,
      ),
      (
        group: '3. Liên quan mờ nhạt',
        query: 'Bé có kỹ năng tự chăm sóc bản thân tốt không?',
        cosine: 0.6448,
      ),
    ];

    test('Toàn bộ 12/12 câu hỏi Nhóm 1-3 đều phải ra đúng Trạng thái 1 (insufficientData)', () {
      print('\n========================================================================================================');
      print('BẢNG XÁC THỰC TOÀN BỘ 12 CÂU HỎI NHÓM 1, 2, 3 VỚI GUARDRAIL (NGƯỠNG 0.72 + TỪ KHÓA)');
      print('========================================================================================================');
      print(
        'STT | Nhóm                  | Câu hỏi                                                  | Điểm Cosine | Qua từ khóa? | Trạng thái cuối | Kết quả',
      );
      print('----+-----------------------+----------------------------------------------------------+-------------+--------------+-----------------+---------');

      var passCount = 0;
      for (var i = 0; i < matrix.length; i++) {
        final item = matrix[i];
        final passedKeyword = GuardrailService.isChildDevelopmentQuery(item.query);

        // Tạo dummy chunk mô phỏng đúng điểm cosine đo đạc thực tế của câu hỏi này
        final dummyChunk = ScoredProfileChunk(
          chunk: ProfileChunk(
            id: 'chunk-$i',
            childId: 'child-1',
            linhVuc: 'mo_ta',
            content: 'Nội dung mô tả đại diện của trẻ',
            nguon: 'phu_huynh',
            createdAt: DateTime.now(),
            embedding: const [],
          ),
          similarity: item.cosine,
        );

        final result = guardrailService.determineState(
          retrievedProfileChunks: [dummyChunk],
          hasScreeningResult: false,
          userQuestion: item.query,
        );

        final isState1 = result.state == AiState.insufficientData;
        if (isState1) passCount++;

        final stt = (i + 1).toString().padLeft(3);
        final group = item.group.padRight(21);
        final q = item.query.padRight(56);
        final cos = item.cosine.toStringAsFixed(4).padRight(11);
        final kw = (passedKeyword ? 'Có' : 'Không').padRight(12);
        final st = result.state.name.padRight(15);
        final res = isState1 ? 'PASS' : 'FAIL';

        print('$stt | $group | $q | $cos | $kw | $st | $res');

        expect(result.state, equals(AiState.insufficientData));
      }
      print('--------------------------------------------------------------------------------------------------------');
      print('TỔNG KẾT NHÓM 1-3: $passCount / ${matrix.length} CÂU ĐẠT ĐÚNG TRẠNG THÁI 1 (100% PASS)\n');
    });
  });

  group('YÊU CẦU 2: Đánh giá Rủi ro Danh sách Từ khóa Cố định (Edge Cases & False Negatives)', () {
    final edgeCases = [
      (
        desc: 'Dùng từ xưng hô thân mật dân gian ("cún")',
        query: 'Cún nhà tôi 3 tuổi chưa biết nói thì có sao không?',
        hasExplicitChildWord: false,
      ),
      (
        desc: 'Mô tả gián tiếp độ tuổi không có từ bé/con/trẻ ("lên ba")',
        query: 'Ở độ tuổi lên ba mà chưa biết bập bẹ gọi ai thì có bất thường không?',
        hasExplicitChildWord: false,
      ),
      (
        desc: 'Dùng đại từ ngôi thứ ba ("nó") và hành vi cụ thể',
        query: 'Nó cứ bịt tai la hét mỗi khi nghe tiếng máy xay thì phải làm sao?',
        hasExplicitChildWord: false,
      ),
      (
        desc: 'Không có đại từ/chủ ngữ chỉ trẻ, chỉ nêu hành vi',
        query: '3 tuổi chỉ xếp ô tô thành hàng dài và cáu giận khi bị lệch thì sao?',
        hasExplicitChildWord: false,
      ),
      (
        desc: 'Dùng từ lóng vùng miền ("nhóc") và hành vi đi kiễng chân',
        query: 'Nhóc 3 tuổi hay giật mình thức giấc và đi kiễng chân thì có đáng lo không?',
        hasExplicitChildWord: false,
      ),
    ];

    test('Đo đạc chi tiết 5 câu hỏi diễn đạt gián tiếp / phi chuẩn', () {
      print('\n========================================================================================================');
      print('BẢNG ĐÁNH GIÁ RỦI RO: CÂU HỎI HỢP LỆ NHƯNG DÙNG TỪ NGỮ KHÔNG NẰM TRONG DANH SÁCH TỪ KHÓA CỐ ĐỊNH');
      print('========================================================================================================');

      for (var i = 0; i < edgeCases.length; i++) {
        final ec = edgeCases[i];
        final passedKeyword = GuardrailService.isChildDevelopmentQuery(ec.query);

        // Giả lập chunk ngôn ngữ/hành vi có độ tương đồng cao (0.73)
        final dummyChunk = ScoredProfileChunk(
          chunk: ProfileChunk(
            id: 'edge-$i',
            childId: 'child-1',
            linhVuc: 'ngon_ngu',
            content: 'Nội dung biểu hiện liên quan trực tiếp của trẻ',
            nguon: 'phu_huynh',
            createdAt: DateTime.now(),
            embedding: const [],
          ),
          similarity: 0.73,
        );

        final result = guardrailService.determineState(
          retrievedProfileChunks: [dummyChunk],
          hasScreeningResult: false,
          userQuestion: ec.query,
        );

        print('\n[Trường hợp ${i + 1}]: ${ec.desc}');
        print('Câu hỏi: "${ec.query}"');
        print('  - Qua lớp từ khóa?: ${passedKeyword ? "CÓ" : "KHÔNG (Bị chặn bởi danh sách từ khóa)"}');
        print('  - Trạng thái Guardrail: ${result.state}');
        if (!passedKeyword) {
          print('  -> ĐÁNH GIÁ: BỊ TỪ CHỐI NHẦM (False Negative) do câu hỏi không chứa từ trong danh sách từ khóa cố định.');
        } else {
          print('  -> ĐÁNH GIÁ: VƯỢT QUA do câu hỏi chứa từ khóa phát triển khác (như "nói", "tai", "ngủ", v.v.).');
        }
      }
      print('========================================================================================================\n');
    });
  });
}
